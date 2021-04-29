# README

Pub Release is a package to assist in publishing dart/flutter packages to pub.dev.

Pub Release performs the following operations:

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
* Run pre/post release 'hook' scripts.

## creating a release

To update the version no. and publish your project run:

pub\_release

The pub\_release command will:

* prompt you to select the new version number
* update pubspec.yaml with the new version no.
* create/udpate a version file in src/util/version.g.dart
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

## Hooks

pub\_release supports the concept of pre and post release hooks.

A hook is simply a script that is run before or after the release is pushed to pub.dev.

Hooks live in the following directories:

* `<project root>`/tool/pre\_release\_hook
* `<project root>`/tool/post\_release\_hook

Where the `project root` is the directory where your pubspec.yaml lives.

You can include any number of scripts in each of these directories and they will be run in alphabetical order.

When your hook is called it will be passed the new version as a cli argument:

```bash
my_hook.dart 1.0.0
```

### dry-run

If the `--dry-run` flag is passed to the `pub_release` command then a `--dry-run` flag will be passed on the command line to the hook.

If the `--dry-run` flag is passed than your hook should suppress any actions that permanently modify the project.

```bash
my_hook.dart --dry-run 1.0.0
```

## Automatic git hub releases

You can use pub\_release to automate the creation of a git 'release' each time you publish your package:

Install dcli which we will use to create the hook.

```bash
pub global activate dcli
dcli install
```

You will need to obtain a github personal access token:

[https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)

Copy the following script to:

`<project root>/tool/post_release_hook\git_release.dart`

```dart
#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:settings_yaml/settings_yaml.dart';

void main(List<String> args) {
  var project = DartProject.current;

  var pathToSettings = join(project.pathToProjectRoot, 'tool', 'post_release_hook', 'settings.yaml');
  var settings = SettingsYaml.load(pathToSettings: pathToSettings);
  var username = settings['username'] as String;
  var apiToken = settings['apiToken'] as String;
  var owner = settings['owner'] as String;
  var repository = settings['repository'] as String;

  'github_release -u $username --apiToken $apiToken --owner $owner --repository $repository'
      .start(workingDirectory: Script.current.pathToProjectRoot);
}
```

on linux and osx mark the script as executable:

```bash
sudo chmod +x git_release.dart
```

Create a settings.yaml file in:

`<project root>/tool/post_release_hook\settings.yaml`

{% hint style="danger" %}
WARNING: DO NOT ADD SETTINGS.YAML TO YOUR GIT REPO!
{% endhint %}

Update the settings.yaml file with your git configuration.

```text
username: <your github username>
apiToken: <your git hub access token>
owner: <your git hub repo owner name>
repository: <your git hub repository name>
```

Modify each of the strings '' to match your configuration.

e.g.

```text
username: my@email.com.au
apiToken: XXXXXXXX
owner: bsutton
repository: pub_release
```

Now when you run pub\_release it will detect your hook and create a github release.

## Attach an asset to a github release:

You can use pub\_release to automatically attach an asset to a git 'release'.

Install dcli which we will use to create the hook.

```bash
pub global activate dcli
dcli install
```

You will need to obtain a github personal access token:

[https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)

Copy the following script to:

`<project root>/tool/post_release_hook\publish_asset.dart`

```dart
#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:settings_yaml/settings_yaml.dart';

void main(List<String> args) {
  var project = DartProject.current;

  var pathToSettings = join(project.pathToProjectRoot, 'tool', 'post_release_hook', 'settings.yaml');
  var settings = SettingsYaml.load(pathToSettings: pathToSettings);
  var username = settings['username'] as String;
  var apiToken = settings['apiToken'] as String;
  var owner = settings['owner'] as String;
  var repository = settings['repository'] as String;

  'github_release -u $username --apiToken $apiToken --owner $owner --repository $repository'
      .start(workingDirectory: Script.current.pathToProjectRoot);
}
```

## Automating releases using Git work flows

You can automate the creation of git release tags from a github workflow via:

* github\_workflow\_release

```text
name: Release executables for Linux

on:
  push:
#    tags:
#      - '*'

jobs:
  build:
    runs-on: ubuntu-latest

    container:
      image:  google/dart:latest

    steps:
    - uses: actions/checkout@v2

    - name: setup paths
      run: export PATH="${PATH}":/usr/lib/dart/bin:"${HOME}/.pub-cache/bin"

    - name: install pub_release
      run: pub global activate pub_release
    - name: Create release
      env:
        APITOKEN:  ${{ secrets.APITOKEN }}
      run: github_workflow_release --username <user> --apiToken "$APITOKEN" --owner <owner> --repository <repo>
```

You need to update the `<user>`, `<owner>` and `<repo>` with the appropriate github values.

You also need to add you personal api token as a secret in github

[https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)

