# Project: ActiveDocument

Ruby ODM (Object Document Mapper) for NoSQL databases. Fork of Mongoid.

## Tech Stack
- Runtime: **Ruby** 3.1+
- Testing: RSpec
- Linting: Rubocop

## Project Structure
```
lib/
├── active_document.rb       # Main entry point
├── active_document/         # Core library code
spec/                        # RSpec tests
docs/                        # Documentation
perf/                        # Performance benchmarks
gemfiles/                    # Gemfile variants for CI
```

## Commands
- `bundle install` - Install dependencies
- `bundle exec rspec` - Run all tests
- `bundle exec rspec spec/path/to_spec.rb` - Run specific test file
- `bundle exec rspec spec/path/to_spec.rb:123` - Run specific test line
- `bundle exec rubocop` - Lint
- `bundle exec rubocop -A` - Lint with auto-fix

## Testing Rules
- **ALWAYS run tests** and add tests for any new scenario or behavior.
- **Focus on changed files first**: Run the specific test file for what you changed before running broader suites.
- **NEVER** skip, suppress, or delete tests because they are difficult. Instead, diagnose the problem.
- **NEVER** implement no-op tests or simplify tests to the point where they are meaningless.
- **100% pass rate required** - 95% is not acceptable.
- Avoid `sleep` in tests; use proper waiting patterns.

## Workflow
- After making each change/feature, write tests for it.
- Consider if writing tests first makes more sense (TDD).
- At milestones: write Lore, consider Harden, consider Lint.

## Documentation
- Implementation summaries: Save to `/lore` folder
- Filename format: `YYYYMMDD-HHMM-lowercase-name.md`

## Code Style
- Follow Ruby style guide and Rubocop rules
- Prefer explicit over implicit
- Keep methods focused and small
