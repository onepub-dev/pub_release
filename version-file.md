# Version File

When creating a release, pub\_release will create or update a dart file containing the package version no.

The version file is called:

```text
lib/src/version/version.g.dart
```

The contents of the version file will be:

```dart
/// GENERATED BY pub_release do not modify.
/// pub_release version
String packageVersion = '3.0.0';

```

Where the packageVersion is set to the value in your pubspec.yaml.

The packageVersion variable provides a convenient method if you need to display the version no. of your package.
