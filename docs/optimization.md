# Executable size optimization

Sizes refer to `build\TinyTetris.exe`, assembled with FASM 1.73.35 using the VS Code Build task. No executable packer is used.

## Baseline

The playable baseline includes seven-piece bags, rotation, collision detection, line clearing, score and level counters, ten gravity levels, restart, timed keyboard repeat, and double-buffered GDI rendering.

| Component | Virtual size | File size |
| --- | ---: | ---: |
| Headers | 496 bytes used | 512 bytes |
| `.data` | 751 bytes | 1024 bytes |
| `.text` | 2838 bytes | 3072 bytes |
| `.idata` | 918 bytes | 1024 bytes |
| Total file | | 5632 bytes |

File alignment is 512 bytes; section alignment in memory is 4096 bytes.

## Experiment 1: Move zero-initialized state to the data section tail

Hypothesis: reserve initially zero-filled state at the end of `.data` instead of storing it between initialized values. Windows supplies zeros for the virtual section tail that is absent from the file.

Moved 267 bytes: the message structure, board, piece bag, and eight state variables. Explicit zero initializers became `rb` or `rd` reservations where applicable. Initialized data now occupies 484 bytes, fitting within one 512-byte file block. No extra section was introduced.

Result: **5632 -> 5120 bytes**, saving **512 bytes (9.09%)**. The `.data` virtual size remains 751 bytes; its file size falls from 1024 to 512 bytes. Code, import declarations, section count, and section access flags are unchanged.

Validation: the build passed. A temporary executable using the production data layout confirmed all 267 reserved bytes were zero at process startup, checked nonzero defaults, and validated spawning and placement across 100 seven-piece bags. Verification files were kept outside the project. The project owner confirmed gameplay works.

Reference: [Microsoft PE format specification](https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#section-table-section-headers).

## Experiment 2: Shorten stack accesses in WindowProc

Hypothesis: place the large paint and text buffers first in the local declaration so frequently accessed rectangles and handles fall within the signed 8-bit displacement range relative to EBP. This permits shorter instruction encodings without reducing the allocated stack space or changing logic.

Only the local declaration order changed: `countersText` now follows `paint`. The stack frame remains 232 bytes. The frequently accessed locals occupy offsets from EBP-104 through EBP-4.

Result: `.text` shrank **2838 -> 2763 bytes**, saving **75 code bytes**. The executable remains **5120 bytes** because `.text` still rounds up to 3072 bytes. Another 203 code bytes must be removed to reach the next 2560-byte section boundary. Retained as a code-size reduction toward that boundary.

Validation: the build passed. A temporary harness using the current procedures passed real offscreen GDI pixel checks and 502 paint cycles without growth in GDI object count. Verification files were kept outside the project. Manual gameplay confirmation is pending.

## Experiment 3: Share return and fatal-error paths

Hypothesis: replace duplicate procedure epilogues and fatal-error calls with branches to shared code, retaining the required return values and register restoration.

`WindowProc` now uses one seven-byte epilogue instead of seven copies. Its successful zero returns share the same path, while creation failure, background erasure, and default processing preserve their distinct return values. Fatal timer failures branch to the existing startup error exit. `UpdateProgress` and `CanPlacePiece` also share their respective epilogues.

Result: `.text` shrank **2763 -> 2718 bytes**, saving **45 code bytes**. The executable remains **5120 bytes**. Another 158 code bytes must be removed to reach the next 2560-byte section boundary. Retained as a further code-size reduction.

Validation: the build passed. Temporary checks covered keyboard message sequences, 502 offscreen paint cycles without GDI object growth, callback return values and preserved registers, both placement return paths, and level-change return values. Four simulated fatal timer failures exited with status 1; initial timer creation failure returned -1 from `WindowProc`. Verification files were kept outside the project. Manual gameplay confirmation is pending.

## Experiment 4: Simplify board rendering

Hypothesis: replace individually drawn grid lines and allocated colored brushes with a grid-colored board background, inset cell fills, and the stock DC brush. Share coordinate calculation between locked and active cells in `DrawCell`. Keep double buffering and the existing visible colors and one-pixel borders.

This experiment starts after the elapsed-time correction: `.text` is 2824 bytes and the executable is 5120 bytes. The board background extends through the right and bottom grid borders; each cell fills only its 35-by-35-pixel interior. Palette entry zero now contains the empty-cell color. The stock brush color changes through `SetDCBrushColor`; the stock object is never deleted.

Result: `.text` shrank **2824 -> 2645 bytes**, saving **179 code bytes**. The import section shrank **918 -> 858 bytes**, saving **60 bytes** by replacing four imports with one. The `WindowProc` local frame shrank from 232 to 180 bytes. The executable remains **5120 bytes** due to section alignment; another 85 code bytes must be removed to reach the next 2560-byte section boundary. Retained as a reduction in code and import contents.

Validation: the build passed. A temporary harness compared every RGB pixel of 504 full 532-by-800 frames rendered by the old and new procedures. All seven shapes and four rotations, three positions, empty/sparse/dense boards, counters, and game-over text were covered; no pixel differed. GDI object counts were stable after warm-up. All 34 elapsed-time regression scenarios also passed, and gameplay helper source is unchanged. Verification files were kept outside the project. Manual gameplay confirmation is pending.

Tradeoff: all 200 cells are filled on each paint, including empty cells. In one local offscreen benchmark, 1000 empty-board frames took 766 ms before and 953 ms after the change, approximately 0.19 ms more per frame. These timings describe that benchmark rather than a guaranteed on-screen frame rate.

## Experiment 5: Trim instruction encodings

Hypothesis: save the remaining 85 code bytes through equivalent shorter instruction encodings and redundant-condition removal, crossing the next 512-byte file boundary.

Small register constants use balanced `push`/`pop` pairs where shorter than `mov`. Full-width zero stores use `and` with zero, and all-ones constants use `or` with -1 where the changed flags are not subsequently consumed. The key-repeat check tests the relevant byte of `lParam`; duplicate checks in the restart and rotation paths were removed because both are reached through the initial key-down check. `GetPieceShape` folds the type-index adjustment into its address expression. Data layout, imports, function signatures, and reserved local frames are unchanged.

Result: `.text` shrank **2645 -> 2552 bytes**, saving **93 code bytes**. Its file allocation fell from 3072 to 2560 bytes, reducing the executable **5120 -> 4608 bytes**, a **512-byte (10%)** saving. Eight code bytes remain before the section would exceed that boundary again.

Validation: the build passed. Temporary checks passed 504 full-frame RGB comparisons, 34 elapsed-time scenarios, 28224 placement/rotation scenarios, 40000 seven-piece bags with 24 partial-bag resets, and score/level checks at 10-, 100-, and 1000-line thresholds. All 256 high-byte key-flag combinations were checked for movement, rotation, and restart. Verification files were kept outside the project. Manual gameplay confirmation is pending.
