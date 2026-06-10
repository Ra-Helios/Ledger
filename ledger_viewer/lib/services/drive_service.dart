// lib/services/drive_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

const _scopes = [drive.DriveApi.driveReadonlyScope];
const _folderName = 'LedgerJsons';

class DriveService {
  static DriveService? _instance;
  static DriveService get instance => _instance ??= DriveService._();
  DriveService._();

  drive.DriveApi? _api;

  // ── Auth ─────────────────────────────────────────────────

  Future<drive.DriveApi> _getApi() async {
    if (_api != null) return _api!;

    final keyJson = await rootBundle.loadString('assets/service_account.json');
    final keyData = jsonDecode(keyJson) as Map<String, dynamic>;

    final credentials = ServiceAccountCredentials.fromJson(keyData);
    final client = await clientViaServiceAccount(credentials, _scopes);
    _api = drive.DriveApi(client);
    return _api!;
  }

  // ── Find LedgerJsons folder ───────────────────────────────

  Future<String?> _getFolderId(drive.DriveApi api) async {
    final result = await api.files.list(
      q: "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      $fields: 'files(id,name)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  // ── List all .json files in the folder ───────────────────

  Future<List<drive.File>> _listProjectFiles(drive.DriveApi api, String folderId) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and trashed=false and mimeType='application/json'",
      $fields: 'files(id,name,modifiedTime)',
      orderBy: 'name',
    );
    return result.files ?? [];
  }

  // ── Download a single file ────────────────────────────────

  Future<Map<String, dynamic>> _downloadJson(drive.DriveApi api, String fileId) async {
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }

    final jsonStr = utf8.decode(chunks); // explicit utf-8 — handles emojis safely
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  // ── Public: fetch all projects ────────────────────────────

  Future<List<Project>> fetchAllProjects() async {
    final api = await _getApi();
    final folderId = await _getFolderId(api);

    if (folderId == null) {
      throw Exception(
        'LedgerJsons folder not found on Drive.\n'
        'Make sure you have shared it with the service account.',
      );
    }

    final files = await _listProjectFiles(api, folderId);

    if (files.isEmpty) {
      return [];
    }

    final projects = <Project>[];
    for (final file in files) {
      try {
        final data = await _downloadJson(api, file.id!);
        // derive slug from filename (strip .json)
        final slug = (file.name ?? 'unknown').replaceAll('.json', '');
        projects.add(Project.fromJson(slug, data));
      } catch (e) {
        // skip malformed files silently
      }
    }

    // Sort by created date
    projects.sort((a, b) => a.created.compareTo(b.created));
    return projects;
  }

  // ── Reset cached API (force re-auth if needed) ────────────

  void reset() => _api = null;
}
