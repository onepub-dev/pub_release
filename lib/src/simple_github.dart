/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:github/github.dart';

class SimpleGitHub {
  final String username;

  final String apiToken;

  final String owner;

  final String repository;

  late GitHub _github;

  late RepositorySlug _repositorySlug;

  late RepositoriesService _repoService;

  SimpleGitHub(
      {required this.username,
      required this.apiToken,
      required this.owner,
      required this.repository});

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
  Future<Release> release({required String? tagName}) =>
      _release(tagName: tagName);

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
      release =
          await _repoService.createRelease(_repositorySlug, createRelease);
    } else {
      throw GitHubException('A release with tagName $tagName already exists');
    }

    return release;
  }

  Future<Release?> getReleaseByTagName({required String? tagName}) =>
      _getByTagName(tagName: tagName);

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

  Future<void> attachAssetFromFile({
    required Release release,
    required String assetName,
    required String assetPath,
    required String mimeType,
    String? assetLabel,
  }) async {
    final assetData = File(assetPath).readAsBytesSync();

    final installAsset = CreateReleaseAsset(
      name: assetName,
      contentType: mimeType,
      assetData: assetData,
      label: assetLabel,
    );
    await _repoService.uploadReleaseAssets(release, [installAsset]);
  }

  Future<void> deleteRelease(Release release) async {
    await _repoService.deleteRelease(_repositorySlug, release);
  }

  Future<void> deleteTag(String tagName) async {
    await GitService(_github).deleteReference(_repositorySlug, 'tags/$tagName');
  }

  Future<void> listReferences() async {
    final gitService = GitService(_github);
    await gitService
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
