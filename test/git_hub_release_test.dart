import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:github/github.dart';

void main() {
  //var github = GitHub(auth: findAuthenticationFromEnvironment());
  var github = GitHub(
      auth: Authentication.basic(
          'bsutton', '5f835aabb17cef7f21ef7ec88cd40e093004bf1d'));

  var dshellSlug = RepositorySlug('bsutton', 'dshell');
  // var repo = waitForEx<Repository>(github.repositories.getRepository());

  //var release = CreateRelease(tagName: '1.0.0', name: 'dshell', );
  var tagName = '1.0.3.${Platform.operatingSystem}';
  var createRelease = CreateRelease(tagName);

  'dshell compile -o $HOME/git/dshell/bin/dshell_install.dart'.run;

  var repoService = RepositoriesService(github);
  var release = waitForEx(repoService.getReleaseByTagName(dshellSlug, tagName));
  if (release == null) {
    print('creating release');
    release = waitForEx<Release>(
        repoService.createRelease(dshellSlug, createRelease));
  } else {
    print('release already exists');
  }
  print('sending binary');

  var assetData = File('$HOME/git/dshell/bin/dshell_install').readAsBytesSync();

  var installAsset = CreateReleaseAsset(
    name: 'dshell_install',
    contentType: 'application/vnd.microsoft.portable-executable',
    assetData: assetData,
    label: 'DShell installer',
  );
  waitForEx(repoService.uploadReleaseAssets(release, [installAsset]));
  print('send complee');
}
