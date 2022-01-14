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

* Install Pub Release globally with:

```bash
dart pub global activate pub_release
```

* Read the [full documentation](https://pubrelease.noojee.dev/) to learn how to use it

