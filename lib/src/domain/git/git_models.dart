enum GitFileStatus {
  modified,
  added,
  deleted,
  renamed,
  untracked,
  conflicted,
  staged,
  unknown,
}

class GitChangedFile {
  const GitChangedFile({
    required this.path,
    required this.status,
    this.isStaged = false,
    this.oldPath,
  });

  final String path;
  final GitFileStatus status;
  final bool isStaged;
  final String? oldPath;
}

class GitCommit {
  const GitCommit({
    required this.hash,
    required this.author,
    required this.message,
    required this.date,
  });

  final String hash;
  final String author;
  final String message;
  final DateTime date;
}

class GitRepositoryState {
  const GitRepositoryState({
    this.isRepository = false,
    this.branch,
    this.changedFiles = const [],
    this.history = const [],
    this.lastOutput,
    this.error,
    this.isBusy = false,
  });

  final bool isRepository;
  final String? branch;
  final List<GitChangedFile> changedFiles;
  final List<GitCommit> history;
  final String? lastOutput;
  final String? error;
  final bool isBusy;

  GitRepositoryState copyWith({
    bool? isRepository,
    String? branch,
    List<GitChangedFile>? changedFiles,
    List<GitCommit>? history,
    String? lastOutput,
    String? error,
    bool? isBusy,
    bool clearError = false,
  }) {
    return GitRepositoryState(
      isRepository: isRepository ?? this.isRepository,
      branch: branch ?? this.branch,
      changedFiles: changedFiles ?? this.changedFiles,
      history: history ?? this.history,
      lastOutput: lastOutput ?? this.lastOutput,
      error: clearError ? null : error ?? this.error,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}
