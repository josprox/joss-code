import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../../core/logging/app_logger.dart';
import '../../core/security/path_guard.dart';
import '../../domain/workspace/workspace_models.dart';

class FileReadResult {
  const FileReadResult({
    required this.content,
    required this.isLargeFile,
    this.error,
  });

  final String content;
  final bool isLargeFile;
  final String? error;
}

class LocalFileSystemService {
  LocalFileSystemService(this._pathGuard, this._logger);

  static const ignoredDirectoryNames = {
    '.git',
    'node_modules',
    'build',
    '.dart_tool',
    'bin',
    'obj',
    '.vs',
    '.idea',
    '.vscode-test',
  };

  static const largeFileBytes = 1024 * 1024 * 2;
  static const previewBytes = 1024 * 1024;

  final PathGuard _pathGuard;
  final AppLogger _logger;
  StreamSubscription<WatchEvent>? _watchSubscription;

  Future<String?> pickWorkspacePath() {
    return FilePicker.getDirectoryPath(dialogTitle: 'Open Workspace');
  }

  Future<FileNode> buildTree(String rootPath, {int maxDepth = 5}) async {
    final rootDirectory = Directory(rootPath);
    if (!await rootDirectory.exists()) {
      throw FileSystemException('Workspace directory does not exist', rootPath);
    }
    return _readNode(rootDirectory, rootPath, depth: 0, maxDepth: maxDepth);
  }

  Future<FileNode> _readNode(
    FileSystemEntity entity,
    String workspacePath, {
    required int depth,
    required int maxDepth,
  }) async {
    final stat = await entity.stat();
    final isDirectory = stat.type == FileSystemEntityType.directory;
    final name = p.basename(entity.path);
    if (!isDirectory) {
      return FileNode(
        path: entity.path,
        name: name,
        isDirectory: false,
        size: stat.size,
        modifiedAt: stat.modified,
      );
    }

    final children = <FileNode>[];
    if (depth < maxDepth) {
      final directory = Directory(entity.path);
      await for (final child in directory.list(followLinks: false)) {
        if (_shouldIgnore(child.path)) {
          continue;
        }
        children.add(
          await _readNode(
            child,
            workspacePath,
            depth: depth + 1,
            maxDepth: maxDepth,
          ),
        );
      }
      children.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return FileNode(
      path: entity.path,
      name: name.isEmpty ? entity.path : name,
      isDirectory: true,
      children: children,
      modifiedAt: stat.modified,
      isExpanded: depth == 0,
    );
  }

  Future<FileReadResult> readTextFile(String path, String workspacePath) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    try {
      final file = File(path);
      final size = await file.length();
      final stream = file.openRead(
        0,
        size > largeFileBytes ? previewBytes : null,
      );
      final bytes = await stream.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      final content = utf8.decode(bytes, allowMalformed: true);
      return FileReadResult(
        content: content,
        isLargeFile: size > largeFileBytes,
      );
    } on Object catch (error) {
      _logger.error('Failed to read file $path', error);
      return FileReadResult(
        content: '',
        isLargeFile: false,
        error: error.toString(),
      );
    }
  }

  Future<void> writeTextFile(
    String path,
    String workspacePath,
    String content,
  ) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    await File(path).writeAsString(content, encoding: utf8);
  }

  Future<void> createFile(String path, String workspacePath) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    final file = File(path);
    if (await file.exists()) {
      throw FileSystemException('File already exists', path);
    }
    await file.create(recursive: true);
  }

  Future<void> createFolder(String path, String workspacePath) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    await Directory(path).create(recursive: true);
  }

  Future<void> rename(String path, String workspacePath, String newName) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    final target = p.join(p.dirname(path), newName);
    _pathGuard.assertWithinWorkspace(target, workspacePath);
    await _renameEntity(path, target);
  }

  Future<void> move(
    String path,
    String workspacePath,
    String targetDirectory,
  ) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    _pathGuard.assertWithinWorkspace(targetDirectory, workspacePath);
    await _renameEntity(path, p.join(targetDirectory, p.basename(path)));
  }

  Future<void> delete(String path, String workspacePath) async {
    _pathGuard.assertWithinWorkspace(path, workspacePath);
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  Stream<WatchEvent> watch(String workspacePath) {
    _watchSubscription?.cancel();
    return DirectoryWatcher(
      workspacePath,
    ).events.where((event) => !_shouldIgnore(event.path));
  }

  bool _shouldIgnore(String path) {
    final segments = p.split(path);
    return segments.any(ignoredDirectoryNames.contains);
  }

  Future<void> _renameEntity(String source, String target) async {
    final type = await FileSystemEntity.type(source);
    if (type == FileSystemEntityType.directory) {
      await Directory(source).rename(target);
    } else {
      await File(source).rename(target);
    }
  }
}
