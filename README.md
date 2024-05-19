![ActiveDocument: Ultra Edition](https://repository-images.githubusercontent.com/298015080/6028fc36-ae5d-46c1-af7a-19dc3c7f56f1)

# ActiveDocument: Ultra Edition

[![Build Status][build-img]][build-url]👨‍🔧
[![Gem Version][rubygems-img]][rubygems-url]🔜
[![License][license-img]][license-url]

The no-baloney fork of ActiveDocument. Made by the community, for the community.
ActiveDocument is the Ruby Object Document Mapper (ODM) for MongoDB.

This fork of ActiveDocument is **not** endorsed by or affiliated with MongoDB Inc. 👍

## 📣 Open Call for Community Steering Committee

If you would like to help with governance and/or maintenance of this project, please [raise an issue](https://github.com/tablecheck/active_document-ultra/issues/new).

## Installation

Add to your application's Gemfile:

```ruby
gem 'active_document'
```

## Compatibility

- Rails 6.0+
- Ruby (MRI) 2.7+
- JRuby 9.4+
- MongoDB server 4.4+

Version support may differ from MongoDB ActiveDocument. We will target to have support for new
Ruby and Rails versions within 1 month of release. As a general policy, ActiveDocument Ultra will
drop support for end-of-life (EOL) versions soon after EOL. If you are using unsupported EOL
software, please stick with an older version of ActiveDocument until you upgrade.

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

**Important:** ActiveDocument Ultra is currently in `alpha` state. The first full release will be `9.0.0.0`.

For the time being, version numbers will shadow those of `mongodb/active_document` with an additional "patch" number added:

`X.Y.Z.P`

Where `X.Y.Z` is the latest upstream release version, and `P` is the patch version of this repo.
`P` will be reset to zero anytime the major version `X` changes, but will not be reset when the minor or tiny `Y`/`Z` version changes.
We will also use `.alpha1`, `.beta1`, `.rc1`, etc. suffixes to denote pre-releases.

**Semver**: For the time being will follow the major version component of semver, i.e. not breaking or
removing functionality *except* in major `X` releases. We may introduce new features in new patch `P` releases,
and will use feature flags prefixed with `ultra_` to allow users to opt-in.

You may distinguish ActiveDocument Ultra from MongoDB ActiveDocument by the constant `ActiveDocument::ULTRA == true`.

All new versions will undergo battle-testing in production at TableCheck prior to being released.

## Roadmap

Refer to the [Roadmap issue](https://github.com/tablecheck/active_document-ultra/issues/13).

## Differences versus MongoDB ActiveDocument

#### Additions

- ✅ [MONGOID-5391](https://jira.mongodb.org/browse/MONGOID-5391) - Add `Criteria#pluck_each` high-performance iterator method.
- ✅ [MONGOID-5556](https://jira.mongodb.org/browse/MONGOID-5556) - Add `Criteria#tally` `:unwind` arg to splat array results.
- More to come soon!

#### Bug Fixes

- 🐞 [MONGOID-5559](https://jira.mongodb.org/browse/MONGOID-5559) - `BigDecimal` should correctly type-cast to `Time`.

#### Best Practices

- ✅ [MONGOID-5570](https://jira.mongodb.org/browse/MONGOID-5570) - Code Docs: Ensure 100% documentation coverage, enforced with Rubocop.
- ✅ [MONGOID-5564](https://jira.mongodb.org/browse/MONGOID-5564) - Code Docs: Use full namespaces in docs.
- ✅ [MONGOID-5572](https://jira.mongodb.org/browse/MONGOID-5572) - RSpec: Use expectation syntax, enforced with RSpec config setting.

#### Removals

- 🙅🏾‍♀️ Remove Evergreen CI and replace with Github Actions which is publicly visible and auto-runs on all contributor patches.
- 🙅🏼 Remove MRSS submodules and other MongoDB Inc. corporate baloney.
- 🙅🏻‍♂️️ [MONGOID-5579](https://jira.mongodb.org/browse/MONGOID-5579) - Drop support for versions earlier than MongoDB 4.4, Ruby 2.7, Rails 6.0, JRuby 9.4 and remove deprecated cruft.
- 🙅🏾‍♀️ [MONGOID-5597](https://jira.mongodb.org/browse/MONGOID-5597) - Remove `ActiveDocument::QueryCache` in favor of `Mongo::QueryCache`.

## Documentation

The documentation of this fork will be hosted at: https://tablecheck.github.io/active_document-ultra/ (not online yet!)

## Support

For beginners, please use MongoDB's existing ActiveDocument support resources:

* [Stack Overflow](http://stackoverflow.com/questions/tagged/active_document)
* [MongoDB Community Forum](https://developer.mongodb.com/community/forums/tags/c/drivers-odms-connectors/7/active_document-odm)
* [#active_document](http://webchat.freenode.net/?channels=active_document) on Freenode IRC

## Issues & Contributing

Feature requests and bugs affecting both upstream and ActiveDocument Ultra should be reported in the [MongoDB MONGOID Jira](https://jira.mongodb.org/browse/MONGOID/).
Please also raise a [ActiveDocument Ultra Github issue](https://github.com/tablecheck/active_document-ultra/issues) in this project to track the fix. We prefer if upstream can make the fix first then we merge it.

Issues specific to ActiveDocument Ultra should be raised in the [ActiveDocument Ultra Github issue tracker](https://github.com/tablecheck/active_document-ultra/issues)

## Security Issues

Security issues affecting both upstream and ActiveDocument Ultra should be
[reported to MongoDB](https://www.mongodb.com/docs/manual/tutorial/create-a-vulnerability-report/).

Security issues affecting only ActiveDocument Ultra should be reported to [security@tablecheck.com](mailto:security@tablecheck.com).
The email should be encrypted with the following PGP public key:

* Key ID: `0xDF7D22A0E8772326`
* Fingerprint: `466C 56B9 E110 3CBA 2129 DBAD DF7D 22A0 E877 2326`

We appreciate your help to disclose security issues responsibly.

## Project Governance

ActiveDocument Ultra is shepherded by the team at TableCheck. TableCheck have been avid ActiveDocument users since 2013,
contributing over 150 PRs to ActiveDocument and MongoDB Ruby projects. TableCheck uses ActiveDocument to power millions of
restaurant reservations each month, and are *personally invested* in the making the best user experience possible.

We invite experienced ActiveDocument hands in the community to apply for co-maintainership.
Please raise a [ActiveDocument Ultra Github issue](https://github.com/tablecheck/active_document-ultra/issues) if interested.

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

[build-img]: https://github.com/tablecheck/active_document-ultra/actions/workflows/test.yml/badge.svg
[build-url]: https://github.com/tablecheck/active_document-ultra/actions
[rubygems-img]: https://badge.fury.io/rb/active_document-ultra.svg
[rubygems-url]: http://badge.fury.io/rb/active_document-ultra
[license-img]: https://img.shields.io/badge/license-MIT-green.svg
[license-url]: https://www.opensource.org/licenses/MIT
