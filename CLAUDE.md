# CLAUDE.md - Guide for agentic coding assistants

## Build Commands
- `mix setup` - Install dependencies and setup the project
- `mix phx.server` - Start Phoenix server
- `iex -S mix phx.server` - Start server with interactive Elixir shell
- `mix test` - Run all tests
- `mix test path/to/test_file.exs` - Run specific test file
- `mix test path/to/test_file.exs:line_number` - Run specific test
- `mix format` - Format code according to Elixir standards
- `mix ecto.reset` - Reset database (drop, create, migrate, seed)

## Code Style Guidelines
- Follow standard Elixir style (enforced by formatter)
- Use Phoenix conventions for web components
- Organize imports: Elixir modules first, then application modules
- Naming: snake_case for variables/functions, CamelCase for modules
- Prefer pipe operator |> for function chaining
- Use pattern matching over conditional logic where appropriate
- Error handling: use with statements for happy path, handle errors explicitly
- Tests: use descriptive test names following "test description, %{conn: conn} do" pattern
- Use LiveView for interactive features
- For UI components, follow Phoenix Component patterns from core_components.ex

## Project Structure
- Phoenix 1.8 architecture with LiveView
- Uses Tailwind CSS for styling
- Includes LangChain, Req, and Oban for AI integration
