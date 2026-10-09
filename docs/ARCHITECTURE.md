# Architecture

Joss Code follows a layered Flutter architecture inspired by Clean Architecture and MVVM. Widgets render state and dispatch commands; application controllers coordinate use cases; infrastructure adapters own platform and IO details.

## Layers

### Presentation

`lib/src/presentation`

- Workbench shell: Activity Bar, Sidebar, Editor Area, Bottom Panel, Status Bar and Command Palette.
- Uses `ConsumerWidget`/`ConsumerStatefulWidget` to observe Riverpod state.
- Avoids heavy business logic inside widgets.
- Keeps fixed dimensions for workbench chrome so tabs, icons and panels do not shift unexpectedly.

### Application

`lib/src/application`

- Riverpod `Notifier` controllers expose state and use cases.
- Controllers depend on services through providers, not constructors hidden inside widgets.
- `command_bootstrap.dart` registers commands used by the Command Palette and keyboard shortcuts.

Main controllers:

- `WorkspaceController`
- `EditorController`
- `SearchController`
- `TerminalController`
- `GitController`
- `PluginsController`
- `LspController`
- `SettingsController`
- `WorkbenchController`

### Domain

`lib/src/domain`

- Pure models for editor documents, workspaces, file nodes, terminal sessions, Git status, plugins, LSP and settings.
- No Flutter UI dependencies except settings theme mapping, which is intentionally small and isolated.

### Infrastructure

`lib/src/infrastructure`

- `LocalFileSystemService`: folder picking, tree loading, safe file CRUD and watcher.
- `JsonSettingsService`: global and workspace JSON settings.
- `WorkspaceSearchService`: text search with debounce/cancel support from the controller.
- `ProcessTerminalService`: desktop shell processes with multiple sessions.
- `GitCliService`: Git CLI adapter.
- `VsixExtensionService`: safe VSIX extraction and `package.json` contribution parsing.
- `GenericLspClient`: JSON-RPC over stdio.

## Core Services

- `CommandRegistry`: central registry for commands, keybinding labels and command palette execution.
- `AppEventBus`: internal event stream for workspace, save, command and sensitive-action events.
- `AppLogger`: in-memory operational/security log shown in the Output panel.
- `PathGuard`: path normalization, workspace containment checks and traversal protection.

## Dependency Injection

`lib/src/core/di/service_providers.dart` defines provider singletons for services. Controllers read them through Riverpod, which keeps the system testable and replaceable.

## Editor Strategy

The first editor is native Flutter:

- `SyntaxTextEditingController` overrides `buildTextSpan` for basic syntax highlighting.
- `CodeEditorView` renders line numbers, tabs, dirty state, find/replace and suggestions.
- `EditorController` owns document state and save behavior.

Future editor engines should implement the same application-level contract so the UI can switch between:

- native Flutter editor,
- Monaco in WebView,
- package-backed editor such as `re_editor`,
- platform-specific high-performance editor backends.

## Security Model

- Workspaces start untrusted unless stored in settings.
- Sensitive commands emit security events.
- File operations assert paths stay inside the workspace.
- VSIX extraction blocks archive path traversal.
- Extensions are parsed and registered, not executed automatically.

## Performance Model

- Heavy folders are ignored by default: `.git`, `node_modules`, `build`, `.dart_tool`, `bin`, `obj`, `.vs`.
- File tree loading is depth-limited initially.
- File watcher refresh is debounced.
- Large files load as previews.
- Search supports cancellation tokens and result limits.
- Extension metadata can be cached under application support directories.
