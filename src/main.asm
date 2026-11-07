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

section '.data' data readable writeable
    windowTitle db 'TinyTetris', 0
    className db 'TinyTetrisWindow', 0
    windowClass WNDCLASS 0, WindowProc, 0, 0, 0, 0, 0, 0, 0, className
    message MSG
    boardRect RECT BOARD_LEFT, BOARD_TOP, BOARD_RIGHT, BOARD_BOTTOM
    pieceX dd 4
    pieceY dd 0

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
    local paint:PAINTSTRUCT, clientRect:RECT, pieceRect:RECT, previousPen:DWORD

    cmp [uMsg], WM_PAINT
    je .paint
    cmp [uMsg], WM_KEYDOWN
    je .keyDown
    cmp [uMsg], WM_DESTROY
    je .destroy
.default:
    invoke DefWindowProc, [hwnd], [uMsg], [wParam], [lParam]
    ret

.keyDown:
    cmp [wParam], VK_LEFT
    je .moveLeft
    cmp [wParam], VK_RIGHT
    je .moveRight
    cmp [wParam], VK_DOWN
    je .moveDown
    jmp .default

.moveLeft:
    cmp [pieceX], 0
    jbe .keyHandled
    dec [pieceX]
    jmp .redraw

.moveRight:
    cmp [pieceX], BOARD_COLUMNS - 2
    jae .keyHandled
    inc [pieceX]
    jmp .redraw

.moveDown:
    cmp [pieceY], BOARD_ROWS - 2
    jae .keyHandled
    inc [pieceY]

.redraw:
    invoke InvalidateRect, [hwnd], boardRect, 0
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

    mov eax, [pieceX]
    imul eax, CELL_SIZE
    add eax, BOARD_LEFT
    mov [pieceRect.left], eax
    add eax, 2 * CELL_SIZE
    mov [pieceRect.right], eax
    mov eax, [pieceY]
    imul eax, CELL_SIZE
    add eax, BOARD_TOP
    mov [pieceRect.top], eax
    add eax, 2 * CELL_SIZE
    mov [pieceRect.bottom], eax

    invoke CreateSolidBrush, 00D7FFh
    mov esi, eax
    lea eax, [pieceRect]
    invoke FillRect, ebx, eax, esi
    invoke DeleteObject, esi

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
    lea eax, [paint]
    invoke EndPaint, [hwnd], eax
    xor eax, eax
    ret

.destroy:
    invoke PostQuitMessage, 0
    xor eax, eax
    ret
endp

section '.idata' import data readable writeable
    library kernel32, 'KERNEL32.DLL', user32, 'USER32.DLL', gdi32, 'GDI32.DLL'

    import kernel32, ExitProcess, 'ExitProcess', GetModuleHandle, 'GetModuleHandleA'
    import user32, RegisterClass, 'RegisterClassA', CreateWindowEx, 'CreateWindowExA', LoadCursor, 'LoadCursorA', GetMessage, 'GetMessageA', TranslateMessage, 'TranslateMessage', DispatchMessage, 'DispatchMessageA', DefWindowProc, 'DefWindowProcA', PostQuitMessage, 'PostQuitMessage', BeginPaint, 'BeginPaint', EndPaint, 'EndPaint', GetClientRect, 'GetClientRect', FillRect, 'FillRect', InvalidateRect, 'InvalidateRect'
    import gdi32, CreateSolidBrush, 'CreateSolidBrush', CreatePen, 'CreatePen', SelectObject, 'SelectObject', DeleteObject, 'DeleteObject', MoveToEx, 'MoveToEx', LineTo, 'LineTo'
