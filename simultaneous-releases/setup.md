# Setup

To run a simultaneous release you need to provide a `pubrelease.multi.yaml` configuration file that describes each of the packages that need to be released.

The `pubrelease.multi.yaml` configuration file will normally be located in the `tool` directory of the main project but can be in any of the package `tool` directories.

The `pubrelease.multi.yaml` configuration file simply lists each of the related packages and their relative paths.

{% hint style="warning" %}
The order of the packages is important.
{% endhint %}

It is important that you place each package in the correct order for the release process to run successfully.

You should place the outermost packages first.

For example if you have the following pubspec.yaml files:

```text
name: conduit
dependencies:
  conduit_orm: ^1.0.0
  conduit_common: ^1.0.0
```

```text
name: conduit_orm
dependencies:
  conduit_common: ^1.0.0
```

```text
name: conduit_common
```

In the above examples `conduit_common` is the 'outermost' package and you should therefore order you packages as follows:

```yaml
conduit_common: ../common
conduit_orm: ../orm
conduit: .
```

The above ordering will cause Pub Release to release packages in the following order:

* conduit\_common
* conduit\_orm
* conduit

The paths for each package must be relative to the project that contains the `pubrelease.multi.yaml` file.

Don't forget to add `pubrelease_multi.yaml` to git.

To test you configuration run:

```dart
pub_release multi --dry-run
```

