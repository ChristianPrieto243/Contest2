#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <windows.h>
#include <windowsx.h>

#define min(a,b) (((a) < (b)) ? (a) : (b))
#define max(a,b) (((a) > (b)) ? (a) : (b))
// COMPILE : gcc Experimental.c -o Experiment -mwindows

// GUI
RECT rect;
unsigned int AIcolor;
boardstate mainboard;
// Window procedure function prototype
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
     // Allocate a console window
    AllocConsole();
    // Redirect standard output to the console
    freopen("CONOUT$", "w", stdout);
    freopen("CONIN$", "r", stdin);

    srand(time(NULL));
    const char CLASS_NAME[] = "Project2";
