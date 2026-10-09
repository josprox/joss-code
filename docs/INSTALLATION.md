# Installation

## Requirements

- Flutter stable `3.44.1` or newer.
- Dart `3.12.1` or newer.
- Git CLI for Source Control features.
- Platform desktop toolchain:
  - Windows: Visual Studio Build Tools with Desktop C++ workload.
  - macOS: Xcode.
  - Linux: Flutter Linux desktop dependencies.

## Setup

```powershell
flutter pub get
flutter analyze
flutter test
```

## Run

```powershell
flutter run -d windows
```

```bash
flutter run -d macos
flutter run -d linux
```

## Build

```powershell
flutter build windows
```

```bash
flutter build macos
flutter build linux
```

## Optional Language Servers

Install only the servers you need:

```powershell
npm install -g typescript typescript-language-server vscode-langservers-extracted
pip install python-lsp-server
dotnet tool install -g csharp-ls
```

Dart uses the SDK command directly:

```powershell
dart language-server --protocol=lsp
```

Markdown:

```powershell
winget install ArturS.MarkdownLanguageServer
```

Server commands can be customized through settings once the settings UI grows that surface.
