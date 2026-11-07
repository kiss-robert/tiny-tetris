format PE GUI 4.0
entry start

include 'win32a.inc'

BOARD_COLUMNS = 10
BOARD_ROWS = 20
CELL_SIZE = 36
BOARD_LEFT = 30
BOARD_TOP = 30
BOARD_RIGHT = BOARD_LEFT + BOARD_COLUMNS * CELL_SIZE
BOARD_BOTTOM = BOARD_TOP + BOARD_ROWS * CELL_SIZE
GRAVITY_TIMER_ID = 1
LINES_PER_LEVEL = 10
MAX_LEVEL = 10

section '.data' data readable writeable
    windowTitle db 'TinyTetris', 0
    className db 'TinyTetrisWindow', 0
    windowClass WNDCLASS 0, WindowProc, 0, 0, 0, 0, 0, 0, 0, className
    message MSG
    boardRect RECT BOARD_LEFT, BOARD_TOP, BOARD_RIGHT, BOARD_BOTTOM
    pieceX dd 4
    pieceY dd 0
    pieceType dd 1
    pieceRotation dd 0
    randomState dd 0
    pieceBag db 7 dup (0)
    bagIndex dd 7
    pieceShapes db 0,1, 1,1, 2,1, 3,1
                db 2,0, 2,1, 2,2, 2,3
                db 3,2, 2,2, 1,2, 0,2
                db 1,3, 1,2, 1,1, 1,0
                db 0,0, 1,0, 0,1, 1,1
                db 0,0, 1,0, 0,1, 1,1
                db 0,0, 1,0, 0,1, 1,1
                db 0,0, 1,0, 0,1, 1,1
                db 1,0, 0,1, 1,1, 2,1
                db 2,1, 1,0, 1,1, 1,2
                db 1,2, 2,1, 1,1, 0,1
                db 0,1, 1,2, 1,1, 1,0
                db 1,0, 2,0, 0,1, 1,1
                db 2,1, 2,2, 1,0, 1,1
                db 1,2, 0,2, 2,1, 1,1
                db 0,1, 0,0, 1,2, 1,1
                db 0,0, 1,0, 1,1, 2,1
                db 2,0, 2,1, 1,1, 1,2
                db 2,2, 1,2, 1,1, 0,1
                db 0,2, 0,1, 1,1, 1,0
                db 0,0, 0,1, 1,1, 2,1
                db 2,0, 1,0, 1,1, 1,2
                db 2,2, 2,1, 1,1, 0,1
                db 0,2, 1,2, 1,1, 1,0
                db 2,0, 0,1, 1,1, 2,1
                db 2,2, 1,0, 1,1, 1,2
                db 0,2, 2,1, 1,1, 0,1
                db 0,0, 1,2, 1,1, 1,0
    pieceColors dd 0, 0FFFF00h, 00D7FFh, 0D050B0h, 40C040h, 4040E0h, 0E07040h, 0080FFh
    board db BOARD_COLUMNS * BOARD_ROWS dup (0)
    gameOver dd 0
    score dd 0
    clearedLines dd 0
    level dd 1
    gravityIntervals dd 1000, 793, 618, 473, 355, 262, 190, 135, 94, 64
    lineScores dd 0, 100, 300, 500, 800
    countersLabels db 'SCORE', 13, 10, 13, 10, 'LINES', 13, 10, 13, 10, 'LEVEL', 0
    countersFormat db '%u', 13, 10, 13, 10, '%u', 13, 10, 13, 10, '%u', 0
    gameOverText db 'GAME OVER', 0
    restartText db 'Press R to restart', 0

section '.text' code readable executable
start:
    invoke GetModuleHandle, 0
    mov [windowClass.hInstance], eax
    invoke LoadCursor, 0, IDC_ARROW
    mov [windowClass.hCursor], eax
    invoke RegisterClass, windowClass
    test eax, eax
    jz .error

    invoke CreateWindowEx, 0, className, windowTitle, WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, 540, 840, 0, 0, [windowClass.hInstance], 0
    test eax, eax
    jz .error

.messageLoop:
    invoke GetMessage, message, 0, 0, 0
    test eax, eax
    jz .exit
    js .error
    invoke TranslateMessage, message
    invoke DispatchMessage, message
    jmp .messageLoop

.exit:
    invoke ExitProcess, 0

.error:
    invoke ExitProcess, 1

proc WindowProc uses ebx esi edi, hwnd, uMsg, wParam, lParam
    local paint:PAINTSTRUCT, clientRect:RECT, pieceRect:RECT, textRect:RECT, previousPen:DWORD, previousFont:DWORD, pieceBrushes[8]:DWORD, shapeEnd:DWORD, countersText[64]:BYTE

    cmp [uMsg], WM_CREATE
    je .create
    cmp [uMsg], WM_PAINT
    je .paint
    cmp [uMsg], WM_KEYDOWN
    je .keyDown
    cmp [uMsg], WM_TIMER
    je .timer
    cmp [uMsg], WM_DESTROY
    je .destroy
.default:
    invoke DefWindowProc, [hwnd], [uMsg], [wParam], [lParam]
    ret

.create:
    invoke GetTickCount
    test eax, eax
    jnz .seedReady
    inc eax
.seedReady:
    mov [randomState], eax
    stdcall SpawnPiece
    invoke SetTimer, [hwnd], GRAVITY_TIMER_ID, [gravityIntervals], 0
    test eax, eax
    jz .createFailed
    xor eax, eax
    ret

.createFailed:
    mov eax, -1
    ret

.timer:
    cmp [gameOver], 0
    jne .keyHandled
    cmp [wParam], GRAVITY_TIMER_ID
    je .moveDown
    jmp .default

.keyDown:
    cmp [gameOver], 0
    je .playingKeys
    cmp [wParam], 'R'
    jne .keyHandled
    test [lParam], 40000000h
    jnz .keyHandled
    invoke SetTimer, [hwnd], GRAVITY_TIMER_ID, [gravityIntervals], 0
    test eax, eax
    jz .keyHandled
    mov ecx, BOARD_COLUMNS * BOARD_ROWS
.clearBoard:
    mov byte [board + ecx - 1], 0
    loop .clearBoard
    mov [score], 0
    mov [clearedLines], 0
    mov [level], 1
    mov [bagIndex], 7
    stdcall SpawnPiece
    mov [gameOver], 0
    jmp .redraw

.playingKeys:
    cmp [wParam], VK_LEFT
    je .moveLeft
    cmp [wParam], VK_RIGHT
    je .moveRight
    cmp [wParam], VK_DOWN
    je .moveDown
    cmp [wParam], VK_UP
    je .rotate
    jmp .default

.rotate:
    test [lParam], 40000000h
    jnz .keyHandled
    stdcall TryRotatePiece
    test eax, eax
    jz .keyHandled
    jmp .redraw

.moveLeft:
    mov ebx, [pieceX]
    dec ebx
    jmp .moveHorizontal

.moveRight:
    mov ebx, [pieceX]
    inc ebx
.moveHorizontal:
    stdcall CanPlacePiece, ebx, [pieceY]
    test eax, eax
    jz .keyHandled
    mov [pieceX], ebx
    jmp .redraw

.moveDown:
    mov esi, [pieceY]
    inc esi
    stdcall CanPlacePiece, [pieceX], esi
    test eax, eax
    jz .lockPiece
    mov [pieceY], esi
    jmp .redraw

.lockPiece:
    stdcall GetPieceShape
    mov esi, eax
    mov ecx, 4
.lockCell:
    movzx eax, byte [esi + 1]
    add eax, [pieceY]
    imul eax, BOARD_COLUMNS
    movzx edx, byte [esi]
    add eax, edx
    add eax, [pieceX]
    mov edx, [pieceType]
    mov [board + eax], dl
    add esi, 2
    loop .lockCell
    stdcall ClearCompletedLines
    stdcall UpdateProgress, eax
    test eax, eax
    jz .spawnNext
    mov eax, [level]
    dec eax
    invoke SetTimer, [hwnd], GRAVITY_TIMER_ID, [gravityIntervals + eax * 4], 0
    test eax, eax
    jnz .spawnNext
    invoke ExitProcess, 1
.spawnNext:
    stdcall SpawnPiece
    stdcall CanPlacePiece, [pieceX], [pieceY]
    test eax, eax
    jnz .redraw
    mov [gameOver], 1
    invoke KillTimer, [hwnd], GRAVITY_TIMER_ID

.redraw:
    invoke InvalidateRect, [hwnd], 0, 0
.keyHandled:
    xor eax, eax
    ret

.paint:
    lea eax, [paint]
    invoke BeginPaint, [hwnd], eax
    mov ebx, eax
    lea eax, [clientRect]
    invoke GetClientRect, [hwnd], eax
    invoke CreateSolidBrush, 121212h
    mov esi, eax
    lea eax, [clientRect]
    invoke FillRect, ebx, eax, esi
    invoke DeleteObject, esi

    invoke CreateSolidBrush, 202020h
    mov esi, eax
    invoke FillRect, ebx, boardRect, esi
    invoke DeleteObject, esi

    mov edi, 1
.createPieceBrushes:
    invoke CreateSolidBrush, [pieceColors + edi * 4]
    mov [pieceBrushes + edi * 4], eax
    inc edi
    cmp edi, 7
    jbe .createPieceBrushes
    xor edi, edi
.boardCells:
    movzx eax, byte [board + edi]
    test eax, eax
    je .nextCell
    mov esi, [pieceBrushes + eax * 4]
    mov eax, edi
    xor edx, edx
    mov ecx, BOARD_COLUMNS
    div ecx
    imul eax, CELL_SIZE
    add eax, BOARD_TOP
    mov [pieceRect.top], eax
    add eax, CELL_SIZE
    mov [pieceRect.bottom], eax
    imul edx, CELL_SIZE
    add edx, BOARD_LEFT
    mov [pieceRect.left], edx
    add edx, CELL_SIZE
    mov [pieceRect.right], edx
    lea eax, [pieceRect]
    invoke FillRect, ebx, eax, esi
.nextCell:
    inc edi
    cmp edi, BOARD_COLUMNS * BOARD_ROWS
    jb .boardCells

    cmp [gameOver], 0
    jne .finishPieces
    mov eax, [pieceType]
    mov esi, [pieceBrushes + eax * 4]
    stdcall GetPieceShape
    mov edi, eax
    add eax, 8
    mov [shapeEnd], eax
.activeCells:
    movzx eax, byte [edi]
    add eax, [pieceX]
    imul eax, CELL_SIZE
    add eax, BOARD_LEFT
    mov [pieceRect.left], eax
    add eax, CELL_SIZE
    mov [pieceRect.right], eax
    movzx eax, byte [edi + 1]
    add eax, [pieceY]
    imul eax, CELL_SIZE
    add eax, BOARD_TOP
    mov [pieceRect.top], eax
    add eax, CELL_SIZE
    mov [pieceRect.bottom], eax

    lea eax, [pieceRect]
    invoke FillRect, ebx, eax, esi
    add edi, 2
    cmp edi, [shapeEnd]
    jb .activeCells
.finishPieces:
    mov edi, 1
.deletePieceBrushes:
    invoke DeleteObject, [pieceBrushes + edi * 4]
    inc edi
    cmp edi, 7
    jbe .deletePieceBrushes

    invoke CreatePen, PS_SOLID, 1, 383838h
    mov esi, eax
    invoke SelectObject, ebx, esi
    mov [previousPen], eax

    mov edi, BOARD_LEFT
.verticalLines:
    invoke MoveToEx, ebx, edi, BOARD_TOP, 0
    invoke LineTo, ebx, edi, BOARD_BOTTOM + 1
    add edi, CELL_SIZE
    cmp edi, BOARD_RIGHT
    jbe .verticalLines

    mov edi, BOARD_TOP
.horizontalLines:
    invoke MoveToEx, ebx, BOARD_LEFT, edi, 0
    invoke LineTo, ebx, BOARD_RIGHT + 1, edi
    add edi, CELL_SIZE
    cmp edi, BOARD_BOTTOM
    jbe .horizontalLines

    invoke SelectObject, ebx, [previousPen]
    invoke DeleteObject, esi
    invoke GetStockObject, DEFAULT_GUI_FONT
    invoke SelectObject, ebx, eax
    mov [previousFont], eax
    invoke SetBkMode, ebx, TRANSPARENT
    invoke SetTextColor, ebx, 0E0E0E0h
    mov [textRect.left], BOARD_RIGHT + 12
    mov eax, [clientRect.right]
    sub eax, 12
    mov [textRect.right], eax
    mov [textRect.top], BOARD_TOP
    mov [textRect.bottom], BOARD_TOP + 160
    lea eax, [textRect]
    invoke DrawText, ebx, countersLabels, -1, eax, DT_LEFT or DT_NOPREFIX
    lea eax, [countersText]
    cinvoke wsprintf, eax, countersFormat, [score], [clearedLines], [level]
    lea eax, [textRect]
    lea edx, [countersText]
    invoke DrawText, ebx, edx, -1, eax, DT_RIGHT or DT_NOPREFIX
    cmp [gameOver], 0
    je .restoreFont
    mov [textRect.top], BOARD_TOP + 190
    mov [textRect.bottom], BOARD_TOP + 230
    lea eax, [textRect]
    invoke DrawText, ebx, gameOverText, -1, eax, DT_CENTER or DT_WORDBREAK or DT_NOPREFIX
    mov [textRect.top], BOARD_TOP + 238
    mov [textRect.bottom], BOARD_TOP + 310
    lea eax, [textRect]
    invoke DrawText, ebx, restartText, -1, eax, DT_CENTER or DT_WORDBREAK or DT_NOPREFIX
.restoreFont:
    invoke SelectObject, ebx, [previousFont]
.finishPaint:
    lea eax, [paint]
    invoke EndPaint, [hwnd], eax
    xor eax, eax
    ret

.destroy:
    invoke KillTimer, [hwnd], GRAVITY_TIMER_ID
    invoke PostQuitMessage, 0
    xor eax, eax
    ret
endp

proc UpdateProgress lines
    mov eax, [lines]
    add [clearedLines], eax
    mov eax, [lineScores + eax * 4]
    imul eax, [level]
    add [score], eax
    mov eax, [clearedLines]
    xor edx, edx
    mov ecx, LINES_PER_LEVEL
    div ecx
    inc eax
    cmp eax, MAX_LEVEL
    jbe .checkLevel
    mov eax, MAX_LEVEL
.checkLevel:
    cmp eax, [level]
    je .unchanged
    mov [level], eax
    mov eax, 1
    ret
.unchanged:
    xor eax, eax
    ret
endp

proc ClearCompletedLines uses ebx esi edi
    xor edx, edx
    mov ebx, (BOARD_ROWS - 1) * BOARD_COLUMNS
.checkRow:
    lea esi, [board + ebx]
    mov ecx, BOARD_COLUMNS
.checkCell:
    cmp byte [esi], 0
    je .previousRow
    inc esi
    loop .checkCell

    inc edx
    mov ecx, ebx
    test ecx, ecx
    jz .clearTopRow
    lea esi, [board + ebx - 1]
    lea edi, [esi + BOARD_COLUMNS]
.shiftCells:
    mov al, [esi]
    mov [edi], al
    dec esi
    dec edi
    loop .shiftCells

.clearTopRow:
    mov ecx, BOARD_COLUMNS
.clearCell:
    mov byte [board + ecx - 1], 0
    loop .clearCell
    jmp .checkRow

.previousRow:
    sub ebx, BOARD_COLUMNS
    jns .checkRow
    mov eax, edx
    ret
endp

proc NextRandom
    mov eax, [randomState]
    mov edx, eax
    shl edx, 13
    xor eax, edx
    mov edx, eax
    shr edx, 17
    xor eax, edx
    mov edx, eax
    shl edx, 5
    xor eax, edx
    mov [randomState], eax
    ret
endp

proc RefillPieceBag uses ebx esi
    xor ecx, ecx
.fill:
    lea eax, [ecx + 1]
    mov [pieceBag + ecx], al
    inc ecx
    cmp ecx, 7
    jb .fill

    mov ebx, 6
.shuffle:
    lea ecx, [ebx + 1]
    mov eax, -1
    xor edx, edx
    div ecx
    mov esi, -1
    sub esi, edx
.randomIndex:
    stdcall NextRandom
    cmp eax, esi
    ja .randomIndex
    dec eax
    xor edx, edx
    div ecx
    mov al, [pieceBag + ebx]
    xchg al, [pieceBag + edx]
    mov [pieceBag + ebx], al
    dec ebx
    jnz .shuffle
    mov [bagIndex], 0
    ret
endp

proc SpawnPiece
    cmp [bagIndex], 7
    jb .takePiece
    stdcall RefillPieceBag
.takePiece:
    mov eax, [bagIndex]
    movzx edx, byte [pieceBag + eax]
    inc [bagIndex]
    mov [pieceType], edx
    mov [pieceRotation], 0
    mov [pieceX], 3
    cmp edx, 2
    jne .setRow
    mov [pieceX], 4
.setRow:
    mov [pieceY], 0
    ret
endp

proc GetPieceShape
    mov eax, [pieceType]
    dec eax
    shl eax, 5
    mov edx, [pieceRotation]
    lea eax, [pieceShapes + eax + edx * 8]
    ret
endp

proc TryRotatePiece uses ebx
    cmp [pieceType], 2
    je .unchanged
    mov ebx, [pieceRotation]
    lea eax, [ebx + 1]
    and eax, 3
    mov [pieceRotation], eax
    stdcall CanPlacePiece, [pieceX], [pieceY]
    test eax, eax
    jnz .done
    mov [pieceRotation], ebx
.unchanged:
    xor eax, eax
.done:
    ret
endp

proc CanPlacePiece uses esi, x, y
    stdcall GetPieceShape
    mov esi, eax
    mov ecx, 4
.checkCell:
    movzx edx, byte [esi]
    add edx, [x]
    cmp edx, BOARD_COLUMNS
    jae .blocked
    movzx eax, byte [esi + 1]
    add eax, [y]
    cmp eax, BOARD_ROWS
    jae .blocked
    imul eax, BOARD_COLUMNS
    add eax, edx
    cmp byte [board + eax], 0
    jne .blocked
    add esi, 2
    loop .checkCell
    mov eax, 1
    ret
.blocked:
    xor eax, eax
    ret
endp

section '.idata' import data readable writeable
    library kernel32, 'KERNEL32.DLL', user32, 'USER32.DLL', gdi32, 'GDI32.DLL'

    import kernel32, ExitProcess, 'ExitProcess', GetModuleHandle, 'GetModuleHandleA', GetTickCount, 'GetTickCount'
    import user32, RegisterClass, 'RegisterClassA', CreateWindowEx, 'CreateWindowExA', LoadCursor, 'LoadCursorA', GetMessage, 'GetMessageA', TranslateMessage, 'TranslateMessage', DispatchMessage, 'DispatchMessageA', DefWindowProc, 'DefWindowProcA', PostQuitMessage, 'PostQuitMessage', BeginPaint, 'BeginPaint', EndPaint, 'EndPaint', GetClientRect, 'GetClientRect', FillRect, 'FillRect', InvalidateRect, 'InvalidateRect', SetTimer, 'SetTimer', KillTimer, 'KillTimer', DrawText, 'DrawTextA', wsprintf, 'wsprintfA'
    import gdi32, CreateSolidBrush, 'CreateSolidBrush', CreatePen, 'CreatePen', SelectObject, 'SelectObject', DeleteObject, 'DeleteObject', MoveToEx, 'MoveToEx', LineTo, 'LineTo', GetStockObject, 'GetStockObject', SetBkMode, 'SetBkMode', SetTextColor, 'SetTextColor'
