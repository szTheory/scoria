defmodule Scoria.Vault do
  use Cloak.Vault, otp_app: :scoria

  @impl true
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_key!()}
      )

    {:ok, config}
  end

  defp decode_key! do
    "SCORIA_VAULT_KEY"
    |> System.get_env(default_key())
    |> Base.decode64!()
  end

  defp default_key do
    "PwIcoX8/Jhn4gsgZeJueZnyaisQDuCtEvLneO+pDkSk="
  end
end
