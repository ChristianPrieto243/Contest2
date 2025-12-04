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
CreateSolidBrush PROTO, color:DWORD
DeleteObject PROTO, hObject:DWORD
SelectObject PROTO, hdc:DWORD, hObject:DWORD
InvalidateRect PROTO, hWnd:DWORD, lpRect:DWORD, bErase:DWORD
GetDC PROTO, hWnd:DWORD
ReleaseDC PROTO, hWnd:DWORD, hdc:DWORD
DeleteDC PROTO, hdc:DWORD

; NOTE: Double buffering functions not learned in class
; Learned from MSDN documentation to prevent flicker
CreateCompatibleDC PROTO, hdc:DWORD
CreateCompatibleBitmap PROTO, hdc:DWORD, nWidth:DWORD, nHeight:DWORD
BitBlt PROTO, hdcDest:DWORD, xDest:DWORD, yDest:DWORD, nWidth:DWORD, nHeight:DWORD, hdcSrc:DWORD, xSrc:DWORD, ySrc:DWORD, rop:DWORD
Rectangle PROTO, hdc:DWORD, nLeft:DWORD, nTop:DWORD, nRight:DWORD, nBottom:DWORD

BeginPaint PROTO, hwnd:DWORD, lpPaint:DWORD
EndPaint PROTO, hwnd:DWORD, lpPaint:DWORD
Ellipse PROTO, hdc:DWORD, nLeft:DWORD, nTop:DWORD, nRight:DWORD, nBottom:DWORD

; BitBlt constant
SRCCOPY = 00CC0020h

;==================== DATA =======================
.data
    WindowName BYTE "Aim Trainer Game", 0
    className  BYTE "AimTrainerWinClass", 0
    
    MainWin WNDCLASS <NULL, WinProc, NULL, NULL, NULL, NULL, NULL, \
                      COLOR_WINDOW, NULL, className>
    
    msg MSGStruct <>
    hMainWnd DWORD ?
    hInstance DWORD ?
    
    ; Window dimensions
    nClientWidth DWORD 800
    nClientHeight DWORD 600
    
    ; Double buffering variables
    hMemDC DWORD ?
    hBitmap DWORD ?
    hOldBitmap DWORD ?
    
    ; Game state variables
    score       DWORD 0
    targetCount     DWORD 100
    targetMaxHealth    DWORD 3
    targetSize  DWORD 30
    targetActive DWORD 1
    globalx DWORD 100
    globaly DWORD 100
    
    Target STRUCT
        x DWORD 0
        y DWORD 0
        health DWORD 3
    Target ENDS
    targets Target 9 DUP(<>)
    
    ps PAINTSTRUCT <>
    hdc DWORD ?

;=================== CODE =========================
.code

;-----------------------------------------------------
randomNum PROC
    ; Input: EAX = max value
    ; Output: EAX = random number from 0 to (input-1)
    ; Uses Irvine32 RandomRange (chapter 9)
    call RandomRange
    ret
randomNum ENDP

;-----------------------------------------------------
initializeTargets PROC
    push ecx
    push esi
    push edx
    push eax
    push ebx
    
    mov ecx, 0
    mov edx, targetMaxHealth
    mov esi, OFFSET targets
    
TargetLoop:
    ; Calculate address of current target
    mov eax, ecx
    mov ebx, SIZEOF Target
    imul eax, ebx
    add eax, esi
    mov ebx, eax
    
    ; Generate random X
    push ebx
    push edx
    mov eax, nClientWidth
    sub eax, 60
    call randomNum
    add eax, 30
    pop edx
    pop ebx
    mov (Target PTR [ebx]).x, eax
    
    ; Generate random Y
    push ebx
    push edx
    mov eax, nClientHeight
    sub eax, 60
    call randomNum
    add eax, 30
    pop edx
    pop ebx
    mov (Target PTR [ebx]).y, eax
    
    ; Set health
    mov (Target PTR [ebx]).health, edx
    
    inc ecx
    cmp ecx, 9
    jl TargetLoop
    
    pop ebx
    pop eax
    pop edx
    pop esi
    pop ecx
    ret
initializeTargets ENDP

;-----------------------------------------------------
DrawAllTargets PROC
    LOCAL L:DWORD
    LOCAL R:DWORD
    LOCAL T:DWORD
    LOCAL B:DWORD
    LOCAL color:DWORD
    LOCAL hBrush_Target:DWORD
    LOCAL hBrush_BG:DWORD
    LOCAL hOldBrush:DWORD

    push eax
    push ecx
    
    mov ecx, targetSize
    mov eax, globalx
    mov L, eax
    sub L, ecx
    mov R, eax
    add R, ecx
    mov eax, globaly
    mov T, eax
    sub T, ecx
    mov B, eax
    add B, ecx
    
    pop ecx
    pop eax
    
    mov color, 000000FFh
    
    ; Fill background black
    invoke CreateSolidBrush, 00000000h
    mov hBrush_BG, eax
    invoke SelectObject, hMemDC, hBrush_BG
    mov hOldBrush, eax
    invoke Rectangle, hMemDC, 0, 0, nClientWidth, nClientHeight
    
    ; Create target brush
    invoke CreateSolidBrush, color
    mov hBrush_Target, eax
    invoke SelectObject, hMemDC, hBrush_Target
    
    ; Draw test circle
    invoke Ellipse, hMemDC, L, T, R, B
    
    ; Restore and cleanup
    invoke SelectObject, hMemDC, hOldBrush
    invoke DeleteObject, hBrush_Target
    invoke DeleteObject, hBrush_BG
    
    ret
DrawAllTargets ENDP

;-----------------------------------------------------
WinProc PROC, hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, localMsg
    
    .IF eax == WM_PAINT
        INVOKE BeginPaint, hWnd, ADDR ps
        mov hdc, eax
        
        call DrawAllTargets
        
        INVOKE BitBlt, hdc, 0, 0, nClientWidth, nClientHeight, hMemDC, 0, 0, SRCCOPY
        
        INVOKE EndPaint, hWnd, ADDR ps
        
        invoke InvalidateRect, hWnd, NULL, FALSE
        jmp WinProcExit
        
    .ELSEIF eax == WM_LBUTTONDOWN
        pushad
        mov eax, lParam
        movzx ecx, ax
        mov globalx, ecx
        shr eax, 16
        movzx ecx, ax
        mov globaly, ecx
        popad
        jmp WinProcExit
        
    .ELSEIF eax == WM_CLOSE
        INVOKE SelectObject, hMemDC, hOldBitmap
        INVOKE DeleteObject, hBitmap
        INVOKE DeleteDC, hMemDC
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
    INVOKE GetModuleHandle, NULL
    mov hInstance, eax
    mov MainWin.hInstance, eax
    
    INVOKE LoadIcon, NULL, IDI_APPLICATION
    mov MainWin.hIcon, eax
    
    INVOKE LoadCursor, NULL, IDC_ARROW
    mov MainWin.hCursor, eax
    
    INVOKE RegisterClass, ADDR MainWin
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    
    INVOKE CreateWindowEx, 0, ADDR className,
           ADDR WindowName, MAIN_WINDOW_STYLE,
           CW_USEDEFAULT, CW_USEDEFAULT, 
           nClientWidth, nClientHeight,
           NULL, NULL, hInstance, NULL
    mov hMainWnd, eax
    
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    
    INVOKE ShowWindow, hMainWnd, SW_SHOW
    INVOKE UpdateWindow, hMainWnd
    
    ; Set up double buffering
    INVOKE GetDC, hMainWnd
    mov hdc, eax
    
    INVOKE CreateCompatibleDC, hdc
    mov hMemDC, eax
    
    INVOKE CreateCompatibleBitmap, hdc, nClientWidth, nClientHeight
    mov hBitmap, eax
    
    INVOKE SelectObject, hMemDC, hBitmap
    mov hOldBitmap, eax
    
    INVOKE ReleaseDC, hMainWnd, hdc
    
    ; Initialize all targets
    call initializeTargets
    
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
