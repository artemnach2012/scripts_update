#Requires AutoHotkey v2.0
#SingleInstance Force

; @version 1.0.3

GITHUB_REPO := "artemnach2012/scripts_update"
RAW_BASE := "https://raw.githubusercontent.com/" GITHUB_REPO "/main/"
INI_FILE := A_ScriptDir "\settings.ini"

scripts := Map()

scripts["Launcher"] := {
    name: "Лаунчер",
    file: "Launcher.ahk",
    localVer: "0.0.0",
    isLauncher: true
}

scripts["ArmyReports"] := {
    name: "Армия докладов",
    file: "ArmyReports.ahk",
    localVer: "0.0.0"
}

scripts["AntiAFK"] := {
    name: "Анти-АФК",
    file: "AntiAFK.ahk",
    localVer: "0.0.0"
}

scripts["MoscowLive"] := {
    name: "Москва-Live",
    file: "MoscowLive.ahk",
    localVer: "0.0.0"
}

scripts["Helpers"] := {
    name: "Хелперка",
    file: "Helpers.ahk",
    localVer: "0.0.0"
}

mainGui := Gui(, "Панель управления скриптами")
mainGui.BackColor := "2A2A2A"
mainGui.SetFont("s10 cWhite", "Segoe UI")

tabNames := ["Главная"]

for key, info in scripts
    tabNames.Push(info.name)

tabPanel := mainGui.Add("Tab3", "x10 y10 w610 h380 cWhite", tabNames)
tabPanel.UseTab(1)

mainGui.SetFont("s12 Bold cWhite")
mainGui.Add("Text", "x20 y45 w590 Center", "Управление скриптами AutoHotkey")

mainGui.SetFont("s9 Italic cFF5555")
mainGui.Add("Text", "x20 y70 w590 Center", "Данное приложение находится в статусе: БЕТА-ВЕРСИЯ")

mainGui.SetFont("s10 Bold cWhite")
mainGui.Add("Text", "x30 y100 w150", "Название")
mainGui.Add("Text", "x190 y100 w80", "Версия")
mainGui.Add("Text", "x280 y100 w100", "Статус")
mainGui.Add("Text", "x390 y100 w210", "Действия")

guiControls := Map()
yPos := 130

for key, info in scripts {
    isLauncher := info.HasOwnProp("isLauncher") && info.isLauncher

    mainGui.SetFont("s10 Norm cWhite")
    mainGui.Add("Text", "x30 y" yPos " w150", info.name)

    verText := mainGui.Add("Text",
        "x190 y" yPos " w80 cYellow",
        "—")

    statusText := mainGui.Add("Text",
        "x280 y" yPos " w100 cGray",
        isLauncher ? "Активен" : "Не запущен")

    mainGui.SetFont("s9 cBlack")

    if isLauncher {
        btnStart := ""
        btnStop := ""
        btnUpdate := mainGui.Add("Button", "x390 y" yPos " w65", " Обн.")
        btnUpdate.BackColor := "2196F3"
    } else {
        btnStart := mainGui.Add("Button", "x390 y" yPos " w65", "▶ Старт")
        btnStart.BackColor := "4CAF50"

        btnStop := mainGui.Add("Button", "x460 y" yPos " w65 Disabled", "⏹ Стоп")
        btnStop.BackColor := "F44336"

        btnUpdate := mainGui.Add("Button", "x530 y" yPos " w65", " Обн.")
        btnUpdate.BackColor := "2196F3"
    }

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
    yPos += 35
}

mainGui.SetFont("s9 cBlack")

btnUpdateAll := mainGui.Add("Button",
    "x30 y" (yPos + 15) " w150",
    " Обновить все")

btnUpdateAll.BackColor := "4CAF50"
btnUpdateAll.OnEvent("Click", UpdateAllScripts)

configFields := Map()
tabIndex := 2

for key, info in scripts {
    if info.HasOwnProp("isLauncher") && info.isLauncher {
        tabIndex += 1
        continue
    }

    tabPanel.UseTab(tabIndex)
    tabIndex += 1

    mainGui.SetFont("s12 Bold cWhite")
    mainGui.Add("Text", "x30 y50 w550", "Настройки: " info.name)

    mainGui.SetFont("s10 Bold cFF5555")
    mainGui.Add("Text", "x30 y80 w550",
        "⚠ ВНИМАНИЕ: настройки находятся в доработке!")

    mainGui.SetFont("s10 Norm cWhite")

    if key == "ArmyReports" {
        cfg1 := mainGui.Add("CheckBox",
            "x40 y115 w300",
            "Включить автоматический доклад по таймеру")

        cfg1.Value := IniRead(INI_FILE,
            "ArmyReports",
            "AutoReport",
            0)

        mainGui.Add("Text",
            "x40 y155",
            "Клавиша для ручного доклада:")

        cfg2 := mainGui.Add("Edit",
            "x250 y152 w100 Background3A3A3A cWhite",
            IniRead(INI_FILE,
                "ArmyReports",
                "Hotkey",
                "F8"))

        configFields["ArmyReports"] := [cfg1, cfg2]
    }

    else if key == "AntiAFK" {
        mainGui.Add("Text",
            "x40 y115",
            "Интервал между действиями (в секундах):")

        cfg1 := mainGui.Add("Edit",
            "x320 y112 w80 Background3A3A3A cWhite Number",
            IniRead(INI_FILE,
                "AntiAFK",
                "Interval",
                "30"))

        cfg2 := mainGui.Add("CheckBox",
            "x40 y155 w300",
            "Отправлять случайный символ в чат вместо прыжка")

        cfg2.Value := IniRead(INI_FILE,
            "AntiAFK",
            "ChatAntiAFK",
            0)

        configFields["AntiAFK"] := [cfg1, cfg2]
    }

    else if key == "MoscowLive" {
        cfg1 := mainGui.Add("CheckBox",
            "x40 y115 w300",
            "Автоматически ловить объявления на сервере")

        cfg1.Value := IniRead(INI_FILE,
            "MoscowLive",
            "CatchAds",
            0)

        mainGui.Add("Text",
            "x40 y155",
            "Задержка перед редактированием (мс):")

        cfg2 := mainGui.Add("Edit",
            "x300 y152 w100 Background3A3A3A cWhite Number",
            IniRead(INI_FILE,
                "MoscowLive",
                "Delay",
                "500"))

        configFields["MoscowLive"] := [cfg1, cfg2]
    }

    mainGui.SetFont("s9 cBlack")

    mainGui.Add("Button",
        "x40 y330 w150",
        " Сохранить")
        .OnEvent("Click", SaveSettings.Bind(key))
}

tabPanel.UseTab()

mainGui.SetFont("s10 cGray")
statusBar := mainGui.Add("Text",
    "x15 y400 w610",
    "Готов к работе.")

mainGui.Show("w630 h430")


; ============================================================
; ОБЩИЕ ФУНКЦИИ
; ============================================================

HideFile(p) {
    if FileExist(p)
        FileSetAttrib("+H", p)
}

GetLocalVersion(p) {
    if !FileExist(p)
        return "0.0.0"

    Loop Read, p, "UTF-8" {
        if A_Index <= 10
            && RegExMatch(
                A_LoopReadLine,
                "i)^;\s*@version\s+([\d]+(?:\.[\d]+){0,2})",
                &match
            )
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
    } catch {
    }

    return ""
}

ParseSimpleJSON(j) {
    result := Map()

    j := Trim(j)
    j := Trim(j, "{}")

    if j == ""
        return result

    for part in StrSplit(j, ",") {
        part := Trim(part)

        if RegExMatch(
            part,
            '^\s*"([^"]+)"\s*:\s*"([^"]*)"\s*$',
            &match
        )
            result[match[1]] := match[2]
    }

    return result
}

GetRemoteVersions() {
    jsonText := HTTPGet(
        RAW_BASE "versions.json?t=" A_TickCount
    )

    return jsonText != ""
        ? ParseSimpleJSON(jsonText)
        : Map()
}

GetRemoteVersion(key, info) {
    rem := GetRemoteVersions()

    if rem.Has(key)
        return Trim(rem[key])

    scriptText := HTTPGet(
        RAW_BASE info.file "?t=" A_TickCount
    )

    if scriptText == ""
        return ""

    Loop Parse, scriptText, "`n", "`r" {
        if A_Index <= 10
            && RegExMatch(
                A_LoopField,
                "i)^;\s*@version\s+([\d]+(?:\.[\d]+){0,2})",
                &match
            )
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

    guiControls[key].statusText.Value := "Остановлен"
    guiControls[key].statusText.SetFont("cFF5555")
    guiControls[key].btnStart.Enabled := true
    guiControls[key].btnStop.Enabled := false
    statusBar.Value := "⏹ Остановлен: " scripts[key].name

    DetectHiddenWindows(false)
}

StartScript(key, *) {
    info := scripts[key]
    p := A_ScriptDir "\" info.file

    if !FileExist(p) {
        MsgBox(
            "Файл " info.file " не найден!"
                "`nСначала нажмите «Обновить».",
            "Ошибка",
            "Iconi")
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
        MsgBox(
            "Не удалось запустить скрипт:"
                "`n" err.Message,
            "Ошибка",
            "Iconi")
        return
    }

    guiControls[key].statusText.Value := "Запущен"
    guiControls[key].statusText.SetFont("c00FF00")
    guiControls[key].btnStart.Enabled := false
    guiControls[key].btnStop.Enabled := true
    statusBar.Value := "▶ Запущен: " info.name
}

SaveSettings(key, *) {
    fields := configFields[key]

    if key == "ArmyReports" {
        IniWrite(fields[1].Value,
            INI_FILE,
            "ArmyReports",
            "AutoReport")

        IniWrite(fields[2].Text,
            INI_FILE,
            "ArmyReports",
            "Hotkey")
    }

    else if key == "AntiAFK" {
        IniWrite(fields[1].Text,
            INI_FILE,
            "AntiAFK",
            "Interval")

        IniWrite(fields[2].Value,
            INI_FILE,
            "AntiAFK",
            "ChatAntiAFK")
    }

    else if key == "MoscowLive" {
        IniWrite(fields[1].Value,
            INI_FILE,
            "MoscowLive",
            "CatchAds")

        IniWrite(fields[2].Text,
            INI_FILE,
            "MoscowLive",
            "Delay")
    }

    p := A_ScriptDir "\" scripts[key].file

    DetectHiddenWindows(true)

    if WinExist(p " ahk_class AutoHotkey") {
        StopScript(key)
        Sleep(300)
        StartScript(key)

        statusBar.Value :=
            "Настройки сохранены."
                " Скрипт '" scripts[key].name "' перезапущен."
    } else {
        MsgBox(
            "Настройки для скрипта '"
                scripts[key].name
                "' успешно сохранены!",
            "Успешно",
            "Iconi")
    }

    DetectHiddenWindows(false)
}


; ============================================================
; ОБНОВЛЕНИЕ ХЕЛПЕРКИ И ДРУГИХ СКРИПТОВ
; ============================================================

UpdateScript(key, *) {
    if key == "Launcher"
        return UpdateLauncher()

    info := scripts[key]
    p := A_ScriptDir "\" info.file
    rv := GetRemoteVersion(key, info)

    if rv == "" {
        MsgBox(
            "Не удалось получить версию для " info.name
                "`nПроверьте интернет и versions.json.",
            "Ошибка",
            "Iconi")
        return false
    }

    lv := GetLocalVersion(p)

    if lv == rv {
        guiControls[key].verText.Value := lv
        guiControls[key].btnUpdate.Enabled := false

        MsgBox(
            "У вас уже последняя версия (" lv ").",
            "Информация",
            "Iconi")
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

        Download(
            RAW_BASE info.file "?t=" A_TickCount,
            tempFile)

        if !FileExist(tempFile)
            throw Error("Скачанный временный файл не найден")

        FileMove(tempFile, p, true)
        HideFile(p)

        info.localVer := rv
        guiControls[key].verText.Value := rv
        guiControls[key].btnUpdate.Enabled := false
        statusBar.Value :=
            "✅ Обновлён: " info.name " до версии " rv

        MsgBox(
            "Скрипт " info.name
                " обновлён до версии " rv,
            "Успешно",
            "Iconi")

        return true
    } catch as err {
        if FileExist(tempFile)
            try FileDelete(tempFile)

        MsgBox(
            "Критическая ошибка при обновлении "
                info.name
                "`n" err.Message,
            "Ошибка",
            "Iconi")
        return false
    }
}


; ============================================================
; ОБНОВЛЕНИЕ ЛАУНЧЕРА
; ============================================================

EscapeAhkString(value) {
    value := StrReplace(value, '`r', '')
    value := StrReplace(value, '`n', '')
    value := StrReplace(value, '"', '`"')
    return value
}

UpdateLauncher() {
    info := scripts["Launcher"]
    launcherFile := A_ScriptDir "\Launcher.ahk"
    tempLauncher := A_ScriptDir "\Launcher_new.ahk"
    updaterFile := A_ScriptDir "\_updater.ahk"

    remoteVersion := GetRemoteVersion("Launcher", info)

    if remoteVersion == "" {
        MsgBox(
            "Не удалось получить версию лаунчера.",
            "Ошибка",
            "Iconi")
        return false
    }

    localVersion := GetLocalVersion(launcherFile)

    if localVersion == remoteVersion
        && localVersion != "0.0.0" {
        MsgBox(
            "У вас уже последняя версия лаунчера (" localVersion ").",
            "Информация",
            "Iconi")

        guiControls["Launcher"].btnUpdate.Enabled := false
        return true
    }

    try {
        if FileExist(tempLauncher)
            FileDelete(tempLauncher)

        if FileExist(updaterFile)
            FileDelete(updaterFile)
    } catch as err {
        MsgBox(
            "Не удалось очистить временные файлы:"
                "`n" err.Message,
            "Ошибка",
            "Iconi")
        return false
    }

    try {
        Download(
            RAW_BASE "Launcher.ahk?t=" A_TickCount,
            tempLauncher)

        if !FileExist(tempLauncher)
            throw Error("Загруженный Launcher_new.ahk отсутствует")

        downloadedVersion := GetLocalVersion(tempLauncher)

        if downloadedVersion == "0.0.0"
            throw Error("В загруженном файле отсутствует @version")

        if downloadedVersion != remoteVersion
            throw Error(
                "Версия загруженного файла "
                    downloadedVersion
                    " не совпадает с remote-версией "
                    remoteVersion)
    } catch as err {
        MsgBox(
            "Не удалось скачать обновление лаунчера:"
                "`n" err.Message,
            "Ошибка",
            "Iconi")

        if FileExist(tempLauncher)
            try FileDelete(tempLauncher)

        return false
    }

    ; Все пути передаются обновлятору отдельно через .ini-файл,
    ; чтобы кавычки не ломали создаваемый AHK-код.
    updateInfoFile := A_ScriptDir "\_launcher_update.ini"

    try {
        if FileExist(updateInfoFile)
            FileDelete(updateInfoFile)

        IniWrite(tempLauncher,
            updateInfoFile,
            "Update",
            "NewFile")

        IniWrite(launcherFile,
            updateInfoFile,
            "Update",
            "TargetFile")

        IniWrite(A_AhkPath,
            updateInfoFile,
            "Update",
            "AutoHotkey")

        if !FileExist(updateInfoFile)
            throw Error("INI-файл параметров не был создан")
    } catch as err {
        MsgBox(
            "Не удалось подготовить параметры обновления:"
                "`n" err.Message,
            "Ошибка",
            "Iconi")

        if FileExist(tempLauncher)
            try FileDelete(tempLauncher)

        return false
    }

    updaterContent :=
        '#Requires AutoHotkey v2.0`n'
        . '#SingleInstance Force`n'
        . '`n'
        . 'updateInfo := A_ScriptDir "\_launcher_update.ini"`n'
        . '`n'
        . 'Sleep 1500`n'
        . '`n'
        . 'newFile := IniRead(updateInfo, "Update", "NewFile", "")`n'
        . 'targetFile := IniRead(updateInfo, "Update", "TargetFile", "")`n'
        . 'ahkExe := IniRead(updateInfo, "Update", "AutoHotkey", "")`n'
        . '`n'
        . 'if newFile = "" or targetFile = "" or ahkExe = "" {`n'
        . '    MsgBox("Не удалось прочитать параметры обновления.", "Ошибка", "Iconi")`n'
        . '    ExitApp`n'
        . '}`n'
        . '`n'
        . 'if !FileExist(newFile) {`n'
        . '    MsgBox("Новый файл лаунчера не найден.", "Ошибка", "Iconi")`n'
        . '    ExitApp`n'
        . '}`n'
        . '`n'
        . 'try FileSetAttrib("-H", targetFile)`n'
        . 'try FileMove(targetFile, targetFile ".old", true)`n'
        . '`n'
        . 'try {`n'
        . '    FileMove(newFile, targetFile, true)`n'
        . '} catch as err {`n'
        . '    if FileExist(targetFile ".old")`n'
        . '        try FileMove(targetFile ".old", targetFile, true)`n'
        . '`n'
        . '    MsgBox("Не удалось заменить лаунчер:`n" err.Message, "Ошибка", "Iconi")`n'
        . '    ExitApp`n'
        . '}`n'
        . '`n'
        . 'try FileDelete(targetFile ".old")`n'
        . 'try IniDelete(updateInfo)`n'
        . '`n'
        . 'Sleep 500`n'
        . '`n'
        . 'try {`n'
        . '    Run(`"' ahkExe '`" `"' targetFile '`"")`n'
        . '} catch as err {`n'
        . '    MsgBox("Лаунчер обновлён, но не удалось запустить:`n" err.Message, "Ошибка", "Iconi")`n'
        . '}`n'
        . '`n'
        . 'Sleep 300`n'
        . 'try FileDelete(A_ScriptFullPath)`n'
        . 'ExitApp`n'

    try {
        FileDelete(updaterFile)
        FileAppend(
            updaterContent,
            updaterFile,
            "UTF-8")
    } catch as err {
        MsgBox(
            "Не удалось создать обновлятор:"
                "`n" err.Message
                "`nПуть: " updaterFile
                "`nПроверьте права на запись.",
            "Ошибка",
            "Iconi")

        try FileDelete(tempLauncher)
        try FileDelete(updateInfoFile)
        return false
    }

    if !FileExist(updaterFile) {
        MsgBox(
            "Обновлятор был создан без содержимого:"
                "`n" updaterFile,
            "Ошибка",
            "Iconi")

        try FileDelete(tempLauncher)
        try FileDelete(updateInfoFile)
        return false
    }

    try {
        Run('"' A_AhkPath '" "' updaterFile '"')
    } catch as err {
        MsgBox(
            "Не удалось запустить обновлятор:"
                "`n" err.Message,
            "Ошибка",
            "Iconi")

        try FileDelete(updaterFile)
        try FileDelete(tempLauncher)
        try FileDelete(updateInfoFile)
        return false
    }

    ExitApp()
}


; ============================================================
; ОБНОВИТЬ ВСЁ
; ============================================================

UpdateAllScripts(*) {
    statusBar.Value := "Проверка обновлений..."

    updated := 0
    launcherNeedsUpdate := false

    launcherInfo := scripts["Launcher"]
    launcherPath := A_ScriptDir "\" launcherInfo.file
    launcherRemoteVersion := GetRemoteVersion(
        "Launcher",
        launcherInfo)
    launcherLocalVersion := GetLocalVersion(
        launcherPath)

    if launcherRemoteVersion != ""
        && launcherRemoteVersion != launcherLocalVersion
        launcherNeedsUpdate := true

    for key, info in scripts {
        if key == "Launcher"
            continue

        if UpdateScript(key)
            updated++
    }

    if launcherNeedsUpdate {
        MsgBox(
            "Обычные скрипты обработаны."
                "`nСейчас запускается обновление лаунчера.",
            "Обновление лаунчера",
            "Iconi")

        UpdateLauncher()
        return
    }

    MsgBox(
        updated
            ? "Обновление завершено."
                "`nОбновлено скриптов: " updated
            : "Все скрипты уже актуальны.",
        "Результат",
        "Iconi")

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
            guiControls[key].btnUpdate.Enabled := true

        else if rem.Has(key)
            && rem[key] != lv
            guiControls[key].btnUpdate.Enabled := true

        else
            guiControls[key].btnUpdate.Enabled := false
    }

    statusBar.Value := "✅ Проверка версий завершена"
}

SetTimer(CheckAllVersions, -500)

~Esc:: {
    if WinActive("ahk_class AutoHotkeyGUI")
        ExitApp()
}
