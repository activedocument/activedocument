# PR #4: Gem Rename to ActiveDocument

**Date:** 2024-05-19
**PR:** https://github.com/activedocument/activedocument/pull/4
**Type:** Major refactor (namespace change)

## Summary

This PR performs a comprehensive rename of the library from `Mongoid` to `ActiveDocument`, establishing the project's new identity as an independent fork.

## Changes

### Namespace Rename
- All `Mongoid::` namespace references changed to `ActiveDocument::`
- All file paths renamed from `lib/mongoid/` to `lib/active_document/`
- Gem name changed from `mongoid.gemspec` to `active_document.gemspec`

### Error Class Restructure
- Base error class renamed from `Mongoid::Errors::MongoidError` to `ActiveDocument::Errors::BaseError`
- Removed `GemConflict` and `BundleChecker` (Mongoid-specific utilities no longer needed)

### Configuration Changes
- Configuration module renamed throughout
- Environment variables still use `MONGOID_` prefix for backwards compatibility with existing deployments

### Documentation Updates
- README completely rewritten for ActiveDocument branding
- All tutorial and reference documentation updated with new naming

## Impact

This is a breaking change that affects:
- All `include Mongoid::Document` declarations → `include ActiveDocument::Document`
- All `Mongoid.configure` calls → `ActiveDocument.configure`
- All error rescue blocks referencing `Mongoid::Errors::*`

## Migration Path

Users migrating from Mongoid should:
1. Find/replace `Mongoid::` → `ActiveDocument::` in application code
2. Find/replace `include Mongoid::` → `include ActiveDocument::` in models
3. Update Gemfile from `gem 'mongoid'` to `gem 'activedocument'`

## Files Changed

- 6,900 additions, 7,065 deletions
- Touches nearly every file in the codebase
