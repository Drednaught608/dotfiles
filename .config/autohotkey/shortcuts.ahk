#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

^+t:: {
    Run("wt.exe")
}

^+q:: {
    Run("taskkill /f /im explorer.exe", , "Hide")
    Sleep(500)
    Run("explorer.exe")
}

