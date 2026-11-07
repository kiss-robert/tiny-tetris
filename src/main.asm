format PE GUI 4.0
entry start

include 'win32a.inc'

section '.data' data readable writeable
    windowTitle db 'TinyTetris', 0
    className db 'TinyTetrisWindow', 0
    windowClass WNDCLASS 0, WindowProc, 0, 0, 0, 0, 0, COLOR_WINDOW + 1, 0, className
    message MSG

section '.text' code readable executable
start:
    invoke GetModuleHandle, 0
    mov [windowClass.hInstance], eax
    invoke LoadCursor, 0, IDC_ARROW
    mov [windowClass.hCursor], eax
    invoke RegisterClass, windowClass
    test eax, eax
    jz .error

    invoke CreateWindowEx, 0, className, windowTitle, WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, 360, 560, 0, 0, [windowClass.hInstance], 0
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

proc WindowProc hwnd, uMsg, wParam, lParam
    cmp [uMsg], WM_DESTROY
    je .destroy
    invoke DefWindowProc, [hwnd], [uMsg], [wParam], [lParam]
    ret

.destroy:
    invoke PostQuitMessage, 0
    xor eax, eax
    ret
endp

section '.idata' import data readable writeable
    library kernel32, 'KERNEL32.DLL', user32, 'USER32.DLL'

    import kernel32, ExitProcess, 'ExitProcess', GetModuleHandle, 'GetModuleHandleA'
    import user32, RegisterClass, 'RegisterClassA', CreateWindowEx, 'CreateWindowExA', LoadCursor, 'LoadCursorA', GetMessage, 'GetMessageA', TranslateMessage, 'TranslateMessage', DispatchMessage, 'DispatchMessageA', DefWindowProc, 'DefWindowProcA', PostQuitMessage, 'PostQuitMessage'
