// lib/services/drive_service.dart
// Uses Google Sign-In OAuth — one-time login on device, auto-refreshes forever.
//
// IMPORTANT: On Android, google_sign_in auto-detects the OAuth client using
// the app's package name + SHA-1 fingerprint registered on Google Cloud
// Console. Do NOT pass `clientId` here — that parameter is for iOS/Web and
// causes ApiException: 10 (DEVELOPER_ERROR) on Android when misused.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../models/models.dart';

const _folderName = 'LedgerJsons';

// No clientId passed — Android auto-detects via package name + SHA-1
// registered on Google Cloud Console for this OAuth client.
final _googleSignIn = GoogleSignIn(
  scopes: [drive.DriveApi.driveFileScope],
);

class DriveService {
  static DriveService? _instance;
  static DriveService get instance => _instance ??= DriveService._();
  DriveService._();

  drive.DriveApi? _api;
  String? _folderId;

  // ── Auth ─────────────────────────────────────────────────

  Future<bool> trySilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _buildApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DRIVE: silent sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // user cancelled
      await _buildApi();
      return true;
    } catch (e) {
      debugPrint('DRIVE: sign-in failed: $e');
      rethrow; // let UI show the real error instead of swallowing it
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _api = null;
    _folderId = null;
  }

  bool get isSignedIn => _googleSignIn.currentUser != null;
  String? get userEmail => _googleSignIn.currentUser?.email;

  Future<void> _buildApi() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception('Could not get authenticated client');
    _api = drive.DriveApi(client);
  }

  Future<drive.DriveApi> _getApi() async {
    if (_api != null) return _api!;
    final ok = await trySilentSignIn();
    if (!ok) throw Exception('not_signed_in');
    return _api!;
  }

  // ── Folder ────────────────────────────────────────────────

  Future<String> _getFolderId(drive.DriveApi api) async {
    if (_folderId != null) return _folderId!;
    final result = await api.files.list(
      q: "name='$_folderName' "
          "and mimeType='application/vnd.google-apps.folder' "
          "and trashed=false",
      $fields: 'files(id,name)',
    );
    final files = result.files;
    if (files != null && files.isNotEmpty) {
      _folderId = files.first.id!;
      debugPrint('DRIVE: found folder $_folderId');
      return _folderId!;
    }
    final meta = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(meta, $fields: 'id');
    _folderId = created.id!;
    debugPrint('DRIVE: created folder $_folderId');
    return _folderId!;
  }

  Future<String?> _findFile(
      drive.DriveApi api, String folderId, String filename) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and name='$filename' and trashed=false",
      $fields: 'files(id,name)',
    );
    final files = result.files;
    return (files != null && files.isNotEmpty) ? files.first.id : null;
  }

  // ── Download ──────────────────────────────────────────────

  Future<Map<String, dynamic>> _downloadJson(
      drive.DriveApi api, String fileId) async {
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }
    return jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
  }

  // ── Upload ────────────────────────────────────────────────

  Future<void> _uploadJson(drive.DriveApi api, String folderId,
      String filename, Map<String, dynamic> data,
      {String? existingId}) async {
    final bytes  = utf8.encode(jsonEncode(data));
    final stream = Stream.fromIterable([bytes]);
    final media  = drive.Media(stream, bytes.length,
        contentType: 'application/json');
    if (existingId != null) {
      await api.files.update(drive.File(), existingId,
          uploadMedia: media, $fields: 'id');
    } else {
      final meta = drive.File()
        ..name    = filename
        ..parents = [folderId];
      await api.files.create(meta, uploadMedia: media, $fields: 'id');
    }
  }

  // ── Public: fetch all projects ────────────────────────────

  Future<List<Project>> fetchAllProjects() async {
    final api      = await _getApi();
    final folderId = await _getFolderId(api);

    final result = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      $fields: 'files(id,name,modifiedTime)',
      orderBy: 'name',
    );

    final files = (result.files ?? [])
        .where((f) => (f.name ?? '').endsWith('.json'))
        .toList();

    debugPrint('DRIVE: found ${files.length} .json files');

    final projects = <Project>[];
    for (final file in files) {
      try {
        final data = await _downloadJson(api, file.id!);
        final slug = (file.name ?? 'unknown').replaceAll('.json', '');
        projects.add(Project.fromJson(slug, data));
        debugPrint('DRIVE: loaded ${file.name}');
      } catch (e) {
        debugPrint('DRIVE: failed to load ${file.name}: $e');
      }
    }

    projects.sort((a, b) => a.created.compareTo(b.created));
    return projects;
  }

  // ── Public: push one project ──────────────────────────────

  Future<void> pushProject(Project project) async {
    final api      = await _getApi();
    final folderId = await _getFolderId(api);
    final filename = '${project.slug}.json';
    final existing = await _findFile(api, folderId, filename);
    await _uploadJson(api, folderId, filename, project.toJson(),
        existingId: existing);
    debugPrint('DRIVE: pushed ${project.slug}');
  }

  void reset() {
    _api      = null;
    _folderId = null;
  }
}
