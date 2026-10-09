import 'package:path/path.dart' as p;

enum EditorLanguage {
  dart,
  javascript,
  typescript,
  python,
  csharp,
  html,
  css,
  json,
  markdown,
  yaml,
  shell,
  plainText;

  String get displayName {
    return switch (this) {
      EditorLanguage.dart => 'Dart',
      EditorLanguage.javascript => 'JavaScript',
      EditorLanguage.typescript => 'TypeScript',
      EditorLanguage.python => 'Python',
      EditorLanguage.csharp => 'C#',
      EditorLanguage.html => 'HTML',
      EditorLanguage.css => 'CSS',
      EditorLanguage.json => 'JSON',
      EditorLanguage.markdown => 'Markdown',
      EditorLanguage.yaml => 'YAML',
      EditorLanguage.shell => 'Shell',
      EditorLanguage.plainText => 'Plain Text',
    };
  }

  static EditorLanguage fromPath(String path) {
    return switch (p.extension(path).toLowerCase()) {
      '.dart' => EditorLanguage.dart,
      '.js' || '.mjs' || '.cjs' => EditorLanguage.javascript,
      '.ts' || '.tsx' => EditorLanguage.typescript,
      '.py' => EditorLanguage.python,
      '.cs' => EditorLanguage.csharp,
      '.html' || '.htm' => EditorLanguage.html,
      '.css' || '.scss' || '.sass' => EditorLanguage.css,
      '.json' => EditorLanguage.json,
      '.md' || '.markdown' => EditorLanguage.markdown,
      '.yaml' || '.yml' => EditorLanguage.yaml,
      '.sh' || '.bash' || '.ps1' => EditorLanguage.shell,
      _ => EditorLanguage.plainText,
    };
  }
}

class EditorDocument {
  EditorDocument({
    required this.id,
    required this.path,
    required this.name,
    required this.content,
    required this.language,
    this.isDirty = false,
    this.isLargeFile = false,
    this.error,
    DateTime? openedAt,
  }) : openedAt = openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String id;
  final String path;
  final String name;
  final String content;
  final EditorLanguage language;
  final bool isDirty;
  final bool isLargeFile;
  final String? error;
  final DateTime openedAt;

  int get lineCount =>
      content.isEmpty ? 1 : '\n'.allMatches(content).length + 1;

  EditorDocument copyWith({
    String? id,
    String? path,
    String? name,
    String? content,
    EditorLanguage? language,
    bool? isDirty,
    bool? isLargeFile,
    String? error,
    DateTime? openedAt,
  }) {
    return EditorDocument(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
      isDirty: isDirty ?? this.isDirty,
      isLargeFile: isLargeFile ?? this.isLargeFile,
      error: error,
      openedAt: openedAt ?? this.openedAt,
    );
  }
}

class EditorStateModel {
  const EditorStateModel({
    this.openDocuments = const [],
    this.activeDocumentId,
    this.fontZoom = 0,
    this.splitAxis,
    this.searchQuery = '',
    this.replaceQuery = '',
    this.showFind = false,
  });

  final List<EditorDocument> openDocuments;
  final String? activeDocumentId;
  final int fontZoom;
  final String? splitAxis;
  final String searchQuery;
  final String replaceQuery;
  final bool showFind;

  EditorDocument? get activeDocument {
    for (final document in openDocuments) {
      if (document.id == activeDocumentId) {
        return document;
      }
    }
    return openDocuments.isEmpty ? null : openDocuments.first;
  }

  EditorStateModel copyWith({
    List<EditorDocument>? openDocuments,
    String? activeDocumentId,
    int? fontZoom,
    String? splitAxis,
    String? searchQuery,
    String? replaceQuery,
    bool? showFind,
    bool clearActiveDocumentId = false,
    bool clearSplitAxis = false,
  }) {
    return EditorStateModel(
      openDocuments: openDocuments ?? this.openDocuments,
      activeDocumentId: clearActiveDocumentId
          ? null
          : activeDocumentId ?? this.activeDocumentId,
      fontZoom: fontZoom ?? this.fontZoom,
      splitAxis: clearSplitAxis ? null : splitAxis ?? this.splitAxis,
      searchQuery: searchQuery ?? this.searchQuery,
      replaceQuery: replaceQuery ?? this.replaceQuery,
      showFind: showFind ?? this.showFind,
    );
  }
}
