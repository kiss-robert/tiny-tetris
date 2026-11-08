# TinyTetris

A personal experiment in AI-assisted software engineering: build a minimal, playable native Windows Tetris in x86 Assembly, then explore code optimizations to make the resulting binary as small as possible.

The implementation is generated using AI tools. The project owner guides decisions, reviews changes, and tests behavior.

## Current status

TinyTetris is playable. The current executable is **4608 bytes (4.5 KiB)**, built with FASM 1.73.35.

- A 10-by-20 board with all seven classic tetrominoes, colors, and shuffled seven-piece bags.
- Movement, clockwise rotation, automatic falling, collision detection, and completed-line clearing.
- Score, line, and level counters; ten progressively faster levels, advancing every ten cleared lines.
- Game over and restart, with double-buffered graphics for flicker-free drawing.

The game continues at level 10 until game over. Size optimization is underway; the experiments and measurements are recorded in [the optimization log](docs/optimization.md).

## Requirements

The instructions below use a Windows 10 or 11 PC with 64-bit Windows. The game itself is a native 32-bit Windows application.

| Tool | What it does | Download |
| --- | --- | --- |
| Visual Studio Code | Opens the project and provides the Build and Run commands. | [Download VS Code for Windows](https://code.visualstudio.com/download) |
| Flat Assembler (FASM) | Turns the Assembly source into the playable `.exe` file. Download the **flat assembler for Windows** package, including its `INCLUDE` folder. | [Download FASM](https://flatassembler.net/download.php) |
| FASM extension by tpxhorus (optional) | Adds syntax highlighting when viewing the Assembly source in VS Code. | [Install the FASM extension](https://marketplace.visualstudio.com/items?itemName=tpxhorus.fasm) |

The recorded executable sizes were measured with **FASM 1.73.35**. The optional VS Code extension provides highlighting; the separate FASM download provides the assembler used to build the game.

## Build and run

You can follow these steps without writing code or entering terminal commands. Git is not required.

### 1. Install Visual Studio Code

1. Open the [VS Code download page](https://code.visualstudio.com/download) and download the Windows installer. The **User Installer** is suitable for a personal setup.
2. Open the downloaded installer and follow its setup instructions. The default installation options are sufficient for this project.
3. Launch Visual Studio Code when installation finishes.

### 2. Set up FASM

1. Open the [FASM download page](https://flatassembler.net/download.php) and download **flat assembler for Windows**.
2. In Windows File Explorer, right-click the downloaded ZIP file, choose **Extract All**, and then choose **Extract**.
3. Create the folder `C:\Tools\fasm` in File Explorer.
4. In the extracted files, locate the folder containing `FASM.EXE`. Copy its contents, including the complete `INCLUDE` folder, into `C:\Tools\fasm`.

Check that these files are in the following locations:

```text
C:\Tools\fasm\
    FASM.EXE
    INCLUDE\
        WIN32A.INC
        API\
        EQUATES\
        MACRO\
```

Keep the other extracted files too. FASM is ready to use from this folder; it does not need a separate installer. The project's build configuration supplies the include path automatically.

### 3. Download the project

1. On this project's GitHub page, click **Code**, then **Download ZIP**.
2. In File Explorer, right-click the downloaded ZIP, choose **Extract All**, and extract it to a folder you can easily find, such as your Documents folder.
3. Open the extracted project folder. It contains `README.md`, the `src` folder, and the `.vscode` folder.

### 4. Open the project in VS Code

1. In VS Code, choose **File > Open Folder**.
2. Select the extracted project folder containing `README.md` and `src`, then choose **Select Folder**.
3. If VS Code asks whether you trust the authors, choose **Yes, I trust the authors** to enable the project's build tasks.

Optionally, press `Ctrl+Shift+X` to open Extensions, search for `@id:tpxhorus.fasm`, and choose **Install**. This makes the source easier to read with colored highlighting.

### 5. Build the game

Building means turning the source files into a program Windows can run.

1. In File Explorer, open the extracted project folder. Create a folder named `build` next to `src` and `README.md` if it is not already there. To create it, right-click an empty area and choose **New > Folder**.
2. Return to VS Code and press `Ctrl+Shift+B`. You can also choose **Terminal > Run Build Task**.
3. Wait for the task to finish. The terminal panel at the bottom shows FASM's output, including the executable size on a successful build.
4. The finished game is now at `build\TinyTetris.exe` inside the project folder.

The `build` folder is excluded from the repository, which is why you may need to create it after downloading the project.

### 6. Run the game

In VS Code, choose **Terminal > Run Task**, then select **Run**. This builds the game and opens its window.

You can also open the project's `build` folder in File Explorer and double-click `TinyTetris.exe`. Windows may display its name as `TinyTetris` when file extensions are hidden.

After building, only `TinyTetris.exe` is needed to play. It uses Windows system libraries and requires no third-party runtime or external assets.

### If something does not work

| Problem | What to check |
| --- | --- |
| The build cannot find FASM. | Confirm that `FASM.EXE` is directly inside `C:\Tools\fasm`. |
| The build cannot find `win32a.inc` or another include file. | Confirm that the complete `INCLUDE` folder is inside `C:\Tools\fasm`, with `WIN32A.INC` directly inside it. |
| The build cannot create or overwrite `TinyTetris.exe`. | Create the project's `build` folder and close any running copy of the game, then build again. |
| VS Code cannot find the Build or Run task. | Use **File > Open Folder** to open the project folder containing `.vscode` and `README.md`. |

For a different FASM installation location, update the Build task's `command` and `options.env.INCLUDE` paths in `.vscode/tasks.json`. Using the location shown above avoids this configuration step.

## Controls

Click the game window to give it keyboard focus.

| Key | Action |
| --- | --- |
| Left / Right arrow | Move sideways; hold to repeat. |
| Down arrow | Fall faster; hold to continue. |
| Up arrow | Rotate clockwise once per keypress. |
| R | Start a new game after game over. |
| Window close button | Exit the game. |

Elapsed game time continues during window interactions, including minimization. If Windows delays processing, the game catches up afterward, potentially reaching game over.

## Executable size milestones

These are measured file sizes using FASM 1.73.35.

| Milestone | Executable size |
| --- | ---: |
| Initial Hello MessageBox | 2048 bytes (2 KiB) |
| Playable baseline before size optimization | 5632 bytes (5.5 KiB) |
| Zero-initialized data optimization | 5120 bytes (5 KiB) |
| Current optimized game | **4608 bytes (4.5 KiB)** |

The current game is 1024 bytes smaller than the playable baseline, a reduction of approximately 18.2%. Optimization targets the actual executable size while preserving functionality and Windows compatibility. No executable packer is used. See [the optimization log](docs/optimization.md) for the individual experiments and validation results.
