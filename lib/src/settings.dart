/// Allows you to save common settings into a settings
/// file so that you don't have to specify the same
/// command line arguments each time.
///
/// If a command line argument is provide it takes precendence
/// over the settings in this file.
///
///
library;

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:settings_yaml/settings_yaml.dart';

import 'multi_settings.dart';

class Settings {
  static const filename = '.pubrelease.yaml';

  late final String? username;

  late final String? apiToken;

  late final String? owner;

  late final String? repository;

  late final bool format;

  factory Settings.load() {
    final project = DartProject.findProject(pwd);

    if (project == null) {
      throw PubReleaseException(
          '''You must be in a Dart project directory containing a pubspec.yaml to run pub_release''');
    }
    final pathToSettings = join(project.pathToToolDir, filename);

    if (!exists(pathToSettings)) {
      return Settings._empty();
    }

    return Settings.loadFromPath(pathToSettings: pathToSettings);
  }

  Settings._empty() {
    format = false;
    username = null;
    apiToken = null;
    owner = null;
    repository = null;
  }

  @visibleForTesting
  Settings.loadFromPath({required String pathToSettings}) {
    final settings = SettingsYaml.load(pathToSettings: pathToSettings);

    username = settings['username'] as String?;
    apiToken = settings['apiToken'] as String?;
    owner = settings['owner'] as String?;
    repository = settings['repository'] as String?;
    format = settings['format'] as bool? ?? true;
  }
}
