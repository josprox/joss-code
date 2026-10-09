class SearchMatch {
  const SearchMatch({
    required this.filePath,
    required this.lineNumber,
    required this.column,
    required this.preview,
  });

  final String filePath;
  final int lineNumber;
  final int column;
  final String preview;
}

class SearchStateModel {
  const SearchStateModel({
    this.query = '',
    this.fileQuery = '',
    this.useRegex = false,
    this.isSearching = false,
    this.matches = const [],
    this.error,
  });

  final String query;
  final String fileQuery;
  final bool useRegex;
  final bool isSearching;
  final List<SearchMatch> matches;
  final String? error;

  SearchStateModel copyWith({
    String? query,
    String? fileQuery,
    bool? useRegex,
    bool? isSearching,
    List<SearchMatch>? matches,
    String? error,
    bool clearError = false,
  }) {
    return SearchStateModel(
      query: query ?? this.query,
      fileQuery: fileQuery ?? this.fileQuery,
      useRegex: useRegex ?? this.useRegex,
      isSearching: isSearching ?? this.isSearching,
      matches: matches ?? this.matches,
      error: clearError ? null : error ?? this.error,
    );
  }
}
