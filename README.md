![ActiveDocument](https://github.com/activedocument/activedocument/assets/27655/d413fc53-821c-4028-a50b-029867cd9445)

# ActiveDocument

[![Build Status][build-img]][build-url]👨‍🔧
[![Gem Version][rubygems-img]][rubygems-url]🔜
[![License][license-img]][license-url]

**⚠️ ActiveDocument is currently in alpha**

ActiveDocument is a Ruby Object Document Mapper (ODM) for NoSQL databases.
Planned support includes:
- MongoDB
- AWS DynamoDB
- Google Firestore
- CouchDB

## Project History

ActiveDocument is a fork of [Mongoid](https://www.github.com/mongodb/mongoid) version 9.0.0.

Mongoid is maintained by MongoDB, Inc. and only supports MongoDB database. ActiveDocument aims to provide
an equally-robust level of support for MongoDB, while also adding support for other NoSQL databases.

## 📣 Open Call for Community Steering Committee

If you would like to help with governance and/or maintenance of ActiveDocument, please [raise an issue](https://github.com/activedocument/activedocument/issues/new).

## Installation

Add to your application's Gemfile. Note that `require: 'active_document'` contains an underscore (while the gem name does not.)

```ruby
gem 'activedocument', git: 'https://github.com/activedocument/activedocument.git', require: 'active_document'
```

## Compatibility

- Ruby
  - Ruby (MRI) 2.7+
  - Rails 6.0+
  - JRuby 9.4+
- MongoDB
  - MongoDB server 4.4+
  - MongoDB driver 2.18+

## Version Lifecycle

- ActiveDocument will target to support new Ruby and Rails versions within 2 months of release.
- Support for new database versions is subject to community contributions. Databases tend to
  maintain a high degree of backwards compatibility.
- ActiveDocument will provide security patches for its 2 most recent major versions.
- ActiveDocument will drop support for end-of-life (EOL) Ruby, Rails, and database versions soon after EOL.

## Roadmap

Refer to the [Roadmap issue](https://github.com/activedocument/activedocument/issues/1).

## Purpose & Principles

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

## Releases & Versioning

**⚠️ Important:** ActiveDocument is currently in `alpha` state. Any releases in the 2.x series should
be considered unstable. The first full release will be `3.0.0`.

All new versions will undergo battle-testing in production at [TableCheck](https://www.tablecheck.com/en/join/) prior to being released.

## Documentation

The documentation of this fork will be hosted at: https://activedocument.github.io/activedocument/ (not online yet!)

## Support

Support channels are yet to be established for ActiveDocument.

As ActiveDocument is forked from Mongoid, you may find some of the support resources for Mongoid to be useful:

* [Stack Overflow](http://stackoverflow.com/questions/tagged/mongoid)
* [MongoDB Community Forum](https://developer.mongodb.com/community/forums/tags/c/drivers-odms-connectors/7/mongoid-odm)

## Issues & Contributing

Issues should be raised in the [ActiveDocument Github issue tracker](https://github.com/activedocument/activedocument/issues).

## Security Issues

Security issues should be reported to [security@tablecheck.com](mailto:security@tablecheck.com).
The email should be encrypted with the following PGP public key:

* Key ID: `0xDF7D22A0E8772326`
* Fingerprint: `466C 56B9 E110 3CBA 2129 DBAD DF7D 22A0 E877 2326`

We appreciate your help to disclose security issues responsibly.

## Project Governance

ActiveDocument is shepherded by the team at TableCheck. TableCheck have been avid users of ActiveDocument's predecessor
Mongoid since 2013, contributing over 150 PRs to it and related projects. TableCheck uses ActiveDocument to power millions of
restaurant reservations each month, and are *personally invested* in the making the best developer experience possible.

We invite experienced hands in the community to apply for co-maintainership.
Please raise a [ActiveDocument Github issue](https://github.com/activedocument/activedocument/issues) if interested.

## Contributors

Big thanks to all [contributors to ActiveDocument](https://github.com/activedocument/activedocument/graphs/contributors),
including contributors to ActiveDocument's predecessor Mongoid.

## Disclaimer

This project is not affiliated with or endorsed by MongoDB, Amazon Web Services, Google Cloud Platform, or
the Apache Software Foundation. Trademarks are property of their respective owners.

Code from the following repos is incorporated into ActiveDocument under the MIT License:
- [mongodb/mongoid](https://github.com/mongodb/mongoid)
- [mongodb-labs/mongo-ruby-spec-shared](https://github.com/mongodb-labs/mongo-ruby-spec-shared)
- [mongoid/mongoid-test-apps](https://github.com/mongoid/mongoid-test-apps)

[build-img]: https://github.com/activedocument/activedocument/actions/workflows/test.yml/badge.svg
[build-url]: https://github.com/activedocument/activedocument/actions
[rubygems-img]: https://badge.fury.io/rb/activedocument.svg
[rubygems-url]: http://badge.fury.io/rb/activedocument
[license-img]: https://img.shields.io/badge/license-MIT-green.svg
[license-url]: https://www.opensource.org/licenses/MIT
