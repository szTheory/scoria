defmodule Scoria.Connectors.Auth do
  @moduledoc """
  `Scoria.Connectors.Auth` coordinates host-owned connector authorization with
  Scoria's connector records, grants, approvals, and audit evidence.

  Use this module when a remote connector needs an authorization start,
  callback completion, auth-failure evidence, or scope-escalation approval. The
  host app owns the authenticated subject, tenant membership, redirect route,
  OAuth app configuration, and business decision to grant scopes. Scoria records
  the connector grant and projects failures or escalations into reviewer trace
  evidence.

  See `guides/capabilities/connectors-and-mcp.md` for connector/MCP setup and
  verification guidance.
  """

  import Ecto.Query, warn: false

  alias Scoria.Connectors
  alias Scoria.Connectors.{AuthState, Connector, Grant, GrantRefresh}
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.Workflows

  def start_authorization(connector_id, attrs \\ %{}) do
    connector = Connectors.get_connector!(connector_id)
    attrs = normalize_map(attrs)
    oauth = oauth_config(connector)
    auth_state = AuthState.new(connector.id, attrs)

    authorization_url =
      oauth["authorization_endpoint"]
      |> URI.parse()
      |> Map.update!(:query, fn _ ->
        URI.encode_query(%{
          "response_type" => "code",
          "client_id" => oauth["client_id"] || connector.key,
          "redirect_uri" => attrs["redirect_uri"],
          "scope" => Enum.join(oauth["scopes"] || [], " "),
          "state" => auth_state["state"],
          "code_challenge" => auth_state["code_challenge"],
          "code_challenge_method" => "S256"
        })
      end)
      |> URI.to_string()

    {:ok, _event} =
      SRE.create_audit_outbox_event(%{
        tenant_id: connector.tenant_id || "system",
        event_type: "connector.auth_started",
        policy_class: "connector_auth",
        trace_id: auth_state["trace_id"],
        actor_id: auth_state["actor_id"],
        tool_ref: connector.key,
        target: connector.endpoint_url,
        metadata: %{
          connector_id: connector.id,
          auth_mode: connector.auth_mode
        }
      })

    {:ok, %{authorization_url: authorization_url, auth_state: auth_state}}
  end

  def complete_authorization(connector_id, params, auth_state, attrs \\ %{}) do
    connector = Connectors.get_connector!(connector_id)
    params = normalize_map(params)
    attrs = normalize_map(attrs)
    oauth = oauth_config(connector)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    token_response = token_response(oauth, params)

    grant =
      Repo.get_by(Grant,
        connector_id: connector.id,
        subject_ref: token_response["subject_ref"],
        grant_kind: "oauth"
      ) ||
        %Grant{}

    grant_attrs = %{
      connector_id: connector.id,
      tenant_id: connector.tenant_id,
      subject_ref: token_response["subject_ref"],
      grant_kind: "oauth",
      status: "active",
      granted_scopes: token_response["granted_scopes"] || oauth["scopes"] || [],
      issuer: oauth["issuer"],
      resource_identifier: token_response["resource_identifier"] || oauth["resource_identifier"],
      token_type: token_response["token_type"] || "Bearer",
      access_token: token_response["access_token"],
      refresh_token: token_response["refresh_token"],
      client_secret: oauth["client_secret"],
      raw_token:
        Map.take(token_response, ["access_token", "refresh_token", "token_type", "expires_in"]),
      expires_at: expires_at(now, token_response["expires_in"]),
      refresh_expires_at: expires_at(now, token_response["refresh_expires_in"]),
      last_authenticated_at: now,
      last_refresh_status: "pending",
      metadata: %{
        "account_label" => token_response["account_label"],
        "code" => params["code"]
      }
    }

    with {:ok, grant} <- Repo.insert_or_update(Grant.changeset(grant, grant_attrs)),
         {:ok, _job} <- GrantRefresh.enqueue_post_auth(connector, grant, attrs),
         {:ok, _event} <-
           SRE.create_audit_outbox_event(%{
             tenant_id: connector.tenant_id || "system",
             event_type: "connector.auth_succeeded",
             policy_class: "connector_auth",
             trace_id: auth_state["trace_id"],
             actor_id: auth_state["actor_id"],
             tool_ref: connector.key,
             target: connector.endpoint_url,
             metadata: %{
               connector_id: connector.id,
               grant_id: grant.id,
               subject_ref: grant.subject_ref
             }
           }) do
      {:ok, grant}
    else
      {:error, reason} ->
        record_callback_auth_failure(connector, auth_state, reason)
        {:error, reason}
    end
  end

  def record_remote_auth_failure(
        %Connector{} = connector,
        local_tool,
        context,
        reason_code,
        opts \\ []
      ) do
    record_connector_invocation_event(
      "connector.auth_failed",
      :auth_required,
      connector,
      local_tool,
      context,
      reason_code,
      Keyword.get(opts, :args, %{}),
      %{
        "grant_status" => Keyword.get(opts, :grant_status, "missing")
      }
    )
  end

  def record_scope_escalation(
        %Connector{} = connector,
        local_tool,
        context,
        missing_scopes,
        opts \\ []
      ) do
    record_connector_invocation_event(
      "connector.scope_escalation",
      :scope_escalation_required,
      connector,
      local_tool,
      context,
      "scope_escalation_required",
      Keyword.get(opts, :args, %{}),
      %{
        "grant_status" => Keyword.get(opts, :grant_status, "active"),
        "missing_scopes" => Enum.map(missing_scopes, &to_string/1)
      }
    )
  end

  defp oauth_config(%Connector{metadata: metadata}) do
    Map.get(metadata || %{}, "oauth", %{})
  end

  defp token_response(oauth, params) do
    Map.merge(
      %{
        "access_token" => "access-" <> params["code"],
        "refresh_token" => "refresh-" <> params["code"],
        "subject_ref" => oauth["subject_ref"] || "subject-" <> params["code"],
        "granted_scopes" => oauth["scopes"] || [],
        "expires_in" => 3600
      },
      oauth["token_response"] || %{}
    )
  end

  defp expires_at(_now, nil), do: nil
  defp expires_at(now, seconds) when is_integer(seconds), do: DateTime.add(now, seconds, :second)

  defp expires_at(now, seconds) when is_binary(seconds),
    do: expires_at(now, String.to_integer(seconds))

  defp expires_at(_now, _seconds), do: nil

  defp record_callback_auth_failure(connector, auth_state, reason) do
    SRE.create_audit_outbox_event(%{
      tenant_id: connector.tenant_id || "system",
      event_type: "connector.auth_failed",
      policy_class: "connector_auth",
      trace_id: auth_state["trace_id"],
      actor_id: auth_state["actor_id"],
      tool_ref: connector.key,
      target: connector.endpoint_url,
      reason_code: inspect(reason),
      metadata: %{
        connector_id: connector.id
      }
    })
  end

  defp record_connector_invocation_event(
         event_type,
         policy_outcome,
         %Connector{} = connector,
         local_tool,
         context,
         reason_code,
         args,
         extra_metadata
       ) do
    context = normalize_map(context)
    args = normalize_map(args)

    payload = %{
      "connector_id" => connector.id,
      "local_tool_id" => local_tool.id,
      "policy_outcome" => Atom.to_string(policy_outcome),
      "reason_code" => reason_code,
      "missing_scopes" => Map.get(extra_metadata, "missing_scopes", []),
      "run_id" => context["run_id"],
      "step_id" => context["step_id"]
    }

    with {:ok, workflow_event_id} <- maybe_record_workflow_event(event_type, context, payload),
         {:ok, audit_outbox_event} <-
           SRE.create_audit_outbox_event(%{
             tenant_id: context["tenant_id"] || connector.tenant_id || "system",
             actor_id: context["actor_id"],
             workflow_run_id: context["run_id"],
             step_id: context["step_id"],
             trace_id: context["trace_id"],
             event_type: event_type,
             policy_class: "connector_auth",
             policy_key: context["policy_key"],
             reason_code: reason_code,
             tool_ref: connector.key,
             target: connector.endpoint_url,
             args: args,
             metadata:
               Map.merge(
                 %{
                   "connector_id" => connector.id,
                   "local_tool_id" => local_tool.id,
                   "policy_outcome" => Atom.to_string(policy_outcome),
                   "run_id" => context["run_id"],
                   "step_id" => context["step_id"],
                   "workflow_event_id" => workflow_event_id
                 },
                 extra_metadata
               )
           }) do
      approval =
        maybe_request_remote_approval(
          connector,
          local_tool,
          context,
          policy_outcome,
          reason_code,
          args,
          extra_metadata,
          workflow_event_id,
          audit_outbox_event.id
        )

      {:ok,
       %{
         audit_outbox_event: audit_outbox_event,
         workflow_event_id: workflow_event_id,
         approval: approval
       }}
    end
  end

  defp maybe_record_workflow_event("connector.auth_failed", context, payload) do
    case Workflows.record_connector_auth_failure(context["run_id"], context["step_id"], payload) do
      {:ok, event} -> {:ok, event.id}
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_record_workflow_event("connector.scope_escalation", context, payload) do
    case Workflows.record_connector_scope_escalation(
           context["run_id"],
           context["step_id"],
           payload
         ) do
      {:ok, event} -> {:ok, event.id}
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_record_workflow_event(_event_type, %{"run_id" => nil}, _payload), do: {:ok, nil}
  defp maybe_record_workflow_event(_event_type, %{}, _payload), do: {:ok, nil}

  defp maybe_request_remote_approval(
         connector,
         local_tool,
         context,
         policy_outcome,
         reason_code,
         args,
         extra_metadata,
         workflow_event_id,
         audit_outbox_event_id
       ) do
    context = normalize_map(context)

    case {context["run_id"], context["step_id"]} do
      {run_id, step_id} when is_binary(run_id) and is_binary(step_id) ->
        blocker_kind =
          case policy_outcome do
            :auth_required -> "auth_required"
            :scope_escalation_required -> "scope_escalation_required"
          end

        {:ok, approval} =
          Workflows.request_remote_approval(run_id, step_id, %{
            tool_name: local_tool.remote_tool_name || local_tool.display_name,
            arguments: args,
            reason: reason_code,
            trace_id: context["trace_id"],
            actor_id: context["actor_id"],
            tenant_id: context["tenant_id"] || connector.tenant_id,
            session_id: context["session_id"],
            blocker_kind: blocker_kind,
            connector_id: connector.id,
            local_tool_id: local_tool.id,
            grant_status: extra_metadata["grant_status"],
            grant_subject_ref: context["subject_ref"] || context["actor_id"],
            policy_outcome: Atom.to_string(policy_outcome),
            missing_scopes: extra_metadata["missing_scopes"] || [],
            requested_scopes: local_tool.required_scopes || [],
            replay_allowed: true,
            blocker_workflow_event_id: workflow_event_id,
            blocker_audit_outbox_event_id: audit_outbox_event_id
          })

        approval

      _ ->
        nil
    end
  end

  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})

  defp normalize_map(attrs) when is_map(attrs),
    do: Map.new(attrs, fn {key, value} -> {to_string(key), value} end)

  defp normalize_map(_attrs), do: %{}
end
