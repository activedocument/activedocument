# PR #23: Introduce AST, MQL Parser, and Renderer

**Date:** 2024-06-15
**PR:** https://github.com/activedocument/activedocument/pull/23
**Type:** New feature - Foundation for query manipulation

## Summary

Introduces an Abstract Syntax Tree (AST) representation for MongoDB queries, along with a parser to convert MQL hashes into AST nodes and a renderer to convert AST back to MQL. This lays groundwork for future query optimization and transformation features.

## Motivation

Working with MongoDB query hashes directly has limitations:
- Hard to analyze query structure programmatically
- Difficult to transform or optimize queries
- No type-safe manipulation of query conditions
- Complex nested queries become unwieldy to debug

An AST provides:
- Structured representation of queries
- Type-safe node classes for each operator
- Foundation for query optimization, analysis, and transformation
- Better tooling for debugging and visualization

## Architecture

### Module Structure

```
lib/active_document/
├── ast.rb                      # Main autoload + DSL helpers
├── ast/
│   ├── node.rb                # Base node class
│   └── node/
│       ├── field_operator.rb  # Base for field-level operators
│       ├── logical_operator.rb # Base for logical operators
│       ├── eq.rb              # $eq
│       ├── not_eq.rb          # $ne
│       ├── gt.rb              # $gt
│       ├── gte.rb             # $gte
│       ├── lt.rb              # $lt
│       ├── lte.rb             # $lte
│       ├── any_in.rb          # $in
│       ├── not_in.rb          # $nin
│       ├── and.rb             # $and
│       ├── or.rb              # $or
│       ├── nor.rb             # $nor
│       └── not.rb             # $not
├── parser.rb
├── parser/
│   └── mql.rb                 # MQL hash -> AST
├── renderer.rb
└── renderer/
    └── mql.rb                 # AST -> MQL hash
```

### AST Node Classes

**Base class** (`lib/active_document/ast/node.rb`):

```ruby
module ActiveDocument
  module AST
    class Node
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def ==(other)
        return false unless self.class == other.class
        children.zip(other.children).all? { |child, other_child| child == other_child }
      end

      def empty?
        return true if children == []
        children.all?(&:empty?)
      end

      def inspect(depth = 1)
        delimiter = @children.any?(Node) ? "\n#{'  ' * depth}" : ' '
        "(#{class_name}:#{delimiter}#{@children.map { |c|
          c.is_a?(Node) ? c.inspect(depth + 1) : c.inspect
        }.join(", #{delimiter}")})"
      end
    end
  end
end
```

**Field operator base** (`lib/active_document/ast/node/field_operator.rb`):

```ruby
module ActiveDocument
  module AST
    class FieldOperator < Node
      attr_reader :field, :value

      def initialize(field, value)
        @field = field
        @value = value
        super([field, value])
      end
    end
  end
end
```

**Logical operator base** (`lib/active_document/ast/node/logical_operator.rb`):

```ruby
module ActiveDocument
  module AST
    class LogicalOperator < Node
      def initialize(operands)
        super(operands)
      end
    end
  end
end
```

**Concrete operators:**

| Node Class | MongoDB Operator | Inheritance |
|------------|-----------------|-------------|
| `AST::Eq` | `$eq` | `FieldOperator` |
| `AST::NotEq` | `$ne` | `FieldOperator` |
| `AST::Gt` | `$gt` | `FieldOperator` |
| `AST::Gte` | `$gte` | `FieldOperator` |
| `AST::Lt` | `$lt` | `FieldOperator` |
| `AST::Lte` | `$lte` | `FieldOperator` |
| `AST::AnyIn` | `$in` | `FieldOperator` |
| `AST::NotIn` | `$nin` | `FieldOperator` |
| `AST::And` | `$and` | `LogicalOperator` |
| `AST::Or` | `$or` | `LogicalOperator` |
| `AST::Nor` | `$nor` | `LogicalOperator` |
| `AST::Not` | `$not` | `LogicalOperator` |

### DSL Helpers

The `AST` module provides factory methods for convenient node construction:

```ruby
module ActiveDocument
  module AST
    # Factory methods (Kernel-style constructors)
    def Eq(*args) = Eq.new(*args)
    def Gt(*args) = Gt.new(*args)
    def Gte(*args) = Gte.new(*args)
    def Lt(*args) = Lt.new(*args)
    def Lte(*args) = Lte.new(*args)
    def NotEq(*args) = NotEq.new(*args)
    def AnyIn(*args) = AnyIn.new(*args)
    def NotIn(*args) = NotIn.new(*args)
    def And(*args) = And.new(args)
    def Or(*args) = Or.new(args)
    def Nor(*args) = Nor.new(args)
    def Not(*args) = Not.new(args)
  end
end
```

**Usage:**

```ruby
include ActiveDocument::AST

# Build AST programmatically
ast = And(
  Eq('name', 'Tool'),
  Or(
    Gt('year', 2000),
    Lt('year', 1990)
  )
)
```

### Parser: MQL Hash to AST

The `Parser::MQL` module (`lib/active_document/parser/mql.rb`) converts MongoDB query hashes to AST:

```ruby
module ActiveDocument
  module Parser
    module MQL
      FIELD_OPERATORS = {
        '$eq' => AST::Eq,
        '$gt' => AST::Gt,
        '$gte' => AST::Gte,
        '$in' => AST::AnyIn,
        '$lt' => AST::Lt,
        '$lte' => AST::Lte,
        '$ne' => AST::NotEq,
        '$nin' => AST::NotIn
      }.freeze

      LOGICAL_OPERATORS = {
        '$and' => AST::And,
        '$nor' => AST::Nor,
        '$not' => AST::Not,
        '$or' => AST::Or
      }.freeze

      class << self
        def parse(mql_hash)
          return nil if mql_hash.nil? || !mql_hash.is_a?(Hash) || mql_hash.empty?
          do_parse(mql_hash)
        end

        private

        def do_parse(data, path = [])
          case data
          when Hash then do_parse_hash(data, path)
          when Array then do_parse_array(data, path)
          when Numeric
            op = path[-1]
            field = path[-2]
            node_klass(op).new(field, data)
          else
            raise "unexpected data: #{data}"
          end
        end

        # ... (handles implicit vs explicit MQL syntax conversion)
      end
    end
  end
end
```

**Key parsing features:**

1. **Handles implicit AND**: `{ name: "Tool", year: 2000 }` becomes `And(Eq(name, Tool), Eq(year, 2000))`

2. **Handles explicit operators**: `{ '$and': [...] }` directly maps to `And(...)`

3. **Handles mixed syntax**: Detects when a hash mixes field conditions with logical operators and normalizes

4. **Primitive type detection**: Distinguishes between MQL array syntax `[{...}, {...}]` and value arrays `[1, 2, 3]`

**Usage:**

```ruby
ast = ActiveDocument::Parser::MQL.parse({
  name: "Tool",
  year: { '$gt' => 2000 }
})
# => And(Eq("name", "Tool"), Gt("year", 2000))

ast = ActiveDocument::Parser::MQL.parse({
  '$or' => [
    { name: "Tool" },
    { name: "Deftones" }
  ]
})
# => Or(Eq("name", "Tool"), Eq("name", "Deftones"))
```

### Renderer: AST to MQL Hash

The `Renderer::MQL` module (`lib/active_document/renderer/mql.rb`) converts AST back to MongoDB query hashes:

```ruby
module ActiveDocument
  module Renderer
    module MQL
      NODE_OPERATORS = {
        AST::Eq => '$eq',
        AST::Gt => '$gt',
        AST::Gte => '$gte',
        AST::AnyIn => '$in',
        AST::Lt => '$lt',
        AST::Lte => '$lte',
        AST::NotEq => '$ne',
        AST::NotIn => '$nin',
        AST::And => '$and',
        AST::Nor => '$nor',
        AST::Not => '$not',
        AST::Or => '$or'
      }.freeze

      class << self
        def render(tree)
          return nil if tree.nil? || !tree.is_a?(AST::Node) || tree.empty?
          do_render(tree)
        end

        private

        def do_render_node(node)
          left, right = *node.children

          case node
          when AST::FieldOperator
            { do_render(left) => { node_type(node) => do_render(right) } }
          when AST::LogicalOperator
            { node_type(node) => [left, right].map { |n| do_render(n) } }
          end
        end
      end
    end
  end
end
```

**Usage:**

```ruby
ast = ActiveDocument::AST::And.new([
  ActiveDocument::AST::Eq.new('name', 'Tool'),
  ActiveDocument::AST::Gt.new('year', 2000)
])

mql = ActiveDocument::Renderer::MQL.render(ast)
# => { '$and' => [{ 'name' => { '$eq' => 'Tool' } }, { 'year' => { '$gt' => 2000 } }] }
```

### Round-Trip Example

```ruby
# Start with MQL hash
original = {
  '$and' => [
    { name: { '$eq' => 'Tool' } },
    { year: { '$gt' => 2000 } }
  ]
}

# Parse to AST
ast = ActiveDocument::Parser::MQL.parse(original)
# => (And: (Eq: "name", "Tool"), (Gt: "year", 2000))

# Render back to MQL
rendered = ActiveDocument::Renderer::MQL.render(ast)
# => { '$and' => [{ 'name' => { '$eq' => 'Tool' } }, { 'year' => { '$gt' => 2000 } }] }
```

## Supported Value Types

The parser and renderer support these primitive types in arrays (for `$in`/`$nin`):

- `Integer`, `Float`, `BigDecimal`
- `String`, `Symbol`
- `ActiveDocument::Boolean`
- `Regexp`
- `Range`
- `Time`, `Date`, `DateTime`, `ActiveSupport::TimeWithZone`
- `BSON::Binary`
- `Set`
- `ActiveDocument::StringifiedSymbol`

## Future Applications

This AST foundation enables:

1. **Query Optimization**
   - Simplify redundant conditions (e.g., `$and` with single child)
   - Flatten nested same-type logical operators
   - Detect and merge compatible conditions

2. **Query Analysis**
   - Detect N+1 query patterns
   - Analyze index usage potential
   - Identify expensive operations

3. **Query Transformation**
   - Convert between query syntaxes
   - Apply security filters (multi-tenancy)
   - Auto-inject soft-delete conditions

4. **Debugging Tools**
   - Pretty-print query structure
   - Visualize query trees
   - Compare query equivalence

5. **Multi-Database Support**
   - Render to different query languages
   - Support for other document databases

## Testing

Comprehensive specs cover:
- Parser handling of all operator types
- Round-trip parsing and rendering
- Edge cases (nested conditions, empty queries)
- 304 lines of parser specs, 173 lines of renderer specs

## Impact

- **Non-breaking addition**: New modules, no changes to existing query API
- **1,032 additions, 1 deletion** (rubocop config update)
- Foundation for future query enhancements
