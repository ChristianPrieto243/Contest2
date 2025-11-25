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
     // Define a window class
    WNDCLASS wc = {0};
    wc.lpfnWndProc = WindowProc;         // Window procedure function
    wc.hInstance = hInstance;           // Handle to the application instance
    wc.lpszClassName = CLASS_NAME;      // Name of the window class
    // Register the window class
    RegisterClass(&wc);
    // Create the window
    HWND hwnd = CreateWindowEx(
        0,                              // Optional window styles
        CLASS_NAME,                     // Window class name
        "Othello",                      // Window title
        WS_OVERLAPPEDWINDOW,            // Window style
        CW_USEDEFAULT, CW_USEDEFAULT,   // Position
        800, 800,                       // Size
        NULL,                           // Parent window
        NULL,                           // Menu
        hInstance,                      // Instance handle
        NULL                            // Additional application data
    );
     if (!hwnd) {
        return 0; // If the window creation failed
    }
     // Show the window
    ShowWindow(hwnd, nCmdShow);

    // Run the message loop
    MSG msg = {0};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg); // pass to WindowProc
    }

    return 0;
}
