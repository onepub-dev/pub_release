Pub Release is a package to assist in publishing dart/flutter packages to pub.dev.

Pub Release performs the following operations:

* Formats all code using dartfmt
* Increments the version no. using semantic versioning after asking what sort of changes have been made.
* Creates a dart file containing the version no. in src/version/version.g.dart
* Updates the pubspec.yaml with the new version no.
* If you are using Git:
  * Generates a Git Tag using the new version no.
  * Generates release notes from  commit messages since the last tag.
* Allows you to edit the release notes.
* Adds the release notes to CHANGELOG.MD along with the new version no.
* Publishes the package to pub.dev.

# creating a release

To update the version no. and publish your project run:

pub_release

The pub_release command will:
 * prompt you to select the new version number
 * update pubspec.yaml with the new version no.
 * create/udpate a version file in src/util/version.g.dart
 * format your code with dartfmt
 * analyze you code with dartanalyzer
 * Generate a default change log entry using your commit history
 * Allow you to edit the resulting change log.
 * push all commits to git
 * run any scripts found in the pre_release_hook directory.
 * publish your project to pub.dev
 * run any scripts found in the post_release_hook directory.

# Hooks
pub_release supports the concept of pre and post release hooks.

A hook is simply a script that is run before or after the release is pushed to pub.dev.

Hooks live in the following directories:

* `<project root>`/tool/pre_release_hook
* `<project root>`/tool/post_release_hook

Where the `project root` is the directory where your pubspec.yaml lives.

You can include any number of scripts in each of these diretories and they will be run in alphabetical order.




To create a git hub release run:

github_release -u <github username> --apiToken <github api token> --owner <github repo owner> --repository <github repo>

If you want to automate the creating of the git release as put of you pub release then add the following dcli script
to a directory called:

tool/post_release_hook

(under you projects root directory)

```dart
#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';


void main(List<String> args) {
  var username = '<github username>';
  var apiToken = '<git hub api token>';
  var owner = '<repo owner>';
  var repository = '<github repo>';

  'github_release -u $username --apiToken $apiToken --owner $owner --repository $repository --suffix linux'
      .start(workingDirectory: Script.current.pathToProjectRoot);
}
```

You will need to obtain a github personal access token:

https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token

You will need to install dcli via:

```
pub global activate dcli
dcli install
```

Don't panic if the dcli install fails it is still a work in progress but it will get far enough to meet pub_release's requirements.


# automating releases

You can automate the creation of git release tags from a github workflow via:

* github_workflow_release

```
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
      run: github_workflow_release --username <user> --apiToken "$APITOKEN" --owner <owner> --repository <repo> --suffix linux 
```

You need to update the `<user>`, `<owner>` and `<repo>` with the appropriate github values.

You also need to add you personal api token as a secret in github

https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets
