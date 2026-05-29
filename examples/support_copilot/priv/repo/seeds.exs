ticket = Scoria.SupportJourney.ticket_fixture()
persona = Scoria.SupportJourney.persona_fixture()

IO.puts("""
Support copilot gallery seeds loaded.

Ticket: #{ticket["id"]} — #{ticket["subject"]}
Persona: #{persona["persona"]} @ #{persona["company"]} (#{persona["tenant_id"]})

Start the gallery with: mix phx.server
Operator surface: http://localhost:4010/scoria
""")
