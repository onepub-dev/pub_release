# 11.1.0
- upgraded to dcli 6.0

# 11.0.0
- upgraded to the latest version of dcli.

# 10.1.2
- Added an exception handler in main for PubReleaseExceptions so we print the error rather than dumping a stack trace.
- no activates specific version after doing a release.

# 10.1.0
- upgraded package deps.

# 10.0.10
- upgraded to release version of pubspec_manager.

# 10.0.8
- upgraded to the latests pubspec_manager to fix a bug
 in the executable iterator.

# 10.0.6
- upgraded to latest version of pubspec_manager to fix a bug
when updating dependencies.
- upgraded to dcli 4.x

# 10.0.3
- upgraded to latest version of dcli and settings_yaml (again)

# 10.0.2
- upgraded to latest settings_yaml and dcli.
- Update README.md
- removed .pubrelease.yaml from git as it contains secrets.

# 10.0.1
- Fixed a bug in the code that looks for the .pubrelease.yaml file.
- moved our own settings yaml into correct path.

# 10.0.0
- Breaking the tool/post_rlease_hook/setttings.yaml has moved to tool/.pubrelease.yaml and 
  now contains addtional settings. The format is the same so you can just copy the exiting file and
  to the tool directory and rename it to .pubrelease.yaml
# 9.3.0
- migrated to pubspec_manager

# 9.1.0
- revert to using pubspec to get around a problem in pubspec2
- upgraded dcli version

# 9.0.2
- upgraded to dcli 3.x and settings_yaml 7.x

# 9.0.1
upgraded to settings_yaml 6.0

# 9.0.0
- dart 3.x compatability
# 9.0.0-beta.1
- beta version for Dart 3.x compatability

# 8.2.1
- Change the order of the version menu so the option 'keep current' is always the first option. In this way the two most common options are in fixed positions.

# 8.2.0
- upgraded dependencies.

# 8.1.0
- upgraded package dependencies to latest compatible versions.
# 8.0.3
- removed version.g.dart from the barrel file as it was polluting the name space of other dcli apps that use the pub_release api and have their own dcli version.

# 8.0.1
-  Upgraded to dcli 1.33.0 and pubspec2 2.4.1 to fix a bug where we were clearing out the executable script name in the pubspec.yaml.
- spelling.

# 8.0.0
- upgraded dependencies and sdk requirements to at least 2.17.
- We now check for a pubrelease.multi.yaml and if it exists we expect the user to pass the multi command or the --no-multi switch.
- Added --no-multi flag to suppress doing a multi build. 
- upgraded to the latest pubspec package to fix a problem with platforms being written out with a null value.

# 7.3.3
- Upgraded to pubspec 2.3.0 to fix a problem with platforms. The pubspec code was incorrectly
adding a 'null' after the platform name so 'linx:' became 'linux: null'

# 7.3.0
Fixed a bug in the dependency version updates for the multi command. 
It was scaning from the wrong root dir for deps. We now use the multi settings file to guide the update process.

# 7.2.2
- added support for updating the dependency version no. when doing a multi release
# 7.2.0
- ENH: added support for pre-release versioning.

# 7.1.19
- spelling.

# 7.1.18
- Applied lint_hard
- Added documentation key to pubspec.yaml. lint cleanups.
- corrected github_release to use the same settings file settings.yaml.

# 7.1.17
- fixed some deprecation warnings.
- Fixed a bug on first run if a changelog.md file didn't already exists. We now created it.

# 7.1.8
upgraded to dcli 1.5.3
changed hooks to explicity run dart for .dart hooks until we resolve dcli problems with the dart file association under windows.

# 7.1.7
upgraded to dcli 1.5.2
remove the units tests dependency on having dcli installed.
Moved to new version of settings.yaml to fix bugs with empty content.

# 7.1.6
Missed on of the invalid array refernces.

# 7.1.5
Added overrides back in.
upgraded to dcli 1.5.2
Fixed a bug in the git procelain parsing.

# 7.1.4
Added  logic to ignore pre and post hooks which are not compatible with the current platform. e.g. .sh scripts on windows

# 7.1.3
update the dcli version no. as we had left it too wide.
We now run critical test with verbose logging if pub_release was called with the verbose flag.

# 7.1.2
Exported the multisettings class as part of the public api so the list of depdencis can be shared by others.

# 7.1.1
- change DartScript.current to self as current is now deprecated.
- Added logic to suppress the running of critical_test if no test directory exits.
- Fixed a bug where we crash if the .gitignore file doesn't exist.
- modified to use dart pub as pub is going away.
- Add getting started to readme and link to docs

# 7.1.0
New Features:
- Added option to suppress git operations --no-git

Fixes:
- Added logic to suppress `dart format` if a directory is non existant or empty.


# 7.0.0
First working version of multi.

Now supports running unit tests as part of the release process via critical_test.

Changed exit codes from -1 to 1 as this seems more standard.

# 6.4.0

Added --dry-run flag.

# 6.3.0

upgraded to dcli 1.0

# 6.2.0

Change the change log editing so that the user gets to see the enitre change log. This is particullarly useful if a release fails an you want to re-edit the release notes. Currently we just append the release notes a second time which is not desirable.

# 6.1.0

Released 6.1.0 improvement to log messags. Fixed incorrect line argument to dart format. Added missing logic for line length.

# 6.1.0

improvement to log messags. Fixed incorrect line argument to dart format. Added missing logic for line length.

# 6.1.0

Added list of extensions to ignore if found in the hook directory. Now allows any type of executable to be used as a hook. Prints an error if invalid command line arguments are passed. Added missig implementation for controlling the formatters line length.

# 6.0.2

upgraded final libraries to nndb versions. upgraded to latest version of dcli

# 6.0.1

Upgraded to latest dcli.

# 6.0.0

Upgraded to nnbd.

# 5.0.7

fixed string formatting problem in formatCode Added logic to commit formatted fils. formatting. We commit any files changed by dartfmt.

# 5.0.4

Cleaned up name/version on startup

# 5.0.3

pub\_relesae was printing the wrong app name on start up.

# 5.0.2

Fixed release names.

# 5.0.1

fixed latest release name.

# 5.0.1

Changed the 'latest' naming convention from 'latest-' to 'latest.' as git hub saw the '-' as meaning the tag was a pre-release. Now prints version no. when starting.

# 5.0.0

Changed code to force the user to commit before doing a release. This allows us to automatically push the committed version changes. Without this the assets attached to git hub have the old version no. Staged the files we modified so we can commit them. quoted the message so it survies arg parsing.

# 4.3.1

Fixed a bug in the deleteTag method as it was using the wrong path to the tags. renamed getByTagname to getReleaseByTagname This bug was causing the 'latest' tag to not be updated. removed sperious } in string. released 4.3.0 formatting

# 4.3.0

We can once again upload assets as part of a release. Fixed a bug where the mimetype was set to null. The result was a crash in the http\_impl class.

Additional verbose messages. Fixed a bug under windows where we appended .exe.exe to the mimeType.

# 4.2.0

Reverted back to dart 2.8.4 to over come [https://github.com/dart-lang/sdk/issues/44578](https://github.com/dart-lang/sdk/issues/44578)

# 4.1.0

Added back in logic to release assets as it now seems to be working? upgraded to latests dcli which has a changed method signature. Now pulling credentials from settings.yaml upgraded to latest dcli version. restored test code to working state. renamed to simple\_github.dart

# 4.0.4

moved from using pub to dart pub.

# 4.0.3

Added hook to active lastest version of pub release locally after we do a release. removed message re attaching assets as we are not currently doing that.

# 4.0.2

Removed ability to add executablles as assets to git release until issue [https://github.com/dart-lang/sdk/issues/44578](https://github.com/dart-lang/sdk/issues/44578) is fixed.

# 4.0.1

Updated dcli version to 0.40.0

# 4.0.0

Removed getPubSpec. You should use findPubspec followed by Pubspec.fromFile

# 3.0.0

removed the --suffix option as we were mis-using it. We had been using the suffix to indicate os version but github sees it as a 'pre-release' indicator. Going forward the assests should all be attached to a single release and the asset names should indicate the platform. Fixed bugs around the recreation of the 'latests' tag Fixed bug where we were not closing the http connection.

# 2.1.20

implemented the lint package. Fixed a bug which caused no hooks to be returned.

# 2.1.19

Fixed hook messages. Fixed bugs in the git detection and push of tags. exposed Git as part of the public api.

# 2.1.18

Fixed a bug where pub\_release only search the dart package root for .git. The dart package could be part of a larger project in which case we need to search up the tree for .git.

# 2.1.17

tweaks to the release process.

# 2.1.16

Added new addAsset method to make it easy to publish an asset.

# 2.1.15

added note about hook scripts. upgraded package versions and added example.md.

# 2.1.14

pub updated. improved the doco on automating git releases.

# 2.1.13

reduced min dart sdk to 2.7 so would work on a pi.

# 2.1.12

upgraded to dcli 0.34.0

# 2.1.11

corrected the filename for settings.

# 2.1.10

ignored settings.yaml and add tool directory. moved credentials into settings.yaml.

# 2.1.9

upgraded to dcli 0.33.6

# 2.1.8

upgraded to dcli 0.32.0

# 2.1.7

upgraded to dcli 0.30.0

# 2.1.6

Upgraded to dcli 0.29.2

# 2.1.5

upgraded to dcli 0.28.0

# 2.1.4

FIX: a bug was causing the code to fail to update the latest release. We are now explicitly deleting the tag and then recreating it.

# 2.1.3

Final test of release hooks. No code changes.

# 2.1.2

changed hooks to hook to conform to dart policy of singular form for directory names. Made the suffix optional. Improved the readme to include instructions on creating release tags in github.

# 2.1.1

Used 2.1.0 to create a release so that it generates the github release tag an assets.

# 2.1.0

pub\_relase can no create a release in github and add each exectable listed in the pubspec.yaml as an asset attached to the release. update workflow notes. Added back in the assest/release tag as github.dart is almost ready. Upgraded to dcli 0.27

# 2.0.2

exported pub\_semver so users have access to the Version class.

# 2.0.1

Small fix as it was displaying the old version no.rather than the new one.

# 2.0.0

Cleaned up the Version api. Added pedeantic.

# 1.1.4

upgraded to dcli 0.24

# 1.1.3

added the dart static analyzer to the set of tasks performed. cleaned up the github\_release and workflow apps. Renamed them and added additional doc and examples of their usage. color coded hook messages. The git\_release exec has been disabled until we get the new version of github.dart.

# 1.1.2

color coded hook messages. upgraded to dcli.

# 1.1.1

Fixed a bug where the pre-release hook path was buggered up. Fixed a message. ignored credentials. Fix git\_release and create\_tag so they will work from the root dir of any project. Widened the dcli version constraints as required by pub.dev

# 1.1.0

Added support for pre/post release hooks. stand alone cli app to create a git hub tag. Added settings\_yaml dependancy as no longer part of dcli.

# 1.0.13

upgraded to dcli. Added new exe git\_release which creates a git release tag and attaches each executable as an asset.

# 1.0.12

made git\_hub a dev dependency.

# 1.0.11

Upgraded to dshell 1.11.0 and fixed breaking changes.

# 1.0.10

Added missing space in message.

# 1.0.9

upgraded packages. Fixed bug where when selecting a custom version no. we would ask for the version twice.

# 1.0.8

no longer asking a user to create the git tag.

# 1.0.7

moved the option to keep the current version down the list as it is rarely used. released 1.0.6

# 1.0.6

Was displaying the old version when asking the usr to confirm the version. ignored bash history. Added option to set the version and ask no questions.

# 1.0.5

# 1.0.5

# 1.0.5

# 1.0.5

# 1.0.5

Add option to set the version no. from the cli

# 1.0.4

removed the version message as it was just confusing when you are looking to update the actual packages version. Added a git pull at the start of the process.

# 1.0.3

Added version to start. Had the exists logic backwards when creating a CHANGLOG.md

# 1.0.2

we now create the CHANGELOG.md file if it doesn't exist.

# 1.0.1

Fixed a bug when detecting git. Change message to only recommend commiting as we will do the push.

# 1.0.0

Fixed a bug where it failed to detect that git was being used. Fixed a bug where it throws an error if a tag doesn't already exist.

# 0.1.4

released 0.1.4 Release of version 0.1.3 Update .gitignore Merge pull request \#1 from bsutton/add-license-1 Create LICENSE initial commit

# 0.1.4

Fixed the change log :\) Added new option to keep the current version.

# 0.1.2

Added a new option to keep the current version.

# 0.1.1

Added a missing 'executeables' statement from pubspec.yaml

# 0.1.0

First release of pub\_release

# 0.1.0

First release of pub\_release

## 0.1.1

## 0.1.0

My first release

## 0.1.0

My first release.

## 1.0.0

* Initial version, created by Stagehand

