#Requires AutoHotkey v2.0
#SingleInstance Force

; @version 1.1.1

GITHUB_REPO := "artemnach2012/scripts_update"
RAW_BASE := "https://raw.githubusercontent.com/" GITHUB_REPO "/main/"
INI_FILE := A_ScriptDir "\settings.ini"

; ==================== СОЗДАНИЕ ФАЙЛА НАСТРОЕК ====================
; Гарантированно создаем settings.ini, если его ещё нет
if !FileExist(INI_FILE) {
    try {
        fh := FileOpen(INI_FILE, "w", "UTF-8")
        fh.Close()
    }
}

; ==================== ПАЛИТРА ЦВЕТОВ ====================
CLR_BG        := "141417" ; Основной фон
CLR_CARD      := "1E1E24" ; Фон карточек и шапки
CLR_INPUT     := "272730" ; Фон полей ввода
CLR_TEXT      := "F4F4F6" ; Основной текст
CLR_MUTED     := "8E8E9A" ; Второстепенный текст
CLR_ACCENT    := "3B82F6" ; Синий (Обновить)
CLR_SUCCESS   := "10B981" ; Зеленый (Старт / Активен)
CLR_DANGER    := "EF4444" ; Красный (Стоп / Закрыть)
CLR_DISABLED  := "2C2C35" ; Неактивная кнопка

scripts := Map()
scripts["Launcher"]    := { name: "Лаунчер",        file: "Launcher.ahk",    localVer: "0.0.0", isLauncher: true }
scripts["ArmyReports"] := { name: "Армия докладов", file: "ArmyReports.ahk", localVer: "0.0.0" }
scripts["AntiAFK"]     := { name: "Анти-АФК",       file: "AntiAFK.ahk",     localVer: "0.0.0" }
scripts["MoscowLive"]  := { name: "Москва-Live",    file: "MoscowLive.ahk",  localVer: "0.0.0" }
scripts["Helpers"]     := { name: "Хелперка",       file: "Helpers.ahk",     localVer: "0.0.0" }

; ==================== СОЗДАНИЕ ОКНА ====================
mainGui := Gui("-Caption +Border", "Панель управления скриптами")
mainGui.BackColor := CLR_BG
mainGui.SetFont("s10 c" CLR_TEXT, "Segoe UI")

; Скругление углов (работает в Windows 11)
try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", mainGui.Hwnd, "Int", 33, "Int*", 2, "Int", 4)

; Кастомная шапка (перетаскивание окна + кнопка закрытия)
headerBg := mainGui.Add("Text", "x0 y0 w650 h42 Background" CLR_CARD, "")
headerBg.OnEvent("Click", (*) => PostMessage(0xA1, 2,,, mainGui))

mainGui.SetFont("s11 Bold c" CLR_TEXT)
titleTxt := mainGui.Add("Text", "x18 y10 w400 BackgroundTrans", "⚡ AHK SCRIPT LAUNCHER")
titleTxt.OnEvent("Click", (*) => PostMessage(0xA1, 2,,, mainGui))

mainGui.SetFont("s8 Bold c" CLR_DANGER)
mainGui.Add("Text", "x475 y13 w65 Center BackgroundTrans", "BETA")

; Кнопки свернуть и закрыть
btnMin := CreateFlatBtn(mainGui, 560, 6, 35, 30, "—", CLR_CARD, CLR_MUTED)
btnMin.OnEvent("Click", (*) => mainGui.Minimize())

btnClose := CreateFlatBtn(mainGui, 600, 6, 40, 30, "✕", CLR_CARD, CLR_TEXT)
btnClose.OnEvent("Click", (*) => ExitApp())

; ==================== НАВИГАЦИЯ (КАСТОМНЫЕ ВКЛАДКИ) ====================
navButtons := Map()
tabPages := Map()
activeTab := "Main"

navItems := [
    { key: "Main",        label: "Главная",        x: 18,  w: 85 },
    { key: "ArmyReports", label: "Армия докладов", x: 108, w: 125 },
    { key: "AntiAFK",     label: "Анти-АФК",       x: 238, w: 90 },
    { key: "MoscowLive",  label: "Москва-Live",    x: 333, w: 105 },
    { key: "Helpers",     label: "Хелперка",       x: 443, w: 90 }
]

for item in navItems {
    btn := CreateFlatBtn(mainGui, item.x, 54, item.w, 30, item.label, CLR_CARD, CLR_MUTED)
    btn.OnEvent("Click", SwitchTab.Bind(item.key))
    navButtons[item.key] := btn
}

; Разделитель под вкладками
mainGui.Add("Text", "x18 y92 w614 h1 Background" CLR_INPUT)

; ==================== ВКЛАДКА 1: ГЛАВНАЯ ====================
mainControls := []

mainGui.SetFont("s9 Bold c" CLR_MUTED)
mainControls.Push(mainGui.Add("Text", "x30 y106 w150", "СКРИПТ"))
mainControls.Push(mainGui.Add("Text", "x195 y106 w70", "ВЕРСИЯ"))
mainControls.Push(mainGui.Add("Text", "x280 y106 w105", "СТАТУС"))
mainControls.Push(mainGui.Add("Text", "x405 y106 w210", "УПРАВЛЕНИЕ"))

guiControls := Map()
yPos := 132

for key, info in scripts {
    isLauncher := info.HasOwnProp("isLauncher") && info.isLauncher

    ; Подложка строки (карточка)
    card := mainGui.Add("Text", "x18 y" (yPos - 6) " w614 h38 Background" CLR_CARD)
    mainControls.Push(card)

    mainGui.SetFont("s10 Bold c" CLR_TEXT)
    lblName := mainGui.Add("Text", "x30 y" (yPos + 3) " w155 BackgroundTrans", info.name)
    mainControls.Push(lblName)

    mainGui.SetFont("s9 Norm c" CLR_ACCENT)
    verText := mainGui.Add("Text", "x195 y" (yPos + 4) " w70 BackgroundTrans", "—")
    mainControls.Push(verText)

    mainGui.SetFont("s9 Bold c" (isLauncher ? CLR_SUCCESS : CLR_MUTED))
    statusText := mainGui.Add("Text", "x280 y" (yPos + 4) " w115 BackgroundTrans", isLauncher ? "● Активен" : "● Остановлен")
    mainControls.Push(statusText)

    if isLauncher {
        btnStart := ""
        btnStop := ""
        btnUpdate := CreateFlatBtn(mainGui, 405, yPos - 1, 212, 28, "↻ Обновить лаунчер", CLR_ACCENT, CLR_TEXT)
    } else {
        btnStart  := CreateFlatBtn(mainGui, 405, yPos - 1, 68, 28, "▶ Старт", CLR_SUCCESS, CLR_TEXT)
        btnStop   := CreateFlatBtn(mainGui, 478, yPos - 1, 66, 28, "⏹ Стоп", CLR_DISABLED, CLR_MUTED)
        btnStop.Enabled := false
        btnUpdate := CreateFlatBtn(mainGui, 549, yPos - 1, 68, 28, "↻ Обн.", CLR_ACCENT, CLR_TEXT)
    }

    if btnStart != ""
        mainControls.Push(btnStart)
    if btnStop != ""
        mainControls.Push(btnStop)
    mainControls.Push(btnUpdate)

    guiControls[key] := {
        verText: verText,
        statusText: statusText,
        btnStart: btnStart,
        btnStop: btnStop,
        btnUpdate: btnUpdate
    }

    if !isLauncher {
        btnStart.OnEvent("Click", StartScript.Bind(key))
        btnStop.OnEvent("Click", StopScript.Bind(key))
    }
    btnUpdate.OnEvent("Click", UpdateScript.Bind(key))

    yPos += 44
}

btnUpdateAll := CreateFlatBtn(mainGui, 18, yPos + 8, 200, 34, "⚡ Обновить все скрипты", CLR_ACCENT, CLR_TEXT)
btnUpdateAll.OnEvent("Click", UpdateAllScripts)
mainControls.Push(btnUpdateAll)

tabPages["Main"] := mainControls

; ==================== ВКЛАДКИ НАСТРОЕК ====================
configFields := Map()

for key, info in scripts {
    if info.HasOwnProp("isLauncher") && info.isLauncher
        continue

    pageCtrls := []
    pageCtrls.Push(mainGui.Add("Text", "x18 y106 w614 h250 Background" CLR_CARD))

    mainGui.SetFont("s12 Bold c" CLR_TEXT)
    pageCtrls.Push(mainGui.Add("Text", "x35 y120 w550 BackgroundTrans", "Параметры: " info.name))

    mainGui.SetFont("s9 Norm c" CLR_MUTED)
    pageCtrls.Push(mainGui.Add("Text", "x35 y145 w550 BackgroundTrans", "Изменения сохраняются в settings.ini и автоматически перезапускают скрипт."))

    mainGui.SetFont("s10 Norm c" CLR_TEXT)

    if key == "ArmyReports" {
        cfg1 := mainGui.Add("CheckBox", "x35 y185 w350 c" CLR_TEXT " Background" CLR_CARD, "Включить автоматический доклад по таймеру")
        cfg1.Value := IniRead(INI_FILE, "ArmyReports", "AutoReport", 0)
        pageCtrls.Push(cfg1)

        pageCtrls.Push(mainGui.Add("Text", "x35 y225 BackgroundTrans", "Клавиша для ручного доклада:"))
        cfg2 := mainGui.Add("Edit", "x255 y222 w100 -E0x200 Background" CLR_INPUT " c" CLR_TEXT, IniRead(INI_FILE, "ArmyReports", "Hotkey", "F8"))
        pageCtrls.Push(cfg2)

        configFields["ArmyReports"] := [cfg1, cfg2]
    }
    else if key == "AntiAFK" {
        pageCtrls.Push(mainGui.Add("Text", "x35 y185 BackgroundTrans", "Интервал между действиями (в секундах):"))
        cfg1 := mainGui.Add("Edit", "x325 y182 w80 -E0x200 Number Background" CLR_INPUT " c" CLR_TEXT, IniRead(INI_FILE, "AntiAFK", "Interval", "30"))
        pageCtrls.Push(cfg1)

        cfg2 := mainGui.Add("CheckBox", "x35 y225 w420 c" CLR_TEXT " Background" CLR_CARD, "Отправлять случайный символ в чат вместо прыжка")
        cfg2.Value := IniRead(INI_FILE, "AntiAFK", "ChatAntiAFK", 0)
        pageCtrls.Push(cfg2)

        configFields["AntiAFK"] := [cfg1, cfg2]
    }
    else if key == "MoscowLive" {
        cfg1 := mainGui.Add("CheckBox", "x35 y185 w380 c" CLR_TEXT " Background" CLR_CARD, "Автоматически ловить объявления на сервере")
        cfg1.Value := IniRead(INI_FILE, "MoscowLive", "CatchAds", 0)
        pageCtrls.Push(cfg1)

        pageCtrls.Push(mainGui.Add("Text", "x35 y225 BackgroundTrans", "Задержка перед редактированием (мс):"))
        cfg2 := mainGui.Add("Edit", "x310 y222 w100 -E0x200 Number Background" CLR_INPUT " c" CLR_TEXT, IniRead(INI_FILE, "MoscowLive", "Delay", "500"))
        pageCtrls.Push(cfg2)

        configFields["MoscowLive"] := [cfg1, cfg2]
    }
    else if key == "Helpers" {
        mainGui.SetFont("s10 c" CLR_MUTED)
        pageCtrls.Push(mainGui.Add("Text", "x35 y190 w550 BackgroundTrans", "Для «Хелперки» все горячие клавиши (F1, F2, F8, F11, Alt+W, Alt+V) настроены внутри скрипта."))
    }

    if key != "Helpers" {
        btnSave := CreateFlatBtn(mainGui, 35, 300, 180, 34, "💾 Сохранить настройки", CLR_SUCCESS, CLR_TEXT)
        btnSave.OnEvent("Click", SaveSettings.Bind(key))
        pageCtrls.Push(btnSave)
    }

    for ctrl in pageCtrls
        ctrl.Visible := false

    tabPages[key] := pageCtrls
}

; ==================== НИЖНИЙ СТАТУС-БАР ====================
mainGui.Add("Text", "x0 y410 w650 h30 Background" CLR_CARD)
mainGui.SetFont("s9 Norm c" CLR_MUTED)
statusBar := mainGui.Add("Text", "x18 y417 w614 BackgroundTrans", "Готов к работе.")

SwitchTab("Main")
mainGui.Show("w650 h440")

; ==================== UI ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
CreateFlatBtn(guiObj, x, y, w, h, text, bgColor, txtColor) {
    guiObj.SetFont("s9 Bold c" txtColor)
    btn := guiObj.Add("Text", "x" x " y" y " w" w " h" h " Center 0x200 Background" bgColor, text)
    return btn
}

SetBtnState(btn, enabled, activeBgColor) {
    if !IsObject(btn)
        return
    btn.Enabled := enabled
    if enabled {
        btn.Opt("Background" activeBgColor)
        btn.SetFont("c" CLR_TEXT)
    } else {
        btn.Opt("Background" CLR_DISABLED)
        btn.SetFont("c" CLR_MUTED)
    }
    btn.Redraw()
}

SwitchTab(targetKey, *) {
    global activeTab
    activeTab := targetKey

    for k, btn in navButtons {
        if (k == targetKey) {
            btn.Opt("Background" CLR_ACCENT)
            btn.SetFont("c" CLR_TEXT)
        } else {
            btn.Opt("Background" CLR_CARD)
            btn.SetFont("c" CLR_MUTED)
        }
        btn.Redraw()
    }
    for pageKey, ctrls in tabPages {
        isVisible := (pageKey == targetKey)
        for ctrl in ctrls
            ctrl.Visible := isVisible
    }
}

; ==================== ОБЩИЕ ФУНКЦИИ ====================
HideFile(p) {
    if FileExist(p)
        FileSetAttrib("+H", p)
}

GetLocalVersion(p) {
    if !FileExist(p)
        return "0.0.0"
    Loop Read, p, "UTF-8" {
        if A_Index <= 10 && RegExMatch(A_LoopReadLine, "i)^;\s*@version\s+([\d]+(?:\.[\d]+){0,2})", &match)
            return match[1]
    }
    return "0.0.0"
}

HTTPGet(url) {
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.SetRequestHeader("Cache-Control", "no-cache")
        whr.SetRequestHeader("Pragma", "no-cache")
        whr.Send()
        if whr.Status == 200
            return whr.ResponseText
    }
    return ""
}

ParseSimpleJSON(j) {
    result := Map()
    j := Trim(Trim(j), "{}")
    if j == ""
        return result
    for part in StrSplit(j, ",") {
        part := Trim(part)
        if RegExMatch(part, '^\s*"([^"]+)"\s*:\s*"([^"]*)"\s*$', &match)
            result[match[1]] := match[2]
    }
    return result
}

GetRemoteVersions() {
    jsonText := HTTPGet(RAW_BASE "versions.json?t=" A_TickCount)
    return jsonText != "" ? ParseSimpleJSON(jsonText) : Map()
}

GetRemoteVersion(key, info) {
    rem := GetRemoteVersions()
    if rem.Has(key)
        return Trim(rem[key])
    scriptText := HTTPGet(RAW_BASE info.file "?t=" A_TickCount)
    if scriptText == ""
        return ""
    Loop Parse, scriptText, "`n", "`r" {
        if A_Index <= 10 && RegExMatch(A_LoopField, "i)^;\s*@version\s+([\d]+(?:\.[\d]+){0,2})", &match)
            return match[1]
    }
    return ""
}

StopScript(key, *) {
    p := A_ScriptDir "\" scripts[key].file
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    winTitle := p " ahk_class AutoHotkey"
    if WinExist(winTitle) {
        try PostMessage(0x0111, 65405, 0,, winTitle)
        Sleep(300)
        if WinExist(winTitle) {
            try WinKill(winTitle)
            Sleep(300)
        }
        if WinExist(winTitle) {
            try {
                scriptPID := WinGetPID(winTitle)
                if scriptPID
                    ProcessClose(scriptPID)
            }
            Sleep(300)
        }
    }
    guiControls[key].statusText.Value := "● Остановлен"
    guiControls[key].statusText.SetFont("c" CLR_DANGER)
    SetBtnState(guiControls[key].btnStart, true, CLR_SUCCESS)
    SetBtnState(guiControls[key].btnStop, false, CLR_DANGER)
    statusBar.Value := "⏹ Остановлен: " scripts[key].name
    DetectHiddenWindows(false)
}

StartScript(key, *) {
    info := scripts[key]
    p := A_ScriptDir "\" info.file
    if !FileExist(p) {
        MsgBox("Файл " info.file " не найден!`nСначала нажмите «Обн.».", "Ошибка", "Iconi")
        return
    }
    HideFile(p)
    ahkRuntime := A_AhkPath
    if A_IsCompiled {
        if FileExist("C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe")
            ahkRuntime := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
        else if FileExist("C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe")
            ahkRuntime := "C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe"
        else
            ahkRuntime := "AutoHotkey64.exe"
    }
    if ahkRuntime == ""
        ahkRuntime := "AutoHotkey64.exe"
    try {
        Run('"' ahkRuntime '" "' p '"')
    } catch as err {
        MsgBox("Не удалось запустить скрипт:`n" err.Message, "Ошибка", "Iconi")
        return
    }
    guiControls[key].statusText.Value := "● Запущен"
    guiControls[key].statusText.SetFont("c" CLR_SUCCESS)
    SetBtnState(guiControls[key].btnStart, false, CLR_SUCCESS)
    SetBtnState(guiControls[key].btnStop, true, CLR_DANGER)
    statusBar.Value := "▶ Запущен: " info.name
}

SaveSettings(key, *) {
    fields := configFields[key]
    if key == "ArmyReports" {
        IniWrite(fields[1].Value, INI_FILE, "ArmyReports", "AutoReport")
        IniWrite(fields[2].Text, INI_FILE, "ArmyReports", "Hotkey")
    } else if key == "AntiAFK" {
        IniWrite(fields[1].Text, INI_FILE, "AntiAFK", "Interval")
        IniWrite(fields[2].Value, INI_FILE, "AntiAFK", "ChatAntiAFK")
    } else if key == "MoscowLive" {
        IniWrite(fields[1].Value, INI_FILE, "MoscowLive", "CatchAds")
        IniWrite(fields[2].Text, INI_FILE, "MoscowLive", "Delay")
    }
    p := A_ScriptDir "\" scripts[key].file
    DetectHiddenWindows(true)
    if WinExist(p " ahk_class AutoHotkey") {
        StopScript(key)
        Sleep(300)
        StartScript(key)
        statusBar.Value := "Настройки сохранены. Скрипт '" scripts[key].name "' перезапущен."
    } else {
        MsgBox("Настройки для скрипта '" scripts[key].name "' успешно сохранены!", "Успешно", "Iconi")
    }
    DetectHiddenWindows(false)
}

UpdateScript(key, *) {
    if key == "Launcher"
        return UpdateLauncher()
    info := scripts[key]
    p := A_ScriptDir "\" info.file
    rv := GetRemoteVersion(key, info)
    if rv == "" {
        MsgBox("Не удалось получить версию для " info.name "`nПроверьте интернет и versions.json.", "Ошибка", "Iconi")
        return false
    }
    lv := GetLocalVersion(p)
    if lv == rv {
        guiControls[key].verText.Value := lv
        SetBtnState(guiControls[key].btnUpdate, false, CLR_ACCENT)
        MsgBox("У вас уже последняя версия (" lv ").", "Информация", "Iconi")
        return true
    }
    DetectHiddenWindows(true)
    if WinExist(p " ahk_class AutoHotkey") {
        StopScript(key)
        Sleep(700)
    }
    DetectHiddenWindows(false)
    tempFile := p ".new"
    try {
        if FileExist(p)
            FileSetAttrib("-H", p)
        if FileExist(tempFile)
            FileDelete(tempFile)
        Download(RAW_BASE info.file "?t=" A_TickCount, tempFile)
        if !FileExist(tempFile)
            throw Error("Скачанный временный файл не найден")
        FileMove(tempFile, p, true)
        HideFile(p)
        info.localVer := rv
        guiControls[key].verText.Value := rv
        SetBtnState(guiControls[key].btnUpdate, false, CLR_ACCENT)
        statusBar.Value := "✅ Обновлён: " info.name " до версии " rv
        MsgBox("Скрипт " info.name " обновлён до версии " rv, "Успешно", "Iconi")
        return true
    } catch as err {
        if FileExist(tempFile)
            try FileDelete(tempFile)
        MsgBox("Критическая ошибка при обновлении " info.name "`n" err.Message, "Ошибка", "Iconi")
        return false
    }
}

UpdateLauncher() {
    info := scripts["Launcher"]
    launcherFile := A_ScriptDir "\Launcher.ahk"
    tempLauncher := A_ScriptDir "\Launcher_new.ahk"
    updaterFile := A_ScriptDir "\_updater.ahk"
    remoteVersion := GetRemoteVersion("Launcher", info)
    if remoteVersion == "" {
        MsgBox("Не удалось получить версию лаунчера.", "Ошибка", "Iconi")
        return false
    }
    localVersion := GetLocalVersion(launcherFile)
    if localVersion == remoteVersion && localVersion != "0.0.0" {
        MsgBox("У вас уже последняя версия лаунчера (" localVersion ").", "Информация", "Iconi")
        SetBtnState(guiControls["Launcher"].btnUpdate, false, CLR_ACCENT)
        return true
    }
    try {
        if FileExist(tempLauncher)
            FileDelete(tempLauncher)
        if FileExist(updaterFile)
            FileDelete(updaterFile)
    } catch as err {
        MsgBox("Не удалось очистить временные файлы:`n" err.Message, "Ошибка", "Iconi")
        return false
    }
    try {
        Download(RAW_BASE "Launcher.ahk?t=" A_TickCount, tempLauncher)
        if !FileExist(tempLauncher)
            throw Error("Загруженный Launcher_new.ahk отсутствует")
        downloadedVersion := GetLocalVersion(tempLauncher)
        if downloadedVersion == "0.0.0"
            throw Error("В загруженном файле отсутствует @version")
        if downloadedVersion != remoteVersion
            throw Error("Версия загруженного файла " downloadedVersion " не совпадает с remote-версией " remoteVersion)
    } catch as err {
        MsgBox("Не удалось скачать обновление лаунчера:`n" err.Message, "Ошибка", "Iconi")
        if FileExist(tempLauncher)
            try FileDelete(tempLauncher)
        return false
    }
    updateInfoFile := A_ScriptDir "\_launcher_update.ini"
    try {
        if FileExist(updateInfoFile)
            FileDelete(updateInfoFile)
        IniWrite(tempLauncher, updateInfoFile, "Update", "NewFile")
        IniWrite(launcherFile, updateInfoFile, "Update", "TargetFile")
        IniWrite(A_AhkPath, updateInfoFile, "Update", "AutoHotkey")
    } catch as err {
        MsgBox("Не удалось подготовить параметры обновления:`n" err.Message, "Ошибка", "Iconi")
        if FileExist(tempLauncher)
            try FileDelete(tempLauncher)
        return false
    }
    
    updaterContent := "
    (
#Requires AutoHotkey v2.0
#SingleInstance Force
updateInfo := A_ScriptDir . '\_launcher_update.ini'
Sleep 1500
newFile := IniRead(updateInfo, 'Update', 'NewFile', '')
targetFile := IniRead(updateInfo, 'Update', 'TargetFile', '')
ahkExe := IniRead(updateInfo, 'Update', 'AutoHotkey', '')
if newFile = '' or targetFile = '' or ahkExe = '' {
    MsgBox('Не удалось прочитать параметры обновления.', 'Ошибка', 'Iconi')
    ExitApp
}
if !FileExist(newFile) {
    MsgBox('Новый файл лаунчера не найден.', 'Ошибка', 'Iconi')
    ExitApp
}
try FileSetAttrib('-H', targetFile)
try FileMove(targetFile, targetFile . '.old', true)
try {
    FileMove(newFile, targetFile, true)
} catch as err {
    if FileExist(targetFile . '.old')
        try FileMove(targetFile . '.old', targetFile, true)
    MsgBox('Не удалось заменить лаунчер:`n' . err.Message, 'Ошибка', 'Iconi')
    ExitApp
}
try FileDelete(targetFile . '.old')
try FileDelete(updateInfo)
Sleep 500
try {
    Run('"' . ahkExe . '" "' . targetFile . '"')
} catch as err {
    MsgBox('Лаунчер обновлён, но не удалось запустить:`n' . err.Message, 'Ошибка', 'Iconi')
}
Sleep 300
try FileDelete(A_ScriptFullPath)
ExitApp
    )"

    try {
        FileDelete(updaterFile)
        FileAppend(updaterContent, updaterFile, "UTF-8")
        Run('"' . A_AhkPath . '" "' . updaterFile . '"')
    } catch as err {
        MsgBox("Не удалось запустить обновлятор:`n" . err.Message, "Ошибка", "Iconi")
        return false
    }
    ExitApp()
}

UpdateAllScripts(*) {
    statusBar.Value := "Проверка обновлений..."
    updated := 0
    launcherNeedsUpdate := false
    launcherInfo := scripts["Launcher"]
    launcherPath := A_ScriptDir "\" launcherInfo.file
    launcherRemoteVersion := GetRemoteVersion("Launcher", launcherInfo)
    launcherLocalVersion := GetLocalVersion(launcherPath)
    if launcherRemoteVersion != "" && launcherRemoteVersion != launcherLocalVersion
        launcherNeedsUpdate := true
    for key, info in scripts {
        if key == "Launcher"
            continue
        if UpdateScript(key)
            updated++
    }
    if launcherNeedsUpdate {
        MsgBox("Обычные скрипты обработаны.`nСейчас запускается обновление лаунчера.", "Обновление лаунчера", "Iconi")
        UpdateLauncher()
        return
    }
    MsgBox(updated ? "Обновление завершено.`nОбновлено скриптов: " updated : "Все скрипты уже актуальны.", "Результат", "Iconi")
    statusBar.Value := "Обновление завершено."
}

CheckAllVersions() {
    rem := GetRemoteVersions()
    for key, info in scripts {
        p := A_ScriptDir "\" info.file
        if FileExist(p)
            HideFile(p)
        lv := GetLocalVersion(p)
        info.localVer := lv
        guiControls[key].verText.Value := lv
        if !FileExist(p)
            SetBtnState(guiControls[key].btnUpdate, true, CLR_ACCENT)
        else if rem.Has(key) && rem[key] != lv
            SetBtnState(guiControls[key].btnUpdate, true, CLR_ACCENT)
        else
            SetBtnState(guiControls[key].btnUpdate, false, CLR_ACCENT)
    }
    statusBar.Value := "✅ Проверка версий завершена"
}

SetTimer(CheckAllVersions, -500)

~Esc:: {
    if WinActive("ahk_class AutoHotkeyGUI")
        ExitApp()
}
