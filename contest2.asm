; contest2.asm - Aim Trainer Game
; Win32 GUI application
INCLUDE Irvine32.inc
INCLUDE GraphWin.inc
INCLUDELIB gdi32.lib
INCLUDELIB user32.lib

; NOTE: Additional Win32 constants and structures
WM_PAINT = 0Fh
WM_LBUTTONDOWN = 201h
WM_CLOSE = 10h
TRANSPARENT = 1

; Only define PAINTSTRUCT if GraphWin hasn't already defined it
IFNDEF PAINTSTRUCT
PAINTSTRUCT STRUCT
    hdc             DWORD ?
    fErase          DWORD ?
    rcPaint_left    DWORD ?
    rcPaint_top     DWORD ?
    rcPaint_right   DWORD ?
    rcPaint_bottom  DWORD ?
    fRestore        DWORD ?
    fIncUpdate      DWORD ?
    rgbReserved     BYTE 32 DUP(?)
PAINTSTRUCT ENDS
ENDIF

; ========================================================
; SAFE GDI PROTO DECLARATIONS
; ========================================================

IFNDEF CreateSolidBrush
    CreateSolidBrush PROTO, :DWORD
ENDIF

IFNDEF DeleteObject
    DeleteObject PROTO, :DWORD
ENDIF

IFNDEF SelectObject
    SelectObject PROTO, :DWORD, :DWORD
ENDIF

IFNDEF InvalidateRect
    InvalidateRect PROTO, :DWORD, :DWORD, :DWORD
ENDIF

IFNDEF GetDC
    GetDC PROTO, :DWORD
ENDIF

IFNDEF ReleaseDC
    ReleaseDC PROTO, :DWORD, :DWORD
ENDIF

IFNDEF DeleteDC
    DeleteDC PROTO, :DWORD
ENDIF

IFNDEF TextOutA
    TextOutA PROTO, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ENDIF

IFNDEF CreateCompatibleDC
    CreateCompatibleDC PROTO, :DWORD
ENDIF

IFNDEF CreateCompatibleBitmap
    CreateCompatibleBitmap PROTO, :DWORD, :DWORD, :DWORD
ENDIF

IFNDEF BitBlt
    BitBlt PROTO, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ENDIF

IFNDEF Rectangle
    Rectangle PROTO, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ENDIF

IFNDEF BeginPaint
    BeginPaint PROTO, :DWORD, :DWORD
ENDIF

IFNDEF EndPaint
    EndPaint PROTO, :DWORD, :DWORD
ENDIF

IFNDEF Ellipse
    Ellipse PROTO, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ENDIF

; BitBlt constant
SRCCOPY = 00CC0020h

;==================== DATA =======================
.data
    WindowName BYTE "Aim Trainer Game", 0
    className  BYTE "AimTrainerWinClass", 0
    
    ; MainWin WNDCLASS structure
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
    targetMaxHealth     DWORD 3
    targetSize  DWORD 30
    targetActive DWORD 1
    globalx DWORD 100
    globaly DWORD 100
    
    ; Score display
    scoreLabel BYTE "Score: ", 0
    scoreBuffer BYTE 12 DUP(0)
    
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
    mov eax, ecx
    mov ebx, SIZEOF Target
    imul eax, ebx
    add eax, esi
    mov ebx, eax
    
    push ebx
    push edx
    mov eax, nClientWidth
    sub eax, 60
    call randomNum
    add eax, 30
    pop edx
    pop ebx
    mov (Target PTR [ebx]).x, eax
    
    push ebx
    push edx
    mov eax, nClientHeight
    sub eax, 60
    call randomNum
    add eax, 30
    pop edx
    pop ebx
    mov (Target PTR [ebx]).y, eax
    
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
DrawScore PROC
    push eax
    push ecx
    push edx
    push edi
    
    mov edi, OFFSET scoreBuffer
    mov esi, OFFSET scoreLabel
    
CopyLabel:
    mov al, [esi]
    test al, al
    jz DoneLabel
    mov [edi], al
    inc esi
    inc edi
    jmp CopyLabel
    
DoneLabel:
    mov eax, score
    mov ebx, 10
    mov ecx, 0
    
PushDigits:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz PushDigits
    
PopDigits:
    pop eax
    add al, '0'
    mov [edi], al
    inc edi
    loop PopDigits
    
    mov BYTE PTR [edi], 0
    
    mov ecx, edi
    sub ecx, OFFSET scoreBuffer
    
    INVOKE TextOutA, hMemDC, 10, 10, OFFSET scoreBuffer, ecx
    
    pop edi
    pop edx
    pop ecx
    pop eax
    ret
DrawScore ENDP

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
    LOCAL currentTarget:DWORD
    LOCAL healthPercent:DWORD

    invoke CreateSolidBrush, 00000000h
    mov hBrush_BG, eax
    invoke SelectObject, hMemDC, hBrush_BG
    mov hOldBrush, eax
    invoke Rectangle, hMemDC, 0, 0, nClientWidth, nClientHeight
    invoke SelectObject, hMemDC, hOldBrush
    invoke DeleteObject, hBrush_BG
    
    push ecx
    push esi
    push eax
    push ebx
    
    mov ecx, 9
    mov esi, OFFSET targets
    
DrawTargetLoop:
    mov eax, 9
    sub eax, ecx
    mov ebx, SIZEOF Target
    imul eax, ebx
    add eax, esi
    mov currentTarget, eax
    
    mov ebx, currentTarget
    mov eax, (Target PTR [ebx]).x
    mov edx, (Target PTR [ebx]).y
    
    push ecx
    mov ecx, targetSize
    mov L, eax
    sub L, ecx
    mov R, eax
    add R, ecx
    mov T, edx
    sub T, ecx
    mov B, edx
    add B, ecx
    pop ecx
    
    push ecx
    push edx
    
    mov ebx, currentTarget
    mov eax, (Target PTR [ebx]).health
    
    mov ebx, 100
    imul eax, ebx           
    xor edx, edx
    mov ebx, targetMaxHealth
    div ebx                 
    mov healthPercent, eax
    
    cmp healthPercent, 67
    jge ColorGreen
    
    cmp healthPercent, 34
    jge ColorYellow
    
    mov color, 000000FFh
    jmp ColorDone
    
ColorGreen:
    mov color, 0000FF00h
    jmp ColorDone
    
ColorYellow:
    mov color, 0000FFFFh
    
ColorDone:
    pop edx
    pop ecx
    
    push ecx
    invoke CreateSolidBrush, color
    mov hBrush_Target, eax
    
    invoke SelectObject, hMemDC, hBrush_Target
    invoke Ellipse, hMemDC, L, T, R, B
    
    invoke DeleteObject, hBrush_Target
    pop ecx
    
    ; FIX 1: Replace loop with manual jump to solve range issue
    dec ecx
    jz DoneDrawing
    jmp DrawTargetLoop
    
DoneDrawing:
    
    pop ebx
    pop eax
    pop esi
    pop ecx
    
    call DrawScore
    
    ret
DrawAllTargets ENDP

;-----------------------------------------------------
WinProc PROC, hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, localMsg
    
    cmp eax, WM_PAINT
    jne CheckClick      
    jmp HandlePaint     
    
CheckClick:
    cmp eax, WM_LBUTTONDOWN
    jne CheckClose      
    jmp HandleClick     
    
CheckClose:
    cmp eax, WM_CLOSE
    jne DoDefault       
    jmp HandleClose     
    
DoDefault:
    INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
    jmp WinProcExit
    
HandlePaint:
    INVOKE BeginPaint, hWnd, ADDR ps
    mov hdc, eax
    call DrawAllTargets
    INVOKE BitBlt, hdc, 0, 0, nClientWidth, nClientHeight, hMemDC, 0, 0, SRCCOPY
    INVOKE EndPaint, hWnd, ADDR ps
    invoke InvalidateRect, hWnd, NULL, FALSE
    jmp WinProcExit
    
HandleClick:
    pushad
    mov eax, lParam
    movzx ebx, ax
    shr eax, 16
    movzx edx, ax
    
    mov ecx, 9
    mov esi, OFFSET targets
    
CheckHitLoop:
    mov eax, 9
    sub eax, ecx
    push ebx
    mov ebx, SIZEOF Target
    imul eax, ebx
    pop ebx
    add eax, esi
    push eax
    
    mov edi, eax
    mov eax, (Target PTR [edi]).x
    mov edi, (Target PTR [edi]).y
    
    sub eax, ebx
    imul eax, eax
    push eax
    mov eax, edx
    sub eax, edi
    imul eax, eax
    pop edi
    add eax, edi
    
    mov edi, targetSize
    imul edi, edi
    
    ; FIX 3: Replaced jg with jle/jmp pattern
    cmp eax, edi
    jle IsHit           ; If distance <= radius, it is a hit
    jmp NotHit          ; Otherwise, jump far away
    
IsHit:
    ; HIT!
    pop edi
    push ebx
    push ecx
    push edx
    
    mov eax, (Target PTR [edi]).health
    dec eax
    
    cmp eax, 0
    jg StillAlive
    
    ; Target Dead
    mov eax, nClientWidth
    sub eax, 60
    call randomNum
    add eax, 30
    mov (Target PTR [edi]).x, eax
    
    mov eax, nClientHeight
    sub eax, 60
    call randomNum
    add eax, 30
    mov (Target PTR [edi]).y, eax
    
    mov eax, targetMaxHealth
    mov (Target PTR [edi]).health, eax
    inc score
    jmp DoneDamage
    
StillAlive:
    mov (Target PTR [edi]).health, eax
    
DoneDamage:
    pop edx
    pop ecx
    pop ebx
    jmp HitDetected
    
NotHit:
    pop eax
    ; FIX 2: Replace loop with manual jump to solve range issue
    dec ecx
    jz HitDetected      ; If loop finishes (ecx=0), no hit was found, exit
    jmp CheckHitLoop    ; Otherwise continue loop
    
HitDetected:
    popad
    jmp WinProcExit
    
HandleClose:
    INVOKE SelectObject, hMemDC, hOldBitmap
    INVOKE DeleteObject, hBitmap
    INVOKE DeleteDC, hMemDC
    INVOKE PostQuitMessage, 0
    jmp WinProcExit
    
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
    
    INVOKE GetDC, hMainWnd
    mov hdc, eax
    INVOKE CreateCompatibleDC, hdc
    mov hMemDC, eax
    INVOKE CreateCompatibleBitmap, hdc, nClientWidth, nClientHeight
    mov hBitmap, eax
    INVOKE SelectObject, hMemDC, hBitmap
    mov hOldBitmap, eax
    INVOKE ReleaseDC, hMainWnd, hdc
    
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
