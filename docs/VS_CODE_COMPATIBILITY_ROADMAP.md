# VS Code Compatibility Roadmap

Joss Code should grow toward VS Code compatibility gradually and honestly.

## Current

- VSIX extraction.
- `package.json` metadata parsing.
- Commands, snippets, themes, languages, grammars, keybindings and configuration metadata.
- Activation events stored but not executed.
- Native command registry.
- Native settings and theme manager foundation.
- Generic LSP client.

## Phase 1: Metadata Compatibility

- Cache extension manifests.
- Show installed extensions with contribution counts.
- Register themes into `AppTheme`.
- Register language IDs and extension mappings.
- Register snippets for the native editor suggestion layer.

## Phase 2: Safe Internal Plugins

- Allow local Joss plugins to register Dart-side commands through a stable API.
- Require explicit trust for command execution and filesystem writes.
- Add plugin logs and disable/uninstall actions.

## Phase 3: VS Code API Shim

- Implement a subset of the VS Code extension API:
  - `commands.registerCommand`
  - `workspace.getConfiguration`
  - `languages.registerCompletionItemProvider`
  - `window.showInformationMessage`
  - `workspace.workspaceFolders`
- Run extension code in a controlled host process.
- Bridge calls over JSON-RPC.

## Phase 4: Language and Grammar Parity

- Load TextMate grammars from extensions.
- Add semantic token support from LSP.
- Add snippets with variables and tab stops.
- Add configurable keybindings.

## Phase 5: Marketplace and Trust

- Add extension search/source configuration.
- Add extension signing or checksum validation.
- Add Workspace Trust enforcement for activation events.
- Add permission prompts and audit logs.

## Not Immediate

- Full Node-based extension compatibility.
- Debug Adapter Protocol parity.
- Webview extension API.
- Remote development extension host.
- Complete VS Code settings/keybinding compatibility.
