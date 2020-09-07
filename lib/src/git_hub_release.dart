//import 'dart:io';

//import 'package:dcli/dcli.dart';
// import 'package:github/github.dart';
//import 'package:meta/meta.dart';

class GitHubRelease {
  // final String username;
  // final String apiToken;
  // final String owner;
  // final String repository;

  // GitHub _github;

  // RepositorySlug _repositorySlug;

  // RepositoriesService _repoService;

  // GitHubRelease(
  //     {@required this.username,
  //     @required this.apiToken,
  //     @required this.owner,
  //     @required this.repository});

  // void auth() {
  //   //var github = GitHub(auth: findAuthenticationFromEnvironment());
  //   _github = GitHub(auth: Authentication.basic(username, apiToken));

  //   _repositorySlug = RepositorySlug(owner, repository);

  //   _repoService = RepositoriesService(_github);
  // }

  // ///
  // /// Creates a git hub release and returns the created release.
  // ///
  // /// Throws a GitHubException if the given tagName already exists.
  // Release release({@required String tagName}) {
  //   var createRelease = CreateRelease(tagName);

  //   var release =
  //       waitForEx(_repoService.getReleaseByTagName(_repositorySlug, tagName));
  //   if (release == null) {
  //     release = waitForEx<Release>(
  //         _repoService.createRelease(_repositorySlug, createRelease));
  //   } else {
  //     throw GitHubException('A release with tagName $tagName already exists');
  //   }

  //   return release;
  // }

  // Release getByTagName({@required String tagName}) {
  //   return waitForEx(
  //       _repoService.getReleaseByTagName(_repositorySlug, tagName));
  // }

  // void attachAssetFromFile(
  //     {Release release,
  //     String assetName,
  //     String assetLabel,
  //     String assetPath,
  //     String mimeType}) {
  //   var assetData = File(assetPath).readAsBytesSync();

  //   var installAsset = CreateReleaseAsset(
  //     name: assetName,
  //     contentType: mimeType,
  //     assetData: assetData,
  //     label: assetLabel,
  //   );
  //   waitForEx(_repoService.uploadReleaseAssets(release, [installAsset]));
  // }

  // void deleteRelease(Release release) {
  //   waitForEx(_repoService.deleteRelease(_repositorySlug, release));
  // }
}

class GitHubException implements Exception {
  String message;

  GitHubException(this.message);

  @override
  String toString() => message;
}
