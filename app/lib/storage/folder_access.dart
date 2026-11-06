/// The folder the budget files live in: Google Drive, Dropbox, iCloud/OneDrive
/// or local storage, all through the platform's document provider (Android
/// Storage Access Framework). The user picks the folder once; the grant is
/// persisted by the OS and survives app restarts.
///
/// Thin wrapper over the `dev.artiz.az_budget/files` method channel
/// (android/.../MainActivity.kt). Everything returns plain Dart types so the
/// budget layer is testable without a platform.
library;

import 'package:flutter/services.dart';

class FolderInfo {
  const FolderInfo({required this.uri, required this.name});
  final String uri;
  final String name;
}

class FileEntry {
  const FileEntry({required this.uri, required this.name, this.mimeType, this.lastModified, this.size});
  final String uri;
  final String name;
  final String? mimeType;
  final DateTime? lastModified;
  final int? size;

  bool get isFolder => mimeType == 'vnd.android.document/directory';
}

class PickedDocument {
  const PickedDocument({required this.uri, required this.name, required this.bytes});
  final String uri;
  final String name;
  final Uint8List bytes;
}

class FolderAccessException implements Exception {
  FolderAccessException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Platform-independent interface so tests can fake the folder.
abstract class FolderAccess {
  Future<FolderInfo?> pickFolder();
  Future<PickedDocument?> pickDocument(List<String> mimeTypes);
  Future<bool> hasFolderPermission(String uri);
  Future<List<FileEntry>> listFiles(String folderUri);
  Future<Uint8List> readFile(String uri);
  Future<void> writeFile(String uri, Uint8List bytes);
  Future<String> createFile(String folderUri, String name, String mimeType, Uint8List bytes);
  Future<FileEntry?> fileInfo(String uri);

  /// The folder at [path] (e.g. `['Belege', '2026']`) below [folderUri],
  /// created when missing; returns its URI, usable with [listFiles] and
  /// [createFile].
  Future<String> ensureFolder(String folderUri, List<String> path);
  Future<void> deleteFile(String uri);
}

class PlatformFolderAccess implements FolderAccess {
  static const _channel = MethodChannel('dev.artiz.az_budget/files');

  Future<T> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args) as T;
    } on PlatformException catch (e) {
      throw FolderAccessException(e.message ?? e.code);
    } on MissingPluginException {
      throw FolderAccessException('folder access is not available on this platform');
    }
  }

  @override
  Future<FolderInfo?> pickFolder() async {
    final map = await _call<Map<Object?, Object?>?>('pickFolder');
    if (map == null) return null;
    return FolderInfo(uri: map['uri'] as String, name: (map['name'] as String?) ?? '');
  }

  @override
  Future<PickedDocument?> pickDocument(List<String> mimeTypes) async {
    final map = await _call<Map<Object?, Object?>?>('pickDocument', {'mimeTypes': mimeTypes});
    if (map == null) return null;
    return PickedDocument(
      uri: map['uri'] as String,
      name: (map['name'] as String?) ?? '',
      bytes: map['bytes'] as Uint8List,
    );
  }

  @override
  Future<bool> hasFolderPermission(String uri) => _call<bool>('hasFolderPermission', {'uri': uri});

  @override
  Future<List<FileEntry>> listFiles(String folderUri) async {
    final list = await _call<List<Object?>>('listFiles', {'uri': folderUri});
    return [for (final e in list.cast<Map<Object?, Object?>>()) _entry(e)];
  }

  FileEntry _entry(Map<Object?, Object?> e) => FileEntry(
        uri: e['uri'] as String,
        name: (e['name'] as String?) ?? '',
        mimeType: e['mimeType'] as String?,
        lastModified: e['lastModified'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((e['lastModified'] as num).toInt()),
        size: (e['size'] as num?)?.toInt(),
      );

  @override
  Future<Uint8List> readFile(String uri) => _call<Uint8List>('readFile', {'uri': uri});

  @override
  Future<void> writeFile(String uri, Uint8List bytes) =>
      _call<Object?>('writeFile', {'uri': uri, 'bytes': bytes});

  @override
  Future<String> createFile(String folderUri, String name, String mimeType, Uint8List bytes) =>
      _call<String>('createFile', {'treeUri': folderUri, 'name': name, 'mimeType': mimeType, 'bytes': bytes});

  @override
  Future<FileEntry?> fileInfo(String uri) async {
    final map = await _call<Map<Object?, Object?>?>('fileInfo', {'uri': uri});
    if (map == null) return null;
    return _entry({...map, 'uri': uri});
  }

  @override
  Future<String> ensureFolder(String folderUri, List<String> path) => _call<String>('ensureFolder', {'uri': folderUri, 'path': path});

  @override
  Future<void> deleteFile(String uri) => _call<Object?>('deleteFile', {'uri': uri});
}
