/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:github/github.dart';

class SimpleGitHub {
  SimpleGitHub(
      {required this.username,
      required this.apiToken,
      required this.owner,
      required this.repository});
  final String username;
  final String apiToken;
  final String owner;
  final String repository;

  late GitHub _github;

  late RepositorySlug _repositorySlug;

  late RepositoriesService _repoService;

  void auth() {
    //var github = GitHub(auth: findAuthenticationFromEnvironment());
    _github = GitHub(auth: Authentication.basic(username, apiToken));

    _repositorySlug = RepositorySlug(owner, repository);

    _repoService = RepositoriesService(_github);
  }

  /// You must call this once you have finished to close the connection
  /// to git hub.

  void dispose() {
    _github.dispose();
  }

  ///
  /// Creates a git hub release and returns the created release.
  ///
  /// Throws a GitHubException if the given tagName already exists.
  Release release({required String? tagName}) =>
      // ignore: discarded_futures
      waitForEx(_release(tagName: tagName));

  /// Throws a GitHubException if the given tagName already exists.
  Future<Release> _release({required String? tagName}) async {
    final createRelease = CreateRelease(tagName);

    Release? release;
    try {
      Settings().verbose('search for $tagName of $_repositorySlug');
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

  Release? getReleaseByTagName({required String? tagName}) =>
      // ignore: discarded_futures
      waitForEx(_getByTagName(tagName: tagName));

  Future<Release?> _getByTagName({required String? tagName}) async {
    Release? release;
    try {
      Settings().verbose('search for $tagName of $_repositorySlug');
      release =
          await _repoService.getReleaseByTagName(_repositorySlug, tagName);
    } on ReleaseNotFound catch (_) {
      // no op - we return null
      print('ReleaseNotFound');
    }

    return release;
  }

  void attachAssetFromFile({
    required Release release,
    required String assetName,
    required String assetPath,
    required String mimeType,
    String? assetLabel,
  }) {
    final assetData = File(assetPath).readAsBytesSync();

    final installAsset = CreateReleaseAsset(
      name: assetName,
      contentType: mimeType,
      assetData: assetData,
      label: assetLabel,
    );
    // ignore: discarded_futures
    waitForEx(_repoService.uploadReleaseAssets(release, [installAsset]));
  }

  void deleteRelease(Release release) {
    // ignore: discarded_futures
    waitForEx(_repoService.deleteRelease(_repositorySlug, release));
  }

  void deleteTag(String tagName) {
    final gitService = GitService(_github);
    // ignore: discarded_futures
    waitForEx(gitService.deleteReference(_repositorySlug, 'tags/$tagName'));
  }

  void listReferences() {
    final gitService = GitService(_github);
    waitForEx<void>(gitService
        .listReferences(_repositorySlug, type: 'tags')
        // ignore: discarded_futures
        .forEach((ref) => print(ref.ref)));
  }
}

class GitHubException implements Exception {
  GitHubException(this.message);
  String message;

  @override
  String toString() => message;
}
