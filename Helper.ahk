#Requires AutoHotkey v2.0
#SingleInstance Force
; @version 1.0.0

INI_FILE := A_ScriptDir "\settings.ini"
bindings := IniRead(INI_FILE, "Helpers", "Bindings", "")
if (bindings = "")
    bindings := "F1=/me поправил бронежилет{Enter}`nF2=/do Бронежилет на груди.{Enter}"

boundCount := 0
boundKeys := []

Loop Parse, bindings, "`n", "`r" {
    line := Trim(A_LoopField)
    if (line = "")
        continue
    eqPos := InStr(line, "=")
    if (eqPos < 2)
        continue
    keyName := Trim(SubStr(line, 1, eqPos - 1))
    text    := SubStr(line, eqPos + 1)
    if (keyName = "" || text = "")
        continue
    try {
        Hotkey(keyName, SendBinding.Bind(text), "On")
        boundCount++
        boundKeys.Push(keyName)
    } catch as e {
        OutputDebug("Helpers: не удалось забиндить " keyName " — " e.Message)
    }
}

SendBinding(text, *) {
    oldClip := ClipboardAll()
    A_Clipboard := text
    ; Send поддерживает {Enter}, {Tab}, {Esc} внутри текста
    Send(text)
    Sleep(80)
    A_Clipboard := oldClip
}

; Показать шпаргалку при старте
if (boundCount > 0) {
    ToolTip("Хелперка активна.`nПривязок: " boundCount "`n" JoinKeys(), 100, 100)
    SetTimer(() => ToolTip(), -4000)
}

JoinKeys() {
    global boundKeys
    s := ""
    for k in boundKeys
        s .= k " "
    return Trim(s)
}
