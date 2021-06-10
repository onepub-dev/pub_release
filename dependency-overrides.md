# Dependency overrides

The Dart pubspec.yaml file allows you to add a dependency\_overrides section to during development.

The dependency\_overrides section allows you to specify an alternate location for any package dependency.

This often useful during development if you have an associated package that you are also developing.

The dependency\_override allows your package to use the associated packages code from your local disk rather than from pub.dev.

```text
name: pub_release
version: 3.0.0

dependencies: 
  dcli: ^1.0.0
dependency_overrides: 
  dcli: 
    path: ../dcli
```

In the above example the pub\_release project is dependant on dcli.

As I'm also the developer of dcli I often make changes to dcli to support pub\_release features.

I find it easier to make dcli changes and test them in pub\_release before I publish dcli to pub.dev.

The dependency\_override allows me to work on both code bases simultaneous.

## Publishing

When it comes time to publish my package I need to remove the dependency\_overrides as pub.dev only allows you to have dependencies on other published packages.

pub\_release supports dependency\_overrides by automatically removing them during the release process.

Once the package has been published it restores the original overrides.

## Multi-package releases

The support of dependency\_overrides is particularly important when doing [multi-package releases](simultaneous-releases/) as it is normally to have overrides for each of the related packages.

