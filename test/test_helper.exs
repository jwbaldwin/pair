ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Pair.Repo, :manual)

Mimic.copy(Req)
Mimic.copy(Pair.Clients.Anthropic)
Mimic.copy(Pair.Clients.OpenAI)
Mimic.copy(Pair.Recordings.Services.ExtractMeetingNotes)
Mimic.copy(Instructor)
