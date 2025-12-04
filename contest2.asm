; contest2.asm - Aim Trainer Game
; Win32 GUI application 

.386
.model flat, stdcall
option casemap:none

; Standard includes from Irvine32 environment
INCLUDE windows.inc
INCLUDE user32.inc
INCLUDE kernel32.inc
INCLUDE Irvine32.inc

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

