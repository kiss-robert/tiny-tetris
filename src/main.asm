format PE GUI 4.0
entry start

include 'win32a.inc'

section '.data' data readable writeable
    windowTitle db 'TinyTetris', 0
    messageText db 'Hello from TinyTetris!', 0

section '.text' code readable executable
start:
    invoke MessageBox, 0, messageText, windowTitle, MB_OK
    invoke ExitProcess, 0

section '.idata' import data readable writeable
    library kernel32, 'KERNEL32.DLL', user32, 'USER32.DLL'

    import kernel32, ExitProcess, 'ExitProcess'
    import user32, MessageBox, 'MessageBoxA'
