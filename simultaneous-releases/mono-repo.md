# Mono Repo

With related packages we recommend that you use a git mono repo.

This ensures consistent naming and paths between between the related packages.

### Pubspec.yaml - dependency\_overrides

Within your mono repo we recommend that you commit you pubspec.yaml with a dependency\_overrides section listing the relative paths of each of the dependant packages.

```text
name: conduit
dependencies:
  conduit_orm: ^1.0.0
  conduit_common: ^1.0.0

dependency_overrides:
  conduit_orm:
    path: ../orm
  conduit_common:
    path: ../common
```

The dependency overrides ensures that when anyone clones your project the code will work correctly out of the box.

Of course pub.dev will not let you publish a package with a path based dependency override.

Pub Release manages your dependency overrides and will temporarily remove them during the release process so your packages can be published.

You can also switch between the two modes using  

`pub_release override` 

`pub_release override remove`

