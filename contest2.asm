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
WM_KEYDOWN = 100h
VK_R = 52h          ; 'R' key
TRANSPARENT = 1

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

IFNDEF GetTickCount
    GetTickCount PROTO
ENDIF

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
    
    nClientWidth DWORD 1920
    nClientHeight DWORD 1080
    
    hMemDC DWORD ?
    hBitmap DWORD ?
    hOldBitmap DWORD ?
    
    score       DWORD 0
    targetCount     DWORD 100
    targetMaxHealth     DWORD 4
    targetSize  DWORD 10
    targetActive DWORD 1
    globalx DWORD 100
    globaly DWORD 100
    
    ; Game State
    gameActive DWORD 1
    
    ; Timer variables
    roundStartTime DWORD 0
    currentTime DWORD 0
    elapsedSeconds DWORD 0
    remainingSeconds DWORD 0
    roundDuration DWORD 30
    
    scoreLabel BYTE "Score: ", 0
    scoreBuffer BYTE 12 DUP(0)
    
    timerLabel BYTE "Time: ", 0
    timerBuffer BYTE 12 DUP(0)
    
    roundOverMsg BYTE "Round Over! Press R to restart", 0
    roundOverBuffer BYTE 40 DUP(0)
    
    Target STRUCT
        x DWORD 0
        y DWORD 0
        health DWORD 4
    Target ENDS
    targets Target 15 DUP(<>)
    
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
    cmp ecx, 15
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
DrawTimer PROC
    push eax
    push ebx
    push ecx
    push edx
    push edi
    
    INVOKE GetTickCount
    mov currentTime, eax
    
    mov eax, currentTime
    mov ebx, roundStartTime
    sub eax, ebx
    mov ebx, 1000
    xor edx, edx
    div ebx
    mov elapsedSeconds, eax
    
    mov eax, roundDuration
    sub eax, elapsedSeconds
    
    cmp eax, 0
    jge TimePositive
    mov eax, 0
    
TimePositive:
    mov remainingSeconds, eax
    
    cmp eax, 0
    jne TimerStillGoing
    
    ; Time's up! End the round
    mov gameActive, 0
    
TimerStillGoing:
    
    mov edi, OFFSET timerBuffer
    mov esi, OFFSET timerLabel
    
CopyTimerLabel:
    mov al, [esi]
    test al, al
    jz DoneTimerLabel
    mov [edi], al
    inc esi
    inc edi
    jmp CopyTimerLabel
    
DoneTimerLabel:
    mov eax, remainingSeconds
    mov ebx, 10
    mov ecx, 0
    
PushTimerDigits:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz PushTimerDigits
    
PopTimerDigits:
    pop eax
    add al, '0'
    mov [edi], al
    inc edi
    loop PopTimerDigits
    
    mov BYTE PTR [edi], 0
    
    mov ecx, edi
    sub ecx, OFFSET timerBuffer
    
    mov eax, nClientWidth
    sub eax, 100
    
    INVOKE TextOutA, hMemDC, eax, 10, OFFSET timerBuffer, ecx
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
DrawTimer ENDP

;-----------------------------------------------------
DrawRoundOver PROC
    push eax
    push ecx
    push edx
    
    mov edi, OFFSET roundOverBuffer
    mov esi, OFFSET roundOverMsg
    
    CopyRoundMsg:
    mov al, [esi]
    test al, al
    jz DoneRoundMsg
    mov [edi], al
    inc esi
    inc edi
    jmp CopyRoundMsg
    
    DoneRoundMsg:
    mov BYTE PTR [edi], 0
    
    mov ecx, edi
    sub ecx, OFFSET roundOverBuffer
    
    mov eax, nClientWidth
    shr eax, 1
    sub eax, 120
    
    mov edx, nClientHeight
    shr edx, 1
    
    INVOKE TextOutA, hMemDC, eax, edx, OFFSET roundOverBuffer, ecx
    
    pop edx
    pop ecx
    pop eax
    ret
DrawRoundOver ENDP

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
    
    mov ecx, 15
    mov esi, OFFSET targets
    
DrawTargetLoop:
    mov eax, 15
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
    imul ecx, (Target PTR [ebx]).health
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
    imul eax, 255     
    cdq              
    mov ecx, 100    
    idiv ecx  
    mov ecx, 255
    sub ecx, eax
    mov eax, ecx
    mov healthPercent, eax
    
    mov eax, 255
    sub eax, healthPercent
    shl eax, 8
    add eax, healthPercent
    
    mov color, eax
    pop edx
    pop ecx
    
    push ecx
    invoke CreateSolidBrush, color
    mov hBrush_Target, eax
    
    invoke SelectObject, hMemDC, hBrush_Target
    invoke Ellipse, hMemDC, L, T, R, B
    
    invoke DeleteObject, hBrush_Target
    pop ecx
    
    dec ecx
    jz DoneDrawing
    jmp DrawTargetLoop
    
DoneDrawing:
    pop ebx
    pop eax
    pop esi
    pop ecx
    
    call DrawScore
    call DrawTimer
    
    cmp gameActive, 0
    jne SkipRoundOver
    call DrawRoundOver
    
SkipRoundOver:
    
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
    jne CheckKeyDown
    jmp HandleClose     
    
CheckKeyDown:
    cmp eax, WM_KEYDOWN
    jne DoDefault
    jmp HandleKeyDown
    
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
    cmp gameActive, 0
    je ClickIgnored
    
    pushad
    mov eax, lParam
    movzx ebx, ax
    shr eax, 16
    movzx edx, ax
    
    mov ecx, 15
    mov esi, OFFSET targets
    
CheckHitLoop:
    mov eax, 15
    sub eax, ecx
    push ebx
    mov ebx, SIZEOF Target
    imul eax, ebx
    pop ebx
    add eax, esi
    push eax
    
    mov edi, eax
    mov eax, (Target PTR [edi]).x
    push ecx
    mov ecx, (Target PTR [edi]).health
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
    imul edi, ecx
    imul edi, edi
    pop ecx
    
    cmp eax, edi
    jle IsHit
    jmp NotHit
    
IsHit:
    pop edi
    push ebx
    push ecx
    push edx
    
    mov eax, (Target PTR [edi]).health
    dec eax
    
    cmp eax, 0
    jg StillAlive
    
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
    dec ecx
    jz HitDetected
    jmp CheckHitLoop
    
HitDetected:
    popad
    jmp WinProcExit
    
ClickIgnored:
    jmp WinProcExit

HandleClose:
    INVOKE SelectObject, hMemDC, hOldBitmap
    INVOKE DeleteObject, hBitmap
    INVOKE DeleteDC, hMemDC
    INVOKE PostQuitMessage, 0
    jmp WinProcExit
    
HandleKeyDown:
    mov eax, wParam
    cmp eax, VK_R
    jne WinProcExit
    
    mov score, 0
    mov gameActive, 1
    
    INVOKE GetTickCount
    mov roundStartTime, eax
    
    call initializeTargets
    
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
    
    ; =========================================================
    ; FIX: Initialize State BEFORE Showing Window
    ; =========================================================
    
    ; 1. Start the clock
    INVOKE GetTickCount
    mov roundStartTime, eax
    
    ; 2. Initialize targets
    call initializeTargets
    
    ; 3. Create the window
    INVOKE CreateWindowEx, 0, ADDR className,
           ADDR WindowName, MAIN_WINDOW_STYLE,
           CW_USEDEFAULT, CW_USEDEFAULT, 
           nClientWidth, nClientHeight,
           NULL, NULL, hInstance, NULL
    mov hMainWnd, eax
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    
    ; 4. Show Window (Triggers first WM_PAINT)
    INVOKE ShowWindow, hMainWnd, SW_SHOW
    INVOKE UpdateWindow, hMainWnd
    
    ; 5. Setup Double Buffering
    INVOKE GetDC, hMainWnd
    mov hdc, eax
    INVOKE CreateCompatibleDC, hdc
    mov hMemDC, eax
    INVOKE CreateCompatibleBitmap, hdc, nClientWidth, nClientHeight
    mov hBitmap, eax
    INVOKE SelectObject, hMemDC, hBitmap
    mov hOldBitmap, eax
    INVOKE ReleaseDC, hMainWnd, hdc
    
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

