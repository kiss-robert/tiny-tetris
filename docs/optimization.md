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
