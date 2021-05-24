# Creating a release

To update the version no. and publish your project run:

```bash
pub_release
```

The pub\_release command will:

* prompt you to select the new version number
* update pubspec.yaml with the new version no.
* create/update a[ version file ](version-file.md)in src/util/version.g.dart
* format your code with dartfmt
* analyze you code with dartanalyzer
* Generate a default change log entry using your commit history
* Allow you to edit the resulting change log.
* push all commits to git
* run any scripts found in the [pre\_release\_hook](hooks.md) directory.
* remove and restore any dependency overrides in your pubspec.yaml
* publish your project to pub.dev
* run any scripts found in the [post\_release\_hook](hooks.md) directory.

### --dry-run

You can pass the `--dry-run` flag on the `pub_release` command line. In this case the pub\_release process is run but no modifications are made to to the project \(except for code formatting\). The `dart pub publish` command is also run with the `--dry-run` switch so suppress publishing the package.

### --\[no\]-test

By default pub-release will run all unit tests \(via the critical\_test package\) before doing a release.

If any unit tests fail then the release will be halted.

You can by pass the running of unit tests by passing the `--no-test` flag on the command line.

### --\[no\]-git

By default pub\_release detects if your code is managed by git.

If the code is managed by git then it will automatically commit any changes made during the release process as well as creating a release tag.

You can suppress all git operations by passing the `--no-git` flag.

Note: git operations are only supported against github. If you remote git repo is other than github then you should always use the `--no-git` flag.

pub\_release will work if you just have a local git repo with no remote set.

### --autoAnswer

If you pass the `--autoAnswer` flag then the user will no be prompted during the release process.

If you use the `--autoAnswer` flag you MUST also pass the `--setVersion` flag.

### --setVersion

The `--setVersion` option allows you to set the version from the command line.

If the `--setVersion` option isn't passed then you will be prompted to select the version no.

### --line

The `--line` option allows you to override the default line width \(80\) used when formatting code.

We recommend that you use the dart default width of 80.

### --tags

By default pub\_release runs every test that is not marked as 'skipped'.

You can limit the set of test by passing in the --tag option.

```text
pub_release --tag='OnlyTheGoodOnes'
```

See the [test](https://pub.dev/packages/test#tagging-tests) guide for details on how to setup and select tests via tags.

### --exclude-tags

By default pub\_release runs every test that is not marked as 'skipped'.

You can exclude certain tests by passing in the --exclude-tags option.



```text
pub_release --exclude-tags='slow'
```

See the [test](https://pub.dev/packages/test#tagging-tests) guide for details on how to setup and exclude tests via tags.

### --multi

Performs a multi-package release.

Use the `--multi` flag when you have [multiple related packages](simultaneous-releases/) that need to be released in sync with a single version no.

