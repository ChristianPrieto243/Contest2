; contest2.asm - Aim Trainer Game
; Win32 GUI application 

.386
.model flat, stdcall
option casemap:none

; Standard includes from Irvine32 environment
INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

; Links
INCLUDELIB user32.lib
INCLUDELIB kernel32.lib
INCLUDELIB Irvine32.lib

.data
    ; Window class and title strings
    className   BYTE "AimTrainerWinClass", 0
    windowTitle BYTE "Aim Trainer Game", 0
    
    ; Window handle 
    hMainWnd    DWORD ?
    
    ; Game state variables
    score       DWORD 0
    targetX     DWORD 100
    targetY     DWORD 100
    targetSize  DWORD 30
    targetActive DWORD 1
.code

WinMain PROC
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hInstance:DWORD
    
    ; Get current instance handle 
    INVOKE GetModuleHandle, NULL
    mov hInstance, eax
    
    ; Fill in window class structure
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    ; Load the program's icon and cursor.
    INVOKE LoadIcon, NULL, IDI_APPLICATION
    mov MainWin.hIcon, eax
    INVOKE LoadCursor, NULL, IDC_ARROW
    mov MainWin.hCursor, eax
    ; Register the window class.
    INVOKE RegisterClass, ADDR MainWin
    .IF eax == 0
    call ErrorHandler
    jmp Exit_Program
    .ENDIF
    ; Returns a handle to the main window in EAX.
    INVOKE CreateWindowEx, 0, ADDR className,
    ADDR WindowName,MAIN_WINDOW_STYLE,
    CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
    CW_USEDEFAULT,NULL,NULL,hInstance,NULL
    mov hMainWnd,eax
    ; If CreateWindowEx failed, display a message & exit.
    .IF eax == 0
    call ErrorHandler
    jmp Exit_Program
    .ENDIF
    ; Show and draw the window.
    INVOKE ShowWindow, hMainWnd, SW_SHOW
    INVOKE UpdateWindow, hMainWnd
Exit_Program:
INVOKE ExitProcess,0
WinMain ENDP





