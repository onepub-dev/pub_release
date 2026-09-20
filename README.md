# README

Pub Release is a package that automates publishing dart/flutter packages to pub.dev.

Pub Release also supports the [simultaneous](simultaneous-releases/) release of multiple related packages.

Pub Release performs the following operations:

* Run pre/post release 'hook' scripts.
* Formats all code using dartfmt
* Increments the version no. using semantic versioning after asking what sort of changes have been made.
* Creates a dart file containing the version no. in src/version/version.g.dart
* Updates the pubspec.yaml with the new version no.
* If you are using Git:
  * Generates a Git Tag using the new version no.
  * Generates release notes from  commit messages since the last tag.
  * Publish any executables list in pubspec.yaml as assets on github
* Allows you to edit the release notes.
* Adds the release notes to CHANGELOG.MD along with the new version no.
* Publishes the package to pub.dev.

## Getting Started

Install Pub Release globally:

```bash
dart pub global activate pub_release
```

Run it from your package root:

```bash
pub_release
```

Read the [full documentation](https://pubrelease.onepub.dev/) to learn how to use it.

## Common Workflows

Dry-run a release (no publish):

```bash
pub_release --dry-run
```

Set a specific version and skip prompts:

```bash
pub_release --setVersion=1.2.3 --autoAnswer
```

Run multi-package release in a mono-repo:

```bash
pub_release multi
```

## Dry Run

Use `--dry-run` to validate a release without publishing. During a dry run,
pub_release performs the publish step inside a temporary copy of your package
to avoid git working tree warnings while still validating the generated
version and changelog.

If you need to allow warnings from `dart pub publish`, pass
`--ignore-warnings`.

## Commands

* `pub_release` - release a single package (default).
* `pub_release multi` - release related packages using `tool/pubrelease.multi.yaml`.
* `pub_release help` - show usage.

## Flags

* `--dry-run` - validate but do not publish.
* `--ignore-warnings` - pass `--ignore-warnings` to `dart pub publish`.
* `--[no]-test` - enable/disable unit tests (default: on).
* `--test-concurrency=<n>` - maximum concurrent test suites (positive integer); overrides the project setting.
* `--line=<n>` - formatter line length (default: 80).
* `--[no]-format` - enable/disable formatting (default: on).
* `--verbose` - enable verbose logging.
* `--git` - enable git operations (default: on).
* `--no-multi` - disable multi-release even if a multi config exists.
* `--askVersion` - prompt for version (default).
* `--setVersion=<x.y.z>` - set version directly.
* `--autoAnswer` - suppress prompts (requires `--setVersion`).
* `--tags=<tag,...>` - only run tests matching tags.
* `--exclude-tags=<tag,...>` - exclude tests by tag.
* `--skip-packages=<name,...>` - skip named packages when running the `multi` command.

## Test Concurrency

For projects whose tests share external state, run test suites serially by adding
the following to `tool/.pubrelease.yaml`:

```yaml
test-concurrency: 1
```

Override the project setting for a release with:

```bash
pub_release --test-concurrency=4
```

Pub Release passes the selected value to `critical_test` as `--concurrency=<n>`.
The value must be a positive integer. If neither setting is provided,
critical_test's default concurrency is unchanged. For multi-package releases,
the selected value applies to every released package. `--no-test` still skips
tests regardless of the concurrency setting.

## Multi Release Notes

When using `pub_release multi`, the first package that generates a changelog
entry will have its release notes propagated to the other packages unless they
already contain notes for that version.
