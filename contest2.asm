; contest2.asm - Aim Trainer Game
; Win32 GUI application using GraphWin.inc 
INCLUDE Irvine32.inc
INCLUDE GraphWin.inc
INCLUDELIB gdi32.lib

; NOTE: Additional Win32 constants and structures not in GraphWin.inc
; Learned from MSDN documentation
WM_PAINT = 0Fh

PAINTSTRUCT STRUCT
    hdc         DWORD ?
    fErase      DWORD ?
    rcPaint_left   DWORD ?
    rcPaint_top    DWORD ?
    rcPaint_right  DWORD ?
    rcPaint_bottom DWORD ?
    fRestore    DWORD ?
    fIncUpdate  DWORD ?
    rgbReserved BYTE 32 DUP(?)
PAINTSTRUCT ENDS

; External GDI function declarations
BeginPaint PROTO, hwnd:DWORD, lpPaint:DWORD
EndPaint PROTO, hwnd:DWORD, lpPaint:DWORD
Ellipse PROTO, hdc:DWORD, left:DWORD, top:DWORD, right:DWORD, bottom:DWORD

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
    
    ; Target structure definition
    Target STRUCT
        x DWORD 0      ; X position
        y DWORD 0      ; Y position
        health WORD 3  ; Health points
    Target ENDS
    targets Target 9 DUP(<>)  ; Array of 9 targets
    
    ; NOTE: GDI drawing not learned in class
    ; Learned from MSDN documentation for Ellipse and BeginPaint/EndPaint
    ps PAINTSTRUCT <>  ; Paint structure
    hdc DWORD ?        ; Device context handle (global for DrawAllTargets)

;=================== CODE =========================
.code

;-----------------------------------------------------
DrawAllTargets PROC
; Draws all active targets on the window
     invoke BeginPaint, hWnd, addr ps
    mov hdc, eax

    LOCAL x:DWORD
    LOCAL y:DWORD
    LOCAL color:DWORD
    LOCAL hBrush:HBRUSH
    LOCAL hOldBrush:HGDIOBJ

    mov x, 150
    mov y, 150
    mov color, RGB(255,0,0)        ; red dot

    ; Create solid brush for the fill
    invoke CreateSolidBrush, color
    mov hBrush, eax

    ; Select brush
    invoke SelectObject, hdc, hBrush
    mov hOldBrush, eax

    ; Draw a 30x30 ellipse
    invoke Ellipse, hdc, x, y, x+30, y+30

    ; Restore old brush
    invoke SelectObject, hdc, hOldBrush

    ; Delete new brush
    invoke DeleteObject, hBrush
    
    ; TODO: Loop through targets array and draw all

    ; TODO: Change color based on target health
    
    ; TODO: Add score display text
    ; TODO: Add timer display text
    
    ret
DrawAllTargets ENDP

;-----------------------------------------------------
WinProc PROC, hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler
;-----------------------------------------------------
    mov eax, localMsg
    
    .IF eax == WM_PAINT
        ; NOTE: BeginPaint/EndPaint and Ellipse not learned in class
        ; Learned from MSDN Win32 GDI documentation
        
        ; Begin painting - get device context
        INVOKE BeginPaint, hWnd, ADDR ps
        mov hdc, eax
        
        ; Call our drawing function
        call DrawAllTargets
        
        ; End painting - release device context
        INVOKE EndPaint, hWnd, ADDR ps
        jmp WinProcExit
        
    .ELSEIF eax == WM_LBUTTONDOWN
        ; Handle left mouse button click
        ; Extract X,Y from lParam
        pushad
        mov eax, lParam  ; Low word = X, High word = Y
        
        ; TODO: Check if hit target (distance formula)
        ; TODO: Update targets array (swap-and-pop if killed)
        ; TODO: Call InvalidateRect to trigger redraw
        
        popad
        jmp WinProcExit
        
    .ELSEIF eax == WM_CLOSE
        ; Handle window close
        INVOKE PostQuitMessage, 0
        jmp WinProcExit
        
    .ELSE
        ; Default handling for all other messages
        INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
        jmp WinProcExit
    .ENDIF
    
WinProcExit:
    ret
WinProc ENDP

;-----------------------------------------------------
WinMain PROC
; Main entry point
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
    
    ; Create the application's main window (800x600)
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



