![ActiveDocument](https://github.com/activedocument/activedocument/assets/27655/f3e6284b-7d41-4273-8dd7-0a2317ae142c)

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

## 📣 Open Call for Community Steering Committee

If you would like to help with governance and/or maintenance of ActiveDocument, please [raise an issue](https://github.com/activedocument/activedocument/issues/new).

## Installation

Add to your application's Gemfile:

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

We will target to support new Ruby and Rails versions within 2 months of release.
ActiveDocument will provide security patches for its 2 most recent major versions.
ActiveDocument will drop support for end-of-life (EOL) Ruby, Rails, and database
versions soon after EOL.

## Purpose & Principles

This is a *community-driven fork of ActiveDocument*, intended to improve the following over MongoDB's ActiveDocument:

- Performance
- Feature robustness
- Code quality
- Behavior rationality
- Developer experience
- Stability
- Transparency
- Community involvement

This fork will merge in changes at least once-per-month from [mongodb/active_document](https://github.com/mongodb/active_document)
as its "upstream" repo. We may backport PRs to upstream where it makes sense to do so, but cannot guarantee that
the upstream will merge them.

## Releases & Versioning

**⚠️ Important:** ActiveDocument is currently in `alpha` state. Any releases in the 2.x series should
be considered unstable. The first full release will be `3.0.0`.

ActiveDocument is a fork of [Mongoid](https://www.github.com/mongodb/mongoid) from version 9.0.0.

All new versions will undergo battle-testing in production at [TableCheck](https://www.tablecheck.com/en/join/) prior to being released.

## Roadmap

Refer to the [Roadmap issue](https://github.com/activedocument/activedocument/issues/13).

#### Best Practices

- ✅ 100% code documentation coverage, enforced with Rubocop.

## Documentation

The documentation of this fork will be hosted at: https://activedocument.github.io/activedocument/ (not online yet!)

## Support

For beginners, please use MongoDB's existing ActiveDocument support resources:

* [Stack Overflow](http://stackoverflow.com/questions/tagged/activedocument)
* [MongoDB Community Forum](https://developer.mongodb.com/community/forums/tags/c/drivers-odms-connectors/7/active_document-odm)
* [#active_document](http://webchat.freenode.net/?channels=active_document) on Freenode IRC

## Issues & Contributing

Feature requests and bugs affecting both upstream and ActiveDocument should be reported in the [MongoDB MONGOID Jira](https://jira.mongodb.org/browse/MONGOID/).
Please also raise a [ActiveDocument Github issue](https://github.com/activedocument/activedocument/issues) in this project to track the fix. We prefer if upstream can make the fix first then we merge it.

Issues specific to ActiveDocument should be raised in the [ActiveDocument Github issue tracker](https://github.com/activedocument/activedocument/issues)

## Security Issues

Security issues should be reported to [security@tablecheck.com](mailto:security@tablecheck.com).
The email should be encrypted with the following PGP public key:

* Key ID: `0xDF7D22A0E8772326`
* Fingerprint: `466C 56B9 E110 3CBA 2129 DBAD DF7D 22A0 E877 2326`

We appreciate your help to disclose security issues responsibly.

## Project Governance

ActiveDocument is shepherded by the team at TableCheck. TableCheck have been avid ActiveDocument users since 2013,
contributing over 150 PRs to ActiveDocument and MongoDB Ruby projects. TableCheck uses ActiveDocument to power millions of
restaurant reservations each month, and are *personally invested* in the making the best user experience possible.

We invite experienced ActiveDocument hands in the community to apply for co-maintainership.
Please raise a [ActiveDocument Github issue](https://github.com/activedocument/activedocument/issues) if interested.

## Reasons for Forking

ActiveDocument started as an open-source project created by Durran Jordan in 2009. MongoDB Inc. took over maintainership in 2015.
Since the transition, the hallmarks of user-disconnect and corporate fumbling have become apparent:

- Introduction of [critical semver-breaking issues](https://serpapi.com/blog/how-a-routine-gem-update-ended-up-charging/), with [no](https://jira.mongodb.org/browse/MONGOID-5272) [sign](https://github.com/mongodb/active_document/pull/5601#issuecomment-1506630267) of [improvement](https://jira.mongodb.org/browse/MONGOID-5016).
- Lack of a publicly visible roadmap and direction (when requested, it was said to be a "corporate secret".)
- [Unwillingness](https://github.com/mongodb/active_document/pull/5546#issuecomment-1448910968) to [adopt](https://github.com/mongodb/active_document/pull/5553#issuecomment-1500361845) [basic](https://github.com/mongodb/bson-ruby/pull/284) industry-standard best practices, e.g. Rubocop linter and a publicly-visible CI workflow.
- Refusal to [merge](https://github.com/mongodb/active_document/pull/5541#discussion_r1101934994) [patches](https://github.com/mongodb/active_document/pull/5497) which would be of obvious benefit to the community.
- Lack of bandwidth and resources to review simple PR contributions.

**None of this is intended to disparage the hard-working and talented individuals at MongoDB Inc.**, but rather,
to illustrate that the corporate rules, philosophy, and priorities of MongoDB Inc. are not aligned with the needs
of its Ruby users.

It's time to do better! 💪 We hope this project encourages MongoDB Inc. to improve its own offering.

## Disclaimer

MongoDB, Mongo, and the leaf logo are registered trademarks of MongoDB, Inc. and are used in compliance with
[MongoDB's Trademark Usage Guidelines](https://www.mongodb.com/legal/trademark-usage-guidelines).
Any usage herein should not be construed as an endorsement or affiliation of MongoDB, Inc. with this project.

Code from the following related repos is incorporated under the MIT License:
- [mongodb-labs/mongo-ruby-spec-shared](https://github.com/mongodb-labs/mongo-ruby-spec-shared)
- [active_document/active_document-test-apps](https://github.com/active_document/active_document-test-apps)

[build-img]: https://github.com/activedocument/activedocument/actions/workflows/test.yml/badge.svg
[build-url]: https://github.com/activedocument/activedocument/actions
[rubygems-img]: https://badge.fury.io/rb/activedocument.svg
[rubygems-url]: http://badge.fury.io/rb/activedocument
[license-img]: https://img.shields.io/badge/license-MIT-green.svg
[license-url]: https://www.opensource.org/licenses/MIT
