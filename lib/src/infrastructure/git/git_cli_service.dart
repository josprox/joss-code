import 'dart:convert';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../domain/git/git_models.dart';

class GitCliService {
  GitCliService(this._logger);

  final AppLogger _logger;

  Future<GitRepositoryState> readState(String workspacePath) async {
    final isRepo = await _isRepository(workspacePath);
    if (!isRepo) {
      return const GitRepositoryState();
    }
    final branch = await _runGit(workspacePath, ['branch', '--show-current']);
    final status = await _runGit(workspacePath, ['status', '--porcelain=v1']);
    final log = await _runGit(workspacePath, [
      'log',
      '--date=iso-strict',
      '--pretty=format:%H%x1f%an%x1f%ad%x1f%s',
      '-n',
      '20',
    ]);
    return GitRepositoryState(
      isRepository: true,
      branch: branch.stdout.trim().isEmpty ? 'detached' : branch.stdout.trim(),
      changedFiles: _parseStatus(status.stdout),
      history: _parseLog(log.stdout),
      lastOutput: status.stderr.trim().isEmpty ? null : status.stderr,
    );
  }

  Future<String> stage(String workspacePath, String filePath) async {
    return (await _runGit(workspacePath, [
      'add',
      '--',
      filePath,
    ])).combinedOutput;
  }

  Future<String> unstage(String workspacePath, String filePath) async {
    return (await _runGit(workspacePath, [
      'restore',
      '--staged',
      '--',
      filePath,
    ])).combinedOutput;
  }

  Future<String> commit(String workspacePath, String message) async {
    return (await _runGit(workspacePath, [
      'commit',
      '-m',
      message,
    ])).combinedOutput;
  }

  Future<String> pull(String workspacePath) async {
    return (await _runGit(workspacePath, ['pull', '--ff-only'])).combinedOutput;
  }

  Future<String> push(String workspacePath) async {
    return (await _runGit(workspacePath, ['push'])).combinedOutput;
  }

  Future<String> diff(
    String workspacePath,
    String filePath, {
    bool staged = false,
  }) async {
    final args = ['diff', if (staged) '--staged', '--', filePath];
    return (await _runGit(workspacePath, args)).stdout;
  }

  Future<bool> _isRepository(String workspacePath) async {
    final result = await _runGit(workspacePath, [
      'rev-parse',
      '--is-inside-work-tree',
    ], throwOnError: false);
    return result.exitCode == 0 && result.stdout.trim() == 'true';
  }

  Future<_GitResult> _runGit(
    String cwd,
    List<String> args, {
    bool throwOnError = true,
  }) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: cwd,
        runInShell: Platform.isWindows,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final gitResult = _GitResult(
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
      if (throwOnError && result.exitCode != 0) {
        throw ProcessException(
          'git',
          args,
          gitResult.combinedOutput,
          result.exitCode,
        );
      }
      return gitResult;
    } on Object catch (error) {
      _logger.error('Git command failed: git ${args.join(' ')}', error);
      if (throwOnError) {
        rethrow;
      }
      return _GitResult(exitCode: 1, stdout: '', stderr: error.toString());
    }
  }

  List<GitChangedFile> _parseStatus(String porcelain) {
    final files = <GitChangedFile>[];
    for (final line in const LineSplitter().convert(porcelain)) {
      if (line.length < 4) {
        continue;
      }
      final indexStatus = line[0];
      final workTreeStatus = line[1];
      final pathPart = line.substring(3);
      final isStaged = indexStatus.trim().isNotEmpty && indexStatus != '?';
      final statusChar = isStaged ? indexStatus : workTreeStatus;
      final status = switch (statusChar) {
        'M' => GitFileStatus.modified,
        'A' => GitFileStatus.added,
        'D' => GitFileStatus.deleted,
        'R' => GitFileStatus.renamed,
        'U' => GitFileStatus.conflicted,
        '?' => GitFileStatus.untracked,
        _ => GitFileStatus.unknown,
      };
      final renameParts = pathPart.split(' -> ');
      files.add(
        GitChangedFile(
          path: renameParts.last,
          oldPath: renameParts.length > 1 ? renameParts.first : null,
          status: isStaged ? GitFileStatus.staged : status,
          isStaged: isStaged,
        ),
      );
    }
    return files;
  }

  List<GitCommit> _parseLog(String log) {
    return const LineSplitter()
        .convert(log)
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final parts = line.split('\x1f');
          return GitCommit(
            hash: parts.isNotEmpty ? parts[0] : '',
            author: parts.length > 1 ? parts[1] : '',
            date: parts.length > 2
                ? DateTime.tryParse(parts[2]) ??
                      DateTime.fromMillisecondsSinceEpoch(0)
                : DateTime.fromMillisecondsSinceEpoch(0),
            message: parts.length > 3 ? parts[3] : '',
          );
        })
        .toList();
  }
}

class _GitResult {
  const _GitResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  String get combinedOutput =>
      [stdout, stderr].where((part) => part.trim().isNotEmpty).join('\n');
}
