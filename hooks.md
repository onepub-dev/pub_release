# Hooks

Pub Release supports the concept of pre and post release hooks.

A hook is simply a script that is run before or after the release is pushed to pub.dev.

Hooks live in the following directories:

* `<project root>`/tool/pre\_release\_hook
* `<project root>`/tool/post\_release\_hook

Where the `project root` is the directory where your pubspec.yaml lives.

You can include any number of scripts in each of these directories and they will be run in alphabetical order.

When your hook is called it will be passed the new version as a cli argument:

```bash
my_hook.dart 1.0.0
```

### dry-run

If the `--dry-run` flag is passed to the `pub_release` command then a `--dry-run` flag will be passed on the command line to the hook.

If the `--dry-run` flag is passed than your hook should suppress any actions that permanently modify the project.

```bash
my_hook.dart --dry-run 1.0.0
```

