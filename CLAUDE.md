# Project: ActiveDocument

Ruby ODM (Object Document Mapper) for NoSQL databases. Fork of Mongoid.

## Differences from Mongoid

When porting code from Mongoid, note these intentional differences:

- **Namespace**: Use `ActiveDocument` instead of `Mongoid` throughout
- **Test utilities**: Use local `EventSubscriber` class (in `spec/support/event_subscriber.rb`) instead of `Mrss::EventSubscriber`. Do NOT create an Mrss module - adapt to our local versions instead.
- **Evergreen CI**: Remove any Evergreen CI-specific code or configurations when porting. This project does not use Evergreen.
- **MRSS shared specs**: When porting tests that reference `Mrss::*` utilities, check `/mnt/c/workspace/mongoid/spec/shared/lib/mrss/` for the source, then adapt to use local equivalents or create simplified local versions without the `Mrss::` namespace.
- **Symbol operators removed**: ActiveDocument does NOT have Symbol operator methods (`:field.in`, `:field.gt`, `:field.ne`, etc.) that Mongoid has. When porting code that uses this syntax, rewrite to use method syntax (`.any_in`, `.not_in`, `.gt`, `.ne`, etc.) OR hash syntax `{ _id: { '$nin' => values } }` instead of `:_id.in => values`).

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

### Ruby Style Conventions
- **Strings**: Prefer single quotes when no interpolation or special symbols needed
- **Arrays**: No spaces inside array brackets (`[1, 2]` not `[ 1, 2 ]`)
- **Percent literals**: No spaces inside delimiters (`%w[foo bar]` not `%w[ foo bar ]`)
- **Ternary operators**: Avoid multi-line ternary; use `if`/`else` instead
- **Nested ternary**: Never nest ternary operators; use `if`/`elsif`/`else`
- **Guard clauses**: Prefer early returns over wrapping code in conditionals
- **Method chaining**: Align chained method calls with the receiver
- **Raise exceptions**: Use `raise ErrorClass.new(args)` not `raise ErrorClass, args`
- **Self-assignment**: Don't use `x = x.method!` when `x.method!` suffices

### RSpec Conventions
- **Equality**: Use `eq` instead of `be ==` for comparisons
- **Negation**: Prefer `to_not` over `not_to`
- **Boolean checks**: Use `be(true)`/`be(false)` over `eq(true)`/`eq(false)`
- **Context naming**: Start context descriptions with "when", "with", or "without"
- **Hook arguments**: Omit default `:example` argument for hooks (`around do` not `around(:example) do`)
- **Empty lines**: Add empty line after final `let` before examples
- **Shared examples**: Use `shared_examples` (not `shared_context`) when not defining context
- **Identical assertions**: Don't compare expression to itself; store in variable first
