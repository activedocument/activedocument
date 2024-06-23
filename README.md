![ActiveDocument](https://github.com/activedocument/activedocument/assets/27655/d413fc53-821c-4028-a50b-029867cd9445)

# ActiveDocument

[![Build Status][build-img]][build-url]
[![Gem Version][rubygems-img]][rubygems-url]
[![CodeCov][codecov-img]][codecov-url]
[![License][license-img]][license-url]

**⚠️ ActiveDocument is currently in alpha**

ActiveDocument is a Ruby Object Document Mapper (ODM) for NoSQL databases.
It is similar but not identical to what Rails' [ActiveRecord](https://github.com/rails/rails/tree/main/activerecord) ORM
provides for SQL databases. ActiveDocument may be used with [Ruby on Rails](https://rubyonrails.org/),
other Ruby frameworks such as [Sinatra](https://sinatrarb.com/) and [Hanami](https://hanamirb.org/), or as a standalone.

### Database support

✅ MongoDB

### Planned support

🔲 [AWS DynamoDB](https://aws.amazon.com/dynamodb/)

🔲 [Google Firestore](https://firebase.google.com/docs/firestore)

🔲 [CouchDB](https://couchdb.apache.org/)

🔲 [ScyllaDB](https://www.scylladb.com/)

🔲 [Start a discussion][github-new-discussion] to suggest others

### Installation

Add to your application's Gemfile. Note that `require: 'active_document'` contains an underscore (while the gem name does not.)

```ruby
gem 'activedocument', git: 'https://github.com/activedocument/activedocument.git', require: 'active_document'
```

### Compatibility

- Ruby
  - Ruby (MRI) 2.7+
  - Rails 6.0+
  - JRuby 9.4+
- MongoDB
  - MongoDB server 5.0+
  - MongoDB driver 2.18+

## OK, show me the code!

### Defining models

- Model fields and relations are defined in your Ruby classes.
- To add new fields or relations, simply add the field definition to your code then release a new version of your app,
  and the field will be included on documents saved thereafter. **No migrations and no `schema.rb` needed!**

```ruby
# /app/models/trainer.rb
class Trainer
  # Include base module into each model class
  include ActiveDocument::Document

  # Define database fields and types
  field :name, type: :string
  field :age,  type: :integer

  # Define relations to other database tables
  belongs_to_many :gyms

  # Models can be nested inside each other
  embeds_many :addresses

  # Can define methods as normal
  def battle(other_trainer)
    # ...
  end
end

# /app/models/gym.rb
class Gym
  include ActiveDocument::Document

  field :name, type: :string

  has_many :trainers

  embeds_many :addresses
end

# /app/models/address.rb
class Address
  include ActiveDocument::Document

  field :city,   type: :string
  field :region, type: :string

  embedded_in :addressable, polymorphic: true
end
```

### Persisting data

- Data can be assigned similarly to ActiveRecord.
- Many-to-many relationships are stored as Arrays of foreign keys in the database. **No join tables needed!**
- You may documents within other documents, which are stored using nested Array and Hash (Map) types in the database.
  Nesting may also be done N-levels deep.

```ruby
gym = Gym.new(name: 'Pewter City Gym')
gym.addresses.build(city: 'Pewter City', region: 'Kanto')
gym.save!

# Document persisted in database "gyms" table:
# {
#   "_id": "664c0c0cd777ae66fec0e8a4",
#   "name": "Pewter City Gym",
#   "addresses": [
#     {
#       "_id": "664c0c0cd777ae66fec0e8a6",
#       "city": "Pewter City",
#       "region": "Kanto"
#     }
#   ]
# }

trainer = Trainer.new(name: 'Ash', age: 10)
trainer.gyms << gym
trainer.addresses.build(city: 'Pallet Town', region: 'Kanto')
trainer.addresses.build(city: 'New Bark Town', region: 'Johto')
trainer.save!

# Document persisted in database "trainers" table:
# {
#   "_id": "664c0c0cd777ae66fec0e8a5",
#   "name": "Ash",
#   "age": 10,
#   "gym_ids": ["664c0c0cd777ae66fec0e8a4"],
#   "addresses": [
#     {
#       "_id": "664c0c0cd777ae66fec0e8a7",
#       "city": "Pallet Town",
#       "region": "Kanto"
#     }, {
#       "_id": "664c0c0cd777ae66fec0e8a8",
#       "city": "New Bark Town",
#       "region": "Johto"
#     }
#   ]
# }
```

### Querying and working with data

- You may retrieve models using chainable query methods similar to ActiveRecord.
- ActiveDocument also exposes the underlying NoSQL database query API where it is possible to do so.

```ruby
ash = Trainer.where(name: 'Ash').first
  #=> #<Trainer name="Ash", age=10>

# Query methods return an instance of `ActiveDocument::Criteria`,
# which is a chainable, lazy-evaluated query builder object.
team_rocket_query = Trainer.any_in(name: ['Jessie', 'James'])
  #=> #<ActiveDocument::Criteria>

team_rocket_query = team_rocket_query.where(age: { '$gt' => 20 })
  #=> #<ActiveDocument::Criteria>

# Call `.to_a`, `.first`, `.each`, `.map`, etc. to execute the query
# and return instance(s) of the model objects.
team_rocket = team_rocket_query.to_a
  #=> [#<Trainer name="Jessie", age=25>, #<Trainer name="James", age=27>]

ash.battle(team_rocket.first)
```

## Documentation

The documentation of this fork will be hosted at: https://activedocument.github.io/activedocument/ (not online yet!)

## Project History

ActiveDocument is a fork of [Mongoid](https://www.github.com/mongodb/mongoid) version 9.0.0.

Mongoid is maintained by MongoDB, Inc. and only supports MongoDB database. ActiveDocument aims to provide
an equally-robust level of support for MongoDB, while also adding support for other NoSQL databases.

## Roadmap

Refer to the [Roadmap issue](https://github.com/activedocument/activedocument/issues/1).

## Releases & Versioning

**⚠️ Important:** ActiveDocument is currently in `alpha` state. Any releases in the 2.x series should
be considered unstable. The first full release will be `3.0.0`.

- All new releases will undergo battle-testing in production at [TableCheck](https://www.tablecheck.com/en/join/) prior to being released.
- ActiveDocument will target to support new Ruby and Rails versions within 2 months of release.
- Support for new database versions is subject to community contributions. Databases tend to
  maintain a high degree of backwards compatibility.
- ActiveDocument will provide security patches for its 2 most recent major versions.
- ActiveDocument will drop support for end-of-life (EOL) Ruby, Rails, and database versions soon after EOL.

## Support

Support channels are yet to be established for ActiveDocument.

As ActiveDocument is forked from Mongoid, you may find some of the support resources for Mongoid to be useful:

* [Stack Overflow](http://stackoverflow.com/questions/tagged/mongoid)
* [MongoDB Community Forum](https://developer.mongodb.com/community/forums/tags/c/drivers-odms-connectors/7/mongoid-odm)

## Issues & Contributing

Issues should be raised in the [ActiveDocument Github issue tracker][github-new-issue].

### Security Issues

Security issues should be reported to [security@tablecheck.com](mailto:security@tablecheck.com).
The email should be encrypted with the following PGP public key:

* Key ID: `0xDF7D22A0E8772326`
* Fingerprint: `466C 56B9 E110 3CBA 2129 DBAD DF7D 22A0 E877 2326`

We appreciate your help to disclose security issues responsibly.

### Contributors

Big thanks to all [contributors to ActiveDocument][github-contributors],
including contributors to ActiveDocument's predecessor Mongoid.

## Project Governance

ActiveDocument is shepherded by the team at [TableCheck](https://www.tablecheck.com/en/join/)
based in Tokyo, Japan. TableCheck have been avid users of ActiveDocument's predecessor
Mongoid since 2013, contributing over 150 PRs to it and related projects. TableCheck uses
ActiveDocument to power millions of restaurant reservations each month, and are
*personally invested* in the making the best developer experience possible.

### 📣 Open Call for Community Steering Committee

If you would like to help with governance and/or maintenance of ActiveDocument,
please [raise an issue][github-new-issue].

### Purpose & Principles

The ActiveDocument project is committed to the following principles:

- Community involvement
- Database neutrality
- Feature robustness
- Performance
- Code quality
- Behavior rationality
- Developer experience
- Stability
- Transparency
- Full documentation

## Disclaimer

This project is not affiliated with or endorsed by MongoDB, Amazon Web Services, Google Cloud Platform,
the Apache Software Foundation, or any other entity not explicitly listed here.
Trademarks are property of their respective owners.

Code from the following repos is incorporated into ActiveDocument under the MIT License:
- [mongodb/mongoid](https://github.com/mongodb/mongoid)
- [mongodb-labs/mongo-ruby-spec-shared](https://github.com/mongodb-labs/mongo-ruby-spec-shared)
- [mongoid/mongoid-test-apps](https://github.com/mongoid/mongoid-test-apps)

[github-new-issue]: https://github.com/activedocument/activedocument/issues/new
[github-new-discussion]: https://github.com/activedocument/activedocument/discussions/new
[github-contributors]: https://github.com/activedocument/activedocument/graphs/contributors
[build-img]: https://github.com/activedocument/activedocument/actions/workflows/test.yml/badge.svg
[build-url]: https://github.com/activedocument/activedocument/actions
[rubygems-img]: https://badge.fury.io/rb/activedocument.svg
[rubygems-url]: http://badge.fury.io/rb/activedocument
[license-img]: https://img.shields.io/badge/license-MIT-green.svg
[license-url]: https://www.opensource.org/licenses/MIT
[codecov-img]: https://codecov.io/gh/activedocument/activedocument/graph/badge.svg?token=2MDF7F5GZ9
[codecov-url]: https://codecov.io/gh/activedocument/activedocument
