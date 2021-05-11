# Creating a release

To update the version no. and publish your project run:

```bash
pub_release
```

The pub\_release command will:

* prompt you to select the new version number
* update pubspec.yaml with the new version no.
* create/update a version file in src/util/version.g.dart
* format your code with dartfmt
* analyze you code with dartanalyzer
* Generate a default change log entry using your commit history
* Allow you to edit the resulting change log.
* push all commits to git
* run any scripts found in the pre\_release\_hook directory.
* publish your project to pub.dev
* run any scripts found in the post\_release\_hook directory.

### dry-run

You can pass the `--dry-run` flag on the `pub_release` command line. In this case the pub\_release process is run but no modifications are made to to the project \(except for code formatting\). The `dart pub publish` command is also run with the `--dry-run` switch so suppress publishing the package.

