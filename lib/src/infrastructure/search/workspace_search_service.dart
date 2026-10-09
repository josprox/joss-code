import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/search/search_models.dart';
import '../filesystem/local_file_system_service.dart';

class SearchCancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class WorkspaceSearchService {
  Future<List<SearchMatch>> searchText({
    required String workspacePath,
    required String query,
    bool useRegex = false,
    SearchCancelToken? cancelToken,
    int maxResults = 500,
  }) async {
    if (query.trim().isEmpty) {
      return const [];
    }
    final results = <SearchMatch>[];
    final matcher = useRegex ? RegExp(query, caseSensitive: false) : null;
    await for (final entity in Directory(
      workspacePath,
    ).list(recursive: true, followLinks: false)) {
      if (cancelToken?.isCancelled ?? false) {
        break;
      }
      if (results.length >= maxResults) {
        break;
      }
      if (entity is! File || _shouldIgnore(entity.path)) {
        continue;
      }
      final stat = await entity.stat();
      if (stat.size > LocalFileSystemService.largeFileBytes) {
        continue;
      }
      final lines = const LineSplitter().convert(
        await entity.readAsString(encoding: utf8).catchError((_) => ''),
      );
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final matches = matcher == null
            ? _plainMatches(line, query)
            : matcher.allMatches(line);
        for (final match in matches) {
          results.add(
            SearchMatch(
              filePath: entity.path,
              lineNumber: index + 1,
              column: match.start + 1,
              preview: line.trimRight(),
            ),
          );
          if (results.length >= maxResults) {
            return results;
          }
        }
      }
    }
    return results;
  }

  Future<List<String>> searchFiles({
    required String workspacePath,
    required String query,
    SearchCancelToken? cancelToken,
    int maxResults = 200,
  }) async {
    if (query.trim().isEmpty) {
      return const [];
    }
    final results = <String>[];
    final lowerQuery = query.toLowerCase();
    await for (final entity in Directory(
      workspacePath,
    ).list(recursive: true, followLinks: false)) {
      if (cancelToken?.isCancelled ?? false) {
        break;
      }
      if (_shouldIgnore(entity.path)) {
        continue;
      }
      if (p.basename(entity.path).toLowerCase().contains(lowerQuery)) {
        results.add(entity.path);
        if (results.length >= maxResults) {
          break;
        }
      }
    }
    return results;
  }

  Iterable<RegExpMatch> _plainMatches(String line, String query) {
    return RegExp(RegExp.escape(query), caseSensitive: false).allMatches(line);
  }

  bool _shouldIgnore(String path) {
    final segments = p.split(path);
    return segments.any(LocalFileSystemService.ignoredDirectoryNames.contains);
  }
}
