import 'package:path/path.dart' as p;

enum WorkspacePanel { explorer, search, sourceControl, extensions, settings }

class Workspace {
  const Workspace({
    required this.path,
    required this.name,
    this.isTrusted = false,
    this.openedAt,
  });

  final String path;
  final String name;
  final bool isTrusted;
  final DateTime? openedAt;

  Workspace copyWith({
    String? path,
    String? name,
    bool? isTrusted,
    DateTime? openedAt,
  }) {
    return Workspace(
      path: path ?? this.path,
      name: name ?? this.name,
      isTrusted: isTrusted ?? this.isTrusted,
      openedAt: openedAt ?? this.openedAt,
    );
  }
}

class FileNode {
  const FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.children = const [],
    this.size,
    this.modifiedAt,
    this.isExpanded = false,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final List<FileNode> children;
  final int? size;
  final DateTime? modifiedAt;
  final bool isExpanded;

  String get extension => p.extension(name);

  FileNode copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    List<FileNode>? children,
    int? size,
    DateTime? modifiedAt,
    bool? isExpanded,
  }) {
    return FileNode(
      path: path ?? this.path,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class WorkspaceStateModel {
  const WorkspaceStateModel({
    this.workspace,
    this.root,
    this.activePanel = WorkspacePanel.explorer,
    this.expandedPaths = const {},
    this.isLoadingTree = false,
    this.error,
  });

  final Workspace? workspace;
  final FileNode? root;
  final WorkspacePanel activePanel;
  final Set<String> expandedPaths;
  final bool isLoadingTree;
  final String? error;

  WorkspaceStateModel copyWith({
    Workspace? workspace,
    FileNode? root,
    WorkspacePanel? activePanel,
    Set<String>? expandedPaths,
    bool? isLoadingTree,
    String? error,
    bool clearError = false,
  }) {
    return WorkspaceStateModel(
      workspace: workspace ?? this.workspace,
      root: root ?? this.root,
      activePanel: activePanel ?? this.activePanel,
      expandedPaths: expandedPaths ?? this.expandedPaths,
      isLoadingTree: isLoadingTree ?? this.isLoadingTree,
      error: clearError ? null : error ?? this.error,
    );
  }
}
