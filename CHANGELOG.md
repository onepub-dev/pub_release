# 4.0.1
Updated dcli version to 0.40.0

# 4.0.0
Removed getPubSpec. You should use findPubspec followed by Pubspec.fromFile

# 3.0.0
removed the --suffix option as we were mis-using it.
We had been using the suffix to indicate os version but github sees it as a 'pre-release' indicator.
Going forward the assests should all be attached to a single release and the asset names should indicate the platform.
Fixed bugs around the recreation of the 'latests' tag
Fixed bug where we were not closing the http connection.

# 2.1.20
implemented the lint package.
Fixed a bug which caused no hooks to be returned.

# 2.1.19
Fixed hook messages.
Fixed bugs in the git detection and push of tags.
exposed Git as part of the public api.

# 2.1.18
Fixed a bug where pub_release only search the dart package root for .git. The dart package could be part of a larger project in which case we need to search up the tree for .git.

# 2.1.17
tweaks to the release process.
# 2.1.16
Added new addAsset method to make it easy to publish an asset.

# 2.1.15
added note about hook scripts.
upgraded package versions and added example.md.

# 2.1.14
pub updated.
improved the doco on automating git releases.

# 2.1.13
reduced min dart sdk to 2.7 so would work on a pi.

# 2.1.12
upgraded to dcli 0.34.0

# 2.1.11
corrected the filename for settings.

# 2.1.10
ignored settings.yaml and add tool directory.
moved credentials into settings.yaml.

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
changed hooks to hook to conform to dart policy of singular form for directory names. 
Made the suffix optional. 
Improved the readme to include instructions on creating release tags in github.

# 2.1.1
Used 2.1.0 to create a release so that it generates the github release tag an assets.

# 2.1.0
pub_relase can no create a release in github and add each exectable listed in the pubspec.yaml as an asset attached
to the release.
update workflow notes.
Added back in the assest/release tag as github.dart is almost ready.
Upgraded to dcli 0.27

# 2.0.2
exported pub_semver so users have access to the Version class.

# 2.0.1
Small fix as it was displaying the old version no.rather than the new one.

# 2.0.0
Cleaned up the Version api.
Added pedeantic.

# 1.1.4
upgraded to dcli 0.24

# 1.1.3
added the dart static analyzer to the set of tasks performed.
cleaned up the github_release and workflow apps. Renamed them and added additional doc and examples of their usage.
color coded hook messages.
The git_release exec has been disabled until we get the new version of github.dart.

# 1.1.2
color coded hook messages.
upgraded to dcli.

# 1.1.1
Fixed a bug where the pre-release hook path was buggered up.
Fixed a message.
ignored credentials.
Fix git_release and create_tag so they will work from the root dir of any project.
Widened the dcli version constraints as required by pub.dev

# 1.1.0
Added support for pre/post release hooks.
stand alone cli app to create a git hub tag.
Added settings_yaml dependancy as no longer part of dcli.

# 1.0.13
upgraded to dcli.
Added new exe git_release which creates a git release tag and attaches each executable as an asset.

# 1.0.12
made git_hub a dev dependency.

# 1.0.11
Upgraded to dshell 1.11.0 and fixed breaking changes.

# 1.0.10
Added missing space in message.


# 1.0.9
upgraded packages.
Fixed bug where when selecting a custom version no. we would ask for the version twice.

# 1.0.8
no longer asking a user to create the git tag.

# 1.0.7
moved the option to keep the current version down the list as it is rarely used.
released 1.0.6

# 1.0.6
Was displaying the old version when asking the usr to confirm the version.
ignored bash history.
Added option to set the version and ask no questions.

# 1.0.5

# 1.0.5

# 1.0.5

# 1.0.5

# 1.0.5
Add option to set the version no. from the cli

# 1.0.4
removed the version message as it was just confusing when you are looking to update the actual packages version.
Added a git pull at the start of the process.

# 1.0.3
Added version to start. Had the exists logic backwards when creating a CHANGLOG.md

# 1.0.2
we now create the CHANGELOG.md file if it doesn't exist.

# 1.0.1
Fixed a bug when detecting git. Change message to only recommend commiting as we will do the push.

# 1.0.0
Fixed a bug where it failed to detect that git was being used.
Fixed a bug where it throws an error if a tag doesn't already exist.

# 0.1.4
released 0.1.4
Release of version 0.1.3
Update .gitignore
Merge pull request #1 from bsutton/add-license-1
Create LICENSE
initial commit

# 0.1.4
Fixed the change log :)
Added new option to keep the current version.
# 0.1.2

Added a new option to keep the current version.
# 0.1.1
Added a missing 'executeables' statement from pubspec.yaml
# 0.1.0

First release of pub_release

# 0.1.0

First release of pub_release
### 0.1.1
### 0.1.0
My first release
### 0.1.0
My first release.
## 1.0.0

- Initial version, created by Stagehand
