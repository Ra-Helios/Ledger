// lib/services/drive_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import '../models/models.dart';

// Editor scope — needed for push
const _scopes = [drive.DriveApi.driveFileScope];
const _folderName = 'LedgerJsons';

class DriveService {
  static DriveService? _instance;
  static DriveService get instance => _instance ??= DriveService._();
  DriveService._();

  drive.DriveApi? _api;
  String? _folderId;

  // ── Auth ─────────────────────────────────────────────────

  Future<drive.DriveApi> _getApi() async {
    if (_api != null) return _api!;
    final keyJson =
        await rootBundle.loadString('assets/service_account.json');
    final keyData = jsonDecode(keyJson) as Map<String, dynamic>;
    final credentials = ServiceAccountCredentials.fromJson(keyData);
    final client = await clientViaServiceAccount(credentials, _scopes);
    _api = drive.DriveApi(client);
    return _api!;
  }

  // ── Folder ────────────────────────────────────────────────

  Future<String> _getFolderId(drive.DriveApi api) async {
    if (_folderId != null) return _folderId!;
    final result = await api.files.list(
      q: "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      $fields: 'files(id,name)',
    );
    final files = result.files;
    if (files != null && files.isNotEmpty) {
      _folderId = files.first.id!;
      return _folderId!;
    }
    // Create it
    final meta = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(meta, $fields: 'id');
    _folderId = created.id!;
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
    final bytes = utf8.encode(jsonEncode(data));
    final stream = Stream.fromIterable([bytes]);
    final media = drive.Media(stream, bytes.length,
        contentType: 'application/json');
    if (existingId != null) {
      await api.files.update(drive.File(), existingId,
          uploadMedia: media, $fields: 'id');
    } else {
      final meta = drive.File()
        ..name = filename
        ..parents = [folderId];
      await api.files.create(meta, uploadMedia: media, $fields: 'id');
    }
  }

  // ── Public: fetch all projects ────────────────────────────

  Future<List<Project>> fetchAllProjects() async {
    final api = await _getApi();
    final folderId = await _getFolderId(api);
    final result = await api.files.list(
      q: "'$folderId' in parents and trashed=false and mimeType='application/json'",
      $fields: 'files(id,name,modifiedTime)',
      orderBy: 'name',
    );
    final files = result.files ?? [];
    final projects = <Project>[];
    for (final file in files) {
      try {
        final data = await _downloadJson(api, file.id!);
        final slug = (file.name ?? 'unknown').replaceAll('.json', '');
        projects.add(Project.fromJson(slug, data));
      } catch (_) {}
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
  }

  void reset() {
    _api = null;
    _folderId = null;
  }
}
