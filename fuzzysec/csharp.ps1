# int WINAPI MessageBox(
#   _In_opt_ HWND    hWnd,
#   _In_opt_ LPCTSTR lpText,
#   _In_opt_ LPCTSTR lpCaption,
#   _In_     UINT    uType
# );

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class User32
{
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern bool MessageBox(
        IntPtr hWnd,    /// Parent window handle
        String text,    /// Text message display
        String caption, /// Window caption
        int options     /// MessageBox type
    );
}
"@

[void] [User32]::MessageBox(0, "Hi mom!", "Greetings", 0)