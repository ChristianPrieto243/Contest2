; contest2.asm - Aim Trainer Game
; Win32 GUI application using GraphWin.inc 

INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

;==================== DATA =======================
.data
    WindowName BYTE "Aim Trainer Game", 0
    className  BYTE "AimTrainerWinClass", 0
    
    ; Define the Application's Window class structure
    MainWin WNDCLASS <NULL, WinProc, NULL, NULL, NULL, NULL, NULL, \
                      COLOR_WINDOW, NULL, className>
    
    msg MSGStruct <>
    hMainWnd DWORD ?
    hInstance DWORD ?
    
    ; Game state variables
    score       DWORD 0
    targetCount     DWORD 100
    targetMaxHealth    DWORD 100
    targetSize  DWORD 30
    targetActive DWORD 1

    Target STRUCT
        x DWORD 0 ; change to random value
        y DWORD 0 ; change to random value
        health WORD 3; amount of health the targets have
    Target ENDS


.code

WinProc PROC, hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler

    mov eax, localMsg
    
    .IF eax == WM_LBUTTONDOWN
        ; mouse click handling logic here ?
        ; Extract X,Y from lParam
        ; Check if hit target
        jmp WinProcExit
        
    .ELSEIF eax == WM_CLOSE
        INVOKE PostQuitMessage, 0
        jmp WinProcExit
        
    .ELSE
        INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
        jmp WinProcExit
    .ENDIF
    
WinProcExit:
    ret
WinProc ENDP

;-----------------------------------------------------
WinMain PROC
;-----------------------------------------------------
    ; Get a handle to the current process
    INVOKE GetModuleHandle, NULL
    mov hInstance, eax
    mov MainWin.hInstance, eax
    
    ; Load the program's icon and cursor
    INVOKE LoadIcon, NULL, IDI_APPLICATION
    mov MainWin.hIcon, eax
    
    INVOKE LoadCursor, NULL, IDC_ARROW
    mov MainWin.hCursor, eax
    
    ; Register the window class
    INVOKE RegisterClass, ADDR MainWin
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    
    ; Create the application's main window
    INVOKE CreateWindowEx, 0, ADDR className,
           ADDR WindowName, MAIN_WINDOW_STYLE,
           CW_USEDEFAULT, CW_USEDEFAULT, 
           800, 600,
           NULL, NULL, hInstance, NULL
    mov hMainWnd, eax
    
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    
    ; Show and draw the window
    INVOKE ShowWindow, hMainWnd, SW_SHOW
    INVOKE UpdateWindow, hMainWnd
    
    ; Begin the message-handling loop
Message_Loop:
    INVOKE GetMessage, ADDR msg, NULL, NULL, NULL
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop
    
Exit_Program:
    INVOKE ExitProcess, 0
WinMain ENDP

END WinMain

