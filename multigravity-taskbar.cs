// Taskbar identity helper, compiled at build time with the WPF effects.
// Avoid PowerShell Add-Type -TypeDefinition at desktop runtime.
using System;
using System.Runtime.InteropServices;

public static class MultigravityTaskbar {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appID);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hwnd, int message, IntPtr wparam, IntPtr lparam);
}
