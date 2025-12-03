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