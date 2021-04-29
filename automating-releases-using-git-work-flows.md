# Automating releases using Git work flows

You can automate the creation of git release tags from a github workflow via:

* github\_workflow\_release

```text
name: Release executables for Linux

on:
  push:
#    tags:
#      - '*'

jobs:
  build:
    runs-on: ubuntu-latest

    container:
      image:  google/dart:latest

    steps:
    - uses: actions/checkout@v2

    - name: setup paths
      run: export PATH="${PATH}":/usr/lib/dart/bin:"${HOME}/.pub-cache/bin"

    - name: install pub_release
      run: pub global activate pub_release
    - name: Create release
      env:
        APITOKEN:  ${{ secrets.APITOKEN }}
      run: github_workflow_release --username <user> --apiToken "$APITOKEN" --owner <owner> --repository <repo>
```

You need to update the `<user>`, `<owner>` and `<repo>` with the appropriate github values.

You also need to add you personal api token as a secret in github

[https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)

