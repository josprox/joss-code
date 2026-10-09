# Plugin Guide

Joss Code has a progressive plugin system. It can install VSIX files, extract them safely, read `package.json` and register metadata contributions. It does not execute arbitrary VS Code extension JavaScript yet.

## Local Extension Folder

Extensions are installed under the platform application-support directory:

```text
JossCode/extensions/<publisher>.<name>-<version>/
```

The installer expects a VSIX with:

```text
extension/package.json
```

## Supported Contributions

The parser currently reads:

- `activationEvents`
- `contributes.commands`
- `contributes.snippets`
- `contributes.themes`
- `contributes.languages`
- `contributes.grammars`
- `contributes.keybindings`
- `contributes.configuration`

## Activation Events

These events are part of the compatibility target:

- `onStartupFinished`
- `onLanguage:<languageId>`
- `onCommand:<commandId>`
- `workspaceContains:<glob>`

The current implementation records these events. Execution hooks are intentionally next-step work because they require permissions, sandboxing and an extension-host API.

## Minimal `package.json`

```json
{
  "name": "hello-joss",
  "displayName": "Hello Joss",
  "publisher": "joss",
  "version": "0.1.0",
  "engines": {
    "vscode": "^1.80.0"
  },
  "activationEvents": [
    "onStartupFinished",
    "onCommand:helloJoss.sayHello"
  ],
  "contributes": {
    "commands": [
      {
        "command": "helloJoss.sayHello",
        "title": "Hello Joss: Say Hello",
        "category": "Hello Joss"
      }
    ],
    "languages": [
      {
        "id": "josslang",
        "aliases": ["Joss Language"],
        "extensions": [".joss"]
      }
    ]
  }
}
```

## Permission Model

Planned permissions:

- filesystem read/write inside workspace,
- command execution,
- network access,
- terminal/task access,
- language server registration,
- UI contribution registration.

Until this exists, plugins are metadata-only and safe by default.

## Extension API Roadmap

1. Register metadata contributions.
2. Register commands backed by internal Joss Code handlers.
3. Add sandboxed extension host for trusted local plugins.
4. Add VS Code API compatibility shim.
5. Add workspace trust prompts and per-extension permissions.
