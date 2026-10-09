import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_providers.dart';
import '../../domain/search/search_models.dart';
import '../../infrastructure/search/workspace_search_service.dart';
import '../workspace/workspace_controller.dart';

final searchControllerProvider =
    NotifierProvider<SearchController, SearchStateModel>(SearchController.new);

class SearchController extends Notifier<SearchStateModel> {
  Timer? _debounce;
  SearchCancelToken? _token;

  @override
  SearchStateModel build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _token?.cancel();
    });
    return const SearchStateModel();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query, clearError: true);
    _debounceSearch();
  }

  void setFileQuery(String query) {
    state = state.copyWith(fileQuery: query);
  }

  void setRegex(bool enabled) {
    state = state.copyWith(useRegex: enabled);
    _debounceSearch();
  }

  Future<void> searchNow() async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null || state.query.trim().isEmpty) {
      state = state.copyWith(matches: const [], isSearching: false);
      return;
    }
    _token?.cancel();
    final token = SearchCancelToken();
    _token = token;
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final matches = await ref
          .read(searchServiceProvider)
          .searchText(
            workspacePath: workspace.path,
            query: state.query,
            useRegex: state.useRegex,
            cancelToken: token,
          );
      if (!token.isCancelled) {
        state = state.copyWith(matches: matches, isSearching: false);
      }
    } on Object catch (error) {
      state = state.copyWith(error: error.toString(), isSearching: false);
    }
  }

  void cancel() {
    _token?.cancel();
    state = state.copyWith(isSearching: false);
  }

  void _debounceSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), searchNow);
  }
}
