# Attach an asset to a github release

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

## 

