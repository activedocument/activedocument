![Mongoid: Ultra Edition](https://repository-images.githubusercontent.com/298015080/6028fc36-ae5d-46c1-af7a-19dc3c7f56f1)

# Mongoid: Ultra Edition

[![Build Status][build-img]][build-url]
[![Gem Version][rubygems-img]][rubygems-url]
[![License][license-img]][license-url]

The no-baloney fork of Mongoid. Made by the community, for the community.
Mongoid is the Ruby Object Document Mapper (ODM) for MongoDB.

This fork of Mongoid is **not** endorsed by or affiliated with MongoDB Inc. 👍

## Installation

Replace `gem 'mongoid'` in your application's Gemfile with:

```ruby
gem 'mongoid-ultra'
```

(Do **not** install `mongoid` and `mongoid-ultra` at the same time.)

## Compatibility

- Ruby (MRI) 2.7 - 3.2
- JRuby 9.4
- MongoDB server 4.4 - 6.0

Version support may differ from MongoDB's Mongoid release.

## Purpose & Principles

This is a *community-driven fork of Mongoid*, intend to improve the following over MongoDB's Mongoid:

- Feature robustness
- Code quality
- Behavior rationality
- Developer experience
- Stability
- Transparency
- Community involvement

This fork will merge in changes at least once-per-month from [mongodb/mongoid](https://github.com/mongodb/mongoid)
as its "upstream" repo. We may backport PRs to upstream where it makes sense to do so, but cannot guarantee that
the upstream will merge them.

## Releases & Versioning

**Important:** Mongoid Ultra is currently in `alpha` state. The first full release will be `9.0.0.0`.

For the time being, version numbers will shadow those of `mongodb/mongoid` with an additional "patch" number added:

`X.Y.Z.P`

Where `X.Y.Z` is the latest upstream release version, and `P` is the patch version of this repo.
`P` will be reset to zero anytime the major version `X` changes, but will not be reset when the minor or tiny `Y`/`Z` version changes.
We will also use `-alpha`, `-beta`, `-rc`, etc. suffixes to denote pre-releases.

**Semver**: For the time being will follow the major version component of semver, i.e. not breaking or
removing functionality *except* in major (`X`) releases. We may introduce new features in new patch (`P`) releases,
and will use feature flags prefixed with `ultra_` to allow users to opt-in.

All new versions will undergo battle-testing in production at TableCheck prior to being released.

## Roadmap

- [ ] Establish maintainers and governance board.
- [ ] Publish documentation.
- [ ] Drop support for old Ruby, Rails, and MongoDB server versions.
- [ ] Full documentation coverage.
- [ ] Full Rubocop compliance and coverage.
- [ ] Remove all monkey-patching.
- [ ] Merge patches rejected by MongoDB.
- [ ] Refactor persistence type-validation (mongoize, etc.)
- [ ] Extract unsafe chaining `and` and `or` operators to a gem. Require usage of `all_of` and `any_of` instead.
- [ ] Extract `:field.in => [1, 2, 3]` query syntax to a gem. Require usage of `field: { '$in' => [1, 2, 3] }` instead.
- [ ] Allow symbol instead of classes in `field :type` declarations.
- [ ] Refactor relations (`belongs_to_one`, `belongs_to_many`)

## Notable Differences from MongoDB Mongoid

- ✅ Use a publicly visible CI (Github Actions) as the primary CI. Remove Evergreen CI.
- ✅ Remove MRSS submodules and other MongoDB corporate baloney.
- ✅ [MONGOID-5570](https://jira.mongodb.org/browse/MONGOID-5570) - Code Docs: Ensure 100% documentation coverage, enforced with Rubocop.
- ✅ [MONGOID-5564](https://jira.mongodb.org/browse/MONGOID-5564) - Code Docs: Use full namespaces in docs.
- More to come soon!

## Documentation

The documentation of this fork will be hosted at: https://tablecheck.github.io/mongoid-ultra/ (not online yet!)

## Support

For beginners, please use MongoDB's existing Mongoid support resources:

* [Stack Overflow](http://stackoverflow.com/questions/tagged/mongoid)
* [MongoDB Community Forum](https://developer.mongodb.com/community/forums/tags/c/drivers-odms-connectors/7/mongoid-odm)
* [#mongoid](http://webchat.freenode.net/?channels=mongoid) on Freenode IRC

## Issues & Contributing

Feature requests and bugs affecting both upstream and Mongoid Ultra should be reported in the [MongoDB MONGOID Jira](https://jira.mongodb.org/browse/MONGOID/).
Please also raise a [Mongoid Ultra Github issue](https://github.com/tablecheck/mongoid-ultra/issues) in this project to track the fix. We prefer if upstream can make the fix first then we merge it.

Issues specific to Mongoid Ultra should be raised in the [Mongoid Ultra Github issue tracker](https://github.com/tablecheck/mongoid-ultra/issues)

## Security Issues

Security issues affecting both upstream and Mongoid Ultra should be
[reported to MongoDB](https://www.mongodb.com/docs/manual/tutorial/create-a-vulnerability-report/).

Security issues affecting only Mongoid Ultra should be reported to [security@tablecheck.com](mailto:security@tablecheck.com).
The email should be encrypted with the following PGP public key:

* Key ID: `0xDF7D22A0E8772326`
* Fingerprint: `466C 56B9 E110 3CBA 2129 DBAD DF7D 22A0 E877 2326`

We appreciate your help to disclose security issues responsibly.

## Maintainership

Mongoid Ultra is shepherded by the team at TableCheck. TableCheck have been avid Mongoid users since 2013,
contributing over 150 PRs to Mongoid and MongoDB Ruby projects. TableCheck uses Mongoid to power millions of
restaurant reservations each month, and are *personally invested* in the making the best user experience possible.

We invite experienced Mongoid hands in the community to apply for co-maintainership.
Please raise a [Mongoid Ultra Github issue](https://github.com/tablecheck/mongoid-ultra/issues) if interested.

## Reasons for Forking

Mongoid started as an open-source project created by Durran Jordan in 2009. MongoDB Inc. took over maintainership in 2015.
Since the transition, the hallmarks of user-disconnect and corporate fumbling have become apparent:

- Introduction of [critical semver-breaking issues](https://serpapi.com/blog/how-a-routine-gem-update-ended-up-charging/).
- Lack of a publicly visible roadmap or direction (when requested, it was said to be a "corporate secret".)
- Unwillingness to adopt basic best industry-standard practices, e.g. Rubocop linter and a publicly-visible CI workflow.
- Refusal to merge patches which would be of obvious benefit to the community.
- Lack of bandwidth and resources to review simple PR contributions.

**None of this is intended to disparage the hard-working and talented individuals at MongoDB Inc.**, but rather,
to illustrate that the corporate rules, philosophy, and priorities of MongoDB Inc. are not aligned with the needs
of its Ruby users.

It's time to do better! 💪 We hope this project encourages MongoDB Inc. to improve its own offering.

## Disclaimer

MongoDB, Mongo, and the leaf logo are registered trademarks of MongoDB, Inc. and are used in compliance with
[MongoDB Inc.'s Trademark Usage Guidelines](https://www.mongodb.com/legal/trademark-usage-guidelines).
Any usage herein should not be construed as an endorsement or affiliation with this project.

[build-img]: https://github.com/tablecheck/mongoid-ultra/actions/workflows/test.yml/badge.svg
[build-url]: https://github.com/tablecheck/mongoid-ultra/actions
[rubygems-img]: https://badge.fury.io/rb/mongoid-ultra.svg
[rubygems-url]: http://badge.fury.io/rb/mongoid-ultra
[license-img]: https://img.shields.io/badge/license-MIT-green.svg
[license-url]: https://www.opensource.org/licenses/MIT
