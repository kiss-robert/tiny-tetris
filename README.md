# TinyTetris

A personal experiment in AI-assisted software engineering: build a minimal, playable native Windows Tetris in x86 Assembly, then explore code optimizations to make the resulting binary as small as possible.

The implementation is generated using AI tools. The project owner guides decisions, reviews changes, and tests behavior.

## Current status

The initial Hello milestone displays a Win32 MessageBox containing "Hello from TinyTetris!" and exits when the dialog is closed. Gameplay is not implemented yet.

## Requirements

- Windows 10 or 11
- Visual Studio Code for the build and run tasks
- Flat Assembler (FASM), including its complete `INCLUDE` directory

The current tasks expect this layout:

```text
C:\Tools\fasm\
    FASM.EXE
    INCLUDE\
        WIN32A.INC
        ...
```

If FASM is installed elsewhere, update the Build task's `command` and `options.env.INCLUDE` in `.vscode/tasks.json`.

## Build and run

1. Open the project folder in Visual Studio Code.
2. Create the `build` directory if it does not exist. Build outputs are excluded from version control, so this directory may be absent in a fresh checkout.
3. Press `Ctrl+Shift+B` to compile `src/main.asm` into `build\TinyTetris.exe`.
4. Select **Terminal > Run Task > Run** to build and launch the application, or launch the executable directly.
5. Click **OK** or close the MessageBox to exit.

The Build task sets the `INCLUDE` environment variable for FASM; no system-wide setting is required. The executable uses Windows system DLLs and requires no third-party runtime or external assets.

## Executable size milestones

| Milestone | Assembler | Executable size | Verification |
| --- | --- | --- | --- |
| Hello MessageBox | FASM 1.73.35 | 2048 bytes (2 KiB) | Build succeeded; project owner confirmed the dialog works. |

Once the game is complete and playable, we will try to optimize the code to make the resulting binary as small as possible. Changes will be measured against actual executable sizes while preserving functionality and compatibility.
