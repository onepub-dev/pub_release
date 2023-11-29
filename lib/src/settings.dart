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

class Settings {
  factory Settings.load() => Settings.loadFromPath(
      pathToSettings: join(DartProject.self.pathToDartToolDir, filename));

  @visibleForTesting
  Settings.loadFromPath({required String pathToSettings}) {
    settings = SettingsYaml.load(pathToSettings: pathToSettings);

    username = settings['username'] as String?;
    apiToken = settings['apiToken'] as String?;
    owner = settings['owner'] as String?;
    repository = settings['repository'] as String?;
    format = settings['format'] as bool? ?? true;
  }

  static const filename = '.pubrelease.yaml';

  late final SettingsYaml settings;

  late final String? username;
  late final String? apiToken;
  late final String? owner;
  late final String? repository;

  late final bool format;
}
