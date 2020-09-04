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
