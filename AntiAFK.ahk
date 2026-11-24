#Requires AutoHotkey v2.0
#SingleInstance Force
; @version 2.1.0

INI_FILE := A_ScriptDir "\settings.ini"
intervalSec := IniRead(INI_FILE, "AntiAFK", "Interval", "30") + 0
chatMode    := IniRead(INI_FILE, "AntiAFK", "ChatAntiAFK", 0) + 0
hotkeyStr   := IniRead(INI_FILE, "AntiAFK", "Hotkey", "F8")
if (intervalSec < 5)
    intervalSec := 30
if (hotkeyStr = "")
    hotkeyStr := "F8"

Toggle := false

try {
    Hotkey(hotkeyStr, ToggleAFK)
} catch {
    Hotkey("F8", ToggleAFK)
    hotkeyStr := "F8"
}

ToggleAFK(*) {
    global Toggle
    Toggle := !Toggle
    ToolTip(Toggle ? "Анти-АФК: ВКЛ" : "Анти-АФК: ВЫКЛ", 100, 100)
    SetTimer(() => ToolTip(), -1500)
    if Toggle
        SetTimer(DoAction, -100)
    else
        SetTimer(DoAction, 0)
}

DoAction() {
    global Toggle, chatMode, intervalSec
    if !Toggle
        return
    if (chatMode) {
        chars := [".", ",", " ", "!", "?"]
        SendInput(chars[Random(1, chars.Length)])
    } else {
        keys := ["w", "a", "s", "d"]
        key := keys[Random(1, keys.Length)]
        Send("{" key " down}")
        Sleep(Random(50, 400))
        Send("{" key " up}")
    }
    if Toggle
        SetTimer(DoAction, -Random(intervalSec * 800, intervalSec * 1200))
}

ToolTip("Анти-АФК загружен. Клавиша: " hotkeyStr, 100, 100)
SetTimer(() => ToolTip(), -2500)