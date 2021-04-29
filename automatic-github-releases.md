# Automatic github releases

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

