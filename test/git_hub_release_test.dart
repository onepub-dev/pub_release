import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:github/github.dart';

void main() {
  //var github = GitHub(auth: findAuthenticationFromEnvironment());
  var github = GitHub(
      auth: Authentication.basic(
          'bsutton', '5f835aabb17cef7f21ef7ec88cd40e093004bf1d'));

  var dcliSlug = RepositorySlug('bsutton', 'dcli');
  // var repo = waitForEx<Repository>(github.repositories.getRepository());

  //var release = CreateRelease(tagName: '1.0.0', name: 'dcli', );
  var tagName = '1.0.3.${Platform.operatingSystem}';
  var createRelease = CreateRelease(tagName);

  'dcli compile -o $HOME/git/dcli/bin/dcli_install.dart'.run;

  var repoService = RepositoriesService(github);
  var release = waitForEx(repoService.getReleaseByTagName(dcliSlug, tagName));
  if (release == null) {
    print('creating release');
    release = waitForEx<Release>(
        repoService.createRelease(dcliSlug, createRelease));
  } else {
    print('release already exists');
  }
  print('sending binary');

  var assetData = File('$HOME/git/dcli/bin/dcli_install').readAsBytesSync();

  var installAsset = CreateReleaseAsset(
    name: 'dcli_install',
    contentType: 'application/vnd.microsoft.portable-executable',
    assetData: assetData,
    label: 'DCli installer',
  );
  waitForEx(repoService.uploadReleaseAssets(release, [installAsset]));
  print('send complee');
}
