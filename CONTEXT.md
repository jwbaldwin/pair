# CONTEXT.md - Guide for Agentic Coding Assistants

## Build Commands
- `mix setup` - Install dependencies and setup project
- `mix phx.server` - Start Phoenix server
- `iex -S mix phx.server` - Start with interactive shell
- `mix test` - Run all tests
- `mix test path/to/test_file.exs:line_number` - Run specific test
- `mix format` - Format code
- `mix ecto.reset` - Reset database

## Code Style Guidelines
- Follow Elixir style (snake_case for variables/functions, CamelCase for modules)
- Organize imports: Elixir modules first, then application modules
- Prefer pipe operator |> for function chaining
- Use pattern matching over conditional logic where appropriate
- Error handling: use `with` statements for happy path, handle errors explicitly
- Tests: use descriptive names following "test description, %{conn: conn} do" pattern
- For UI components, follow Phoenix Component patterns from core_components.ex

## Project Structure
- Phoenix 1.7 architecture with LiveView
- Uses Tailwind CSS for styling
- Includes LangChain, Req, and Oban for AI integration
- Follows standard Phoenix directory structure (lib/pair, lib/pair_web)