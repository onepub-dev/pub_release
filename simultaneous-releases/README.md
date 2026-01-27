# Multi-package Releases

If you have a project that consists of multiple related Dart packages then you may want to perform simultaneous releases of all of the related packages.

The Pub Release `multi` command automates simultaneous releases.

{% hint style="info" %}
For simultaneous releases we recommend using github mono repos to ensure a consistent  directory structure as relative paths are used to reference related dependencies.
{% endhint %}

## How it works

* Uses `tool/pubrelease.multi.yaml` to discover related packages.
* Aligns all package versions to the same release number.
* Applies temporary `pubspec_overrides.yaml` files so local path dependencies
  resolve during the release.

## Release notes

During a multi release, the first package that generates a changelog entry will
have its release notes propagated to other packages unless they already contain
notes for that version.




