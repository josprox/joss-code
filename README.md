# Joss Code

Joss Code is a professional Flutter foundation for a VS Code-inspired, extensible, multi-platform code editor. It is not a promise of full VS Code parity on day one; it is a clean, compilable architecture designed to evolve toward a real editor with workspaces, plugins, LSP, Git, terminal sessions, settings and themes.

## Real Flutter Constraints

Flutter is strong for a custom workbench, cross-platform UI, theming and responsive layouts. The hard parts of a production code editor are lower-level:

- A native Flutter text editor can be deeply integrated with app state, but Monaco-level editing features require years of behavior: multi-cursor, tokenization, folding, minimap, semantic highlighting and IME edge cases.
- Monaco inside WebView gives mature editing quickly, but introduces WebView focus, file-system bridging, platform shortcuts, LSP transport and extension-host boundaries.
- Integrated terminals need a PTY for true interactive shells. This base starts with process-backed sessions on desktop and documents a PTY adapter path.
- VS Code extensions are Node-based and expect VS Code APIs. This project reads VSIX metadata and contributions first, then grows a compatible API intentionally.
- Mobile/tablet support is viable for browsing/editing, but local terminal, arbitrary language servers and unrestricted filesystem access are platform-limited.

The current implementation therefore uses a native Flutter workbench and native editor contract, with extension points that can later host Monaco, `re_editor`, a PTY backend or a sandboxed extension host.

## Current Features

- VS Code-style workbench: Activity Bar, Sidebar, Editor tabs, Bottom Panel and Status Bar.
- Explorer with open-folder workspace support, ignored heavy directories and file watcher refresh.
- Multi-tab editor with line numbers, syntax highlighting, dirty indicator, save, find/replace, font zoom and basic completions.
- Command Palette powered by an internal Command Registry.
- Settings JSON service with global/workspace shape, recent workspaces, trust list, theme, font, wrap and auto-save settings.
- Integrated terminal sessions backed by desktop shell processes.
- Git integration through Git CLI: repo detection, branch, status, stage, unstage, commit, pull and push.
- VSIX reader: extracts extensions safely, reads `package.json`, commands, snippets, themes, languages, grammars, keybindings and configuration.
- LSP client foundation over stdio with default definitions for Dart, JavaScript/TypeScript, Python, C#, HTML, CSS, JSON and Markdown.
- Workspace Trust and path traversal protection for file operations and extension extraction.

## Getting Started

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

For macOS or Linux:

```bash
flutter run -d macos
flutter run -d linux
```

## Project Map

- `lib/src/domain`: immutable models and editor/workspace/plugin/LSP/Git contracts.
- `lib/src/application`: Riverpod controllers, MVVM-style state and command bootstrap.
- `lib/src/infrastructure`: filesystem, settings, terminal, Git, VSIX and LSP adapters.
- `lib/src/presentation`: workbench UI, editor widget, panels and theme.
- `docs/ARCHITECTURE.md`: architecture details.
- `docs/PLUGIN_GUIDE.md`: extension/plugin development guide.
- `docs/VS_CODE_COMPATIBILITY_ROADMAP.md`: realistic VS Code compatibility plan.

## Validation

The base is expected to stay green with:

```powershell
flutter analyze
flutter test
```

Desktop builds should be validated per platform before release:

```powershell
flutter build windows
```

---

## ☕ Apoya el proyecto / Support

Si este proyecto te ha sido de utilidad o deseas apoyar mi trabajo, ¡puedes invitarme un café!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Fitted?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black&color=FFDD00)](https://buymeacoffee.com/jossestrely)
