import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

class SimpleGitHub {
  final String username;
  final String apiToken;
  final String owner;
  final String repository;

  GitHub _github;

  RepositorySlug _repositorySlug;

  RepositoriesService _repoService;

  SimpleGitHub(
      {@required this.username,
      @required this.apiToken,
      @required this.owner,
      @required this.repository});

  void auth() {
    //var github = GitHub(auth: findAuthenticationFromEnvironment());
    _github = GitHub(auth: Authentication.basic(username, apiToken));

    _repositorySlug = RepositorySlug(owner, repository);

    _repoService = RepositoriesService(_github);
  }

  ///
  /// Creates a git hub release and returns the created release.
  ///
  /// Throws a GitHubException if the given tagName already exists.
  Future<Release> release({@required String tagName}) async {
    final createRelease = CreateRelease(tagName);

    Release release;
    try {
      release =
          await _repoService.getReleaseByTagName(_repositorySlug, tagName);
    } on ReleaseNotFound catch (_) {}

    if (release == null) {
      release = waitForEx<Release>(
          _repoService.createRelease(_repositorySlug, createRelease));
    } else {
      throw GitHubException('A release with tagName $tagName already exists');
    }

    return release;
  }

  Future<Release> getByTagName({@required String tagName}) async {
    Release release;
    try {
      release =
          await _repoService.getReleaseByTagName(_repositorySlug, tagName);
    } on ReleaseNotFound catch (_) {
      // no opp
    }
    return release;
  }

  void attachAssetFromFile(
      {Release release,
      String assetName,
      String assetLabel,
      String assetPath,
      String mimeType}) {
    final assetData = File(assetPath).readAsBytesSync();

    final installAsset = CreateReleaseAsset(
      name: assetName,
      contentType: mimeType,
      assetData: assetData,
      label: assetLabel,
    );
    waitForEx(_repoService.uploadReleaseAssets(release, [installAsset]));
  }

  void deleteRelease(Release release) {
    waitForEx(_repoService.deleteRelease(_repositorySlug, release));
  }

  void deleteTag(String tagName) {
    final gitService = GitService(_github);
    gitService.deleteReference(_repositorySlug, 'tag/$tagName');
  }

  void listReferences() {
    final gitService = GitService(_github);
    gitService
        .listReferences(_repositorySlug, type: 'tags')
        .forEach((ref) => print(ref.ref));
  }
}

class GitHubException implements Exception {
  String message;

  GitHubException(this.message);

  @override
  String toString() => message;
}
