#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
; 1. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
; =============================================================================

; ---------- ped_tester.ahk ----------
Global ResultFilePath := A_Desktop "\peds_test_results.txt"
Global PedsBase := [
    "mp_m_freemode_01", "mp_f_freemode_01", "ig_abigail", "u_m_y_abner", "a_m_m_afriamer_01",
    "a_m_y_afriamer_02", "ig_amani", "ig_andreas", "cs_andreas", "hc_andreas", "ig_ashley",
    "a_m_m_beach_01", "a_m_m_beach_02", "a_m_y_beach_01", "a_m_y_beach_02", "a_f_m_beach_01",
    "a_f_y_beach_01", "ig_benny", "ig_bestmen", "g_m_y_ballaeast_01", "g_m_y_ballaorig_01",
    "g_m_y_ballasout_01", "g_f_y_ballas_01", "s_m_m_bouncer_01", "s_m_y_blackops_01",
    "s_m_y_blackops_02", "cs_bradcadd", "ig_brad", "s_m_m_cntrybar_01", "g_m_y_chef_01",
    "ig_chef", "s_m_m_chef_01", "s_m_y_chef_01", "s_m_y_cop_01", "s_f_y_cop_01",
    "s_m_m_doctor_01", "s_m_m_fiboffice_01", "s_m_m_fiboffice_02", "s_m_m_gaffer_01",
    "s_m_y_garbage", "ig_groom", "s_m_m_highsec_01", "s_m_m_highsec_02", "s_m_m_paramedic_01",
    "s_m_m_pilot_01", "s_m_y_pilot_01", "s_m_m_postal_01", "s_m_m_postal_02", "s_m_m_prison_01",
    "s_m_y_prisoner_01", "s_m_y_robber_01", "s_m_m_scientist_01", "s_m_y_sheriff_01",
    "s_f_y_sheriff_01", "s_m_m_strvend_01", "s_m_m_swat_01", "s_m_y_swat_01", "s_m_m_ups_01"
]
Global CurrentIndex := 1
Global TargetPlayerID := ""
Global IsActiveTest := 0
Global IsSkinEvaluated := 0

; ---------- Съемка.ahk ----------
Global IsGuiVisible := 0
Global WarningsMap := Map()
Global MyGui, LV

; ---------- объединенный скрипт.ahk ----------
Global MainFolder := A_Desktop "\админ ахк"
Global Folder1 := MainFolder "\Поставки"
Global Folder2 := MainFolder "\Налеты"
Global Folder3 := MainFolder "\Ограбления"
Global LogFile := MainFolder "\количество_репортов.txt"
Global TempFile := MainFolder "\временный_скриншот.png"
Global ReportCount := 0

if FileExist(LogFile) {
    SavedCount := FileRead(LogFile)
    if IsInteger(SavedCount)
        ReportCount := Integer(SavedCount)
}

; ---------- очистка старых записей нарушений.ahk ----------
Global TargetFolder := "C:\Users\" A_UserName "\Videos\NVIDIA" ; Сделано универсальным
Global DaysToKeep := 4

; ---------- ГРИБЫ (F1) ----------
Global MushroomsList := [
    ["Белый гриб", "8.000р", "1.6%"],
    ["Сморчок", "5.600р", "2.3%"],
    ["Подберёзовик", "4.800р", "3.2%"],
    ["Зонтик пёстрый", "3.680р", "7.4%"],
    ["Лисичка", "2.920р", "10.4%"],
    ["Навозник белый", "2.520р", "8.1%"],
    ["Мухомор", "2.200р", "10.7%"],
    ["Говорушка ворончатая", "1.880р", "8.7%"],
    ["Рыжик", "1.640р", "10.4%"],
    ["Маслёнок", "1.320р", "16.8%"],
    ["Луговой опёнок", "1.080р", "20.4%"]
]

; =============================================================================
; 2. СОЗДАНИЕ ПАПОК И МЕНЮ СЛЕЖКИ (АВТОЗАПУСК)
; =============================================================================

; Создаем все нужные папки, если их нет
if !DirExist(MainFolder)
    DirCreate(MainFolder)
if !DirExist(Folder1)
    DirCreate(Folder1)
if !DirExist(Folder2)
    DirCreate(Folder2)
if !DirExist(Folder3)
    DirCreate(Folder3)

PostavkiMenu := Menu()
PostavkiMenu.Add("Начало поставки", (ItemName, ItemPos, MyMenu) => SaveScreenshot(Folder1, "Поставка_НАЧАЛО"))
PostavkiMenu.Add("Привозка матки", (ItemName, ItemPos, MyMenu) => SaveScreenshot(Folder1, "Поставка_ПРИВОЗ_МАТКИ"))

NaletiMenu := Menu()
NaletiMenu.Add("Начало налета", (ItemName, ItemPos, MyMenu) => SaveScreenshot(Folder2, "Налет_НАЧАЛО"))
NaletiMenu.Add("Конец налета", (ItemName, ItemPos, MyMenu) => SaveScreenshot(Folder2, "Налет_КОНЕЦ"))

OgrabiMenu := Menu()
OgrabiMenu.Add("Начало ограбления", (ItemName, ItemPos, MyMenu) => SaveScreenshot(Folder3, "Ограбление_НАЧАЛО"))
OgrabiMenu.Add("Конец ограбления", (ItemName, ItemPos, MyMenu) => SaveScreenshot(Folder3, "Ограбление_КОНЕЦ"))

MainMenu := Menu()
MainMenu.Add("Поставки", PostavkiMenu)
MainMenu.Add("Налеты", NaletiMenu)
MainMenu.Add("Ограбления", OgrabiMenu)

; =============================================================================
; 3. СОЗДАНИЕ ОВЕРЛЕЕВ (СКРЫТЫ ПО УМОЛЧАНИЮ)
; =============================================================================

Global TestGui := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20", "HUD Тестера")
TestGui.BackColor := "111111"
WinSetTransColor("111111", TestGui)
TestGui.SetFont("s11", "Segoe UI")
Global HudText := TestGui.Add("Text", "w400 cLime", "")
HudText.SetFont("Bold")
TestGui.Hide()

MyGui := Gui("+AlwaysOnTop +ToolWindow", "Мониторинг предов RMRP")
MyGui.SetFont("s10", "Segoe UI")
MyGui.Add("Text",, "Нарушители в деменшене (F11 - скрыть/показать):")
LV := MyGui.Add("ListView", "r12 w400 Grid", ["ID Игрока", "Предупреждения", "Последняя причина"])
LV.ModifyCol(1, 100), LV.ModifyCol(2, 110), LV.ModifyCol(3, 170)
MyGui.Hide()

; =============================================================================
; 4. ОСНОВНЫЕ ФУНКЦИИ
; =============================================================================

IsInteger(x) => x ~= "^-?\d+$"

SendSkinToGame() {
    Global CurrentIndex, TargetPlayerID
    if !(WinActive("ahk_exe GTA5.exe") or WinActive("ahk_exe ragemp_v.exe"))
        return
    CommandText := "/setmodel " TargetPlayerID " " PedsBase[CurrentIndex]
    OldClipboard := ClipboardAll()
    A_Clipboard := CommandText
    ClipWait(1)
    BlockInput(true)
    SendEvent("^v")
    Sleep(80)
    SendEvent("{Enter}")
    BlockInput(false)
    A_Clipboard := OldClipboard
}

SaveResult(Status) {
    Global CurrentIndex, IsSkinEvaluated
    CurrentSkinCode := PedsBase[CurrentIndex]
    FileAppend("Скин: " CurrentSkinCode " -> СТАТУС: " Status "`n", ResultFilePath, "UTF-8")
    IsSkinEvaluated := 1
    StatusColor := (Status == "РАБОЧИЙ") ? "🟢" : "🔴"
    UpdateHud("Скин [" CurrentIndex "/" PedsBase.Length "]: " CurrentSkinCode "`n" StatusColor " СОХРАНЕНО: " Status "`n[Нажмите Alt + Стрелка Вниз для перехода]")
}

UpdateHud(NewText) {
    HudText.Value := NewText
    if !TestGui.Visible
        TestGui.Show("x50 y150 NoActivate")
}

HideTestHud() {
    TestGui.Hide()
}

ManageLV(Mode, FID, Count:=0, Reason:="") {
    if (Mode == 1) {
        Row := 0
        Loop LV.GetCount() {
            if (LV.GetText(A_Index, 1) == FID)
                Row := A_Index
        }
        if (Row > 0)
            LV.Modify(Row, , FID, Count " / 3", Reason)
        else
            LV.Add(, FID, Count " / 3", Reason)
    } else if (Mode == 2) {
        Loop LV.GetCount() {
            if (LV.GetText(A_Index, 1) == FID)
                LV.Delete(A_Index)
        }
    }
}

SendCmd(Text) {
    if (WinActive("ahk_exe GTA5.exe") or WinActive("ahk_exe ragemp_v.exe")) {
        BlockInput(true)
        SendEvent("{t Down}")
        Sleep(40)
        SendEvent("{t Up}")
        Sleep(150)
        SendText(Text)
        Sleep(100)
        SendEvent("{Enter Down}")
        Sleep(40)
        SendEvent("{Enter Up}")
        BlockInput(false)
    }
}

SaveAndShowReports() {
    if FileExist(LogFile)
        FileDelete(LogFile)
    FileAppend(String(ReportCount), LogFile, "UTF-8")
    ShowToolTip("Репортов за сегодня: " ReportCount)
}

SaveScreenshot(TargetDir, Prefix) {
    CurrentTime := FormatTime(, "dd-MM-yyyy_HH-mm-ss")
    NewFileName := TargetDir "\" Prefix "_" CurrentTime ".png"
    try {
        FileMove(TempFile, NewFileName, 1)
        ShowToolTip("Сохранено: " Prefix "!")
    } catch {
        MsgBox("Не удалось переместить скриншот. Возможно, файл или папка заблокированы.", "Ошибка", "IconX")
    }
}

ShowToolTip(Text) {
    ToolTip(Text)
    SetTimer(() => ToolTip(), -2000)
}

ShowHelpWindow() {
    MyGui2 := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Шпаргалка RMRP")
    MyGui2.SetFont("s10", "Segoe UI")
    MyGui2.Add("Text",, "Управление инструментами:")
    MyGui2.Add("Text",, "• Numpad [+] — Добавить репорт")
    MyGui2.Add("Text",, "• Numpad [-] — Отнять репорт")
    MyGui2.Add("Text",, "• Page Up — Проверить счет репортов")
    MyGui2.Add("Text",, "• Page Down — Показать это окно снова")
    MyGui2.Add("Text",, "• Delete — Обнулить репорты за день")
    MyGui2.Add("Text",, "• F8 — Скриншот слежки (Поставки / Налеты / Ограбления)")
    MyGui2.Add("Text",, "• Alt+↑ — Тестер скинов (HUD появляется автоматически)")
    MyGui2.Add("Text",, "• F11 — Показать/скрыть таблицу предов")
    MyGui2.Add("Text",, "• Alt+W — Управление игроком (преды, кик, инвайт, скины)")
    MyGui2.Add("Text",, "• Alt+V — Гараж транспорта")
    MyGui2.Add("Text",, "• F2 — Войти в медиа-измерение")
    MyGui2.Add("Text",, "• Alt+C — Очистить транспорт")
    MyGui2.Add("Text",, "• F12 — Очистить таблицу предов")
    MyGui2.Add("Text",, "• Ctrl+Alt+C — Очистка папки с видео (старше 4 дней)")
    MyGui2.Add("Text",, "• Home — Правила сервера (ПП, ПГО, ПКО, ФКЗ)")
    MyGui2.Add("Text",, "• F1 — Грибы (название, цена, шанс + карта)")
    Btn := MyGui2.Add("Button", "w80 Default", "Понял")
    Btn.OnEvent("Click", (GuiCtrl, *) => GuiCtrl.Gui.Destroy())
    MyGui2.Show("w350")
}

; =============================================================================
; 5. ТЕКСТЫ ПРАВИЛ
; =============================================================================

pp_text := "
(
2.1. Игровой никнейм персонажа должен быть оформлен в формате Имя Фамилия...
[ВСТАВЬТЕ ВАШ ТЕКСТ ПП СЮДА]
)"

pgo_text := "
(
1.1. Сотрудниками государственных организаций являются...
[ВСТАВЬТЕ ВАШ ТЕКСТ ПГО СЮДА]
)"

pko_text := "
(
1.1. Запрещается угон авто в районах: Исторический, Деловой...
[ВСТАВЬТЕ ВАШ ТЕКСТ ПКО СЮДА]
)"

fkz_text := "
(
Глава I. Общие положения
Статья 1. Исполнительная власть Федеральных округов Российской Федерации...
[ВСТАВЬТЕ ВАШ ТЕКСТ ФКЗ СЮДА]
)"

; =============================================================================
; 6. ГОРЯЧИЕ КЛАВИШИ
; =============================================================================

!Up:: {
    Global TargetPlayerID, CurrentIndex, IsActiveTest, IsSkinEvaluated
    RawID := InputBox("Введите 6 цифр ID актера для теста скинов:", "Запуск внутриигрового теста").Value
    if (RawID == "" or !IsInteger(RawID) or StrLen(RawID) != 6) {
        MsgBox("Неверный ID!", "Ошибка")
        return
    }
    TargetPlayerID := SubStr(RawID, 1, 3) "-" SubStr(RawID, 4, 3)
    CurrentIndex := 1
    IsActiveTest := 1
    IsSkinEvaluated := 0
    if FileExist(ResultFilePath)
        FileDelete(ResultFilePath)
    FileAppend("=== ЛОГ ТЕСТИРОВАНИЯ СКИНОВ RMRP ===`n`n", ResultFilePath, "UTF-8")
    UpdateHud("Скин [" CurrentIndex "/" PedsBase.Length "]: " PedsBase[CurrentIndex] "`n🟡 Ожидание оценки...`n[Alt+Влево: Рабочий | Alt+Вправо: Нерабочий]")
    SetTimer(() => SendSkinToGame(), -100)
}

!Left:: {
    Global IsActiveTest
    if (!IsActiveTest)
        return
    SaveResult("РАБОЧИЙ")
}

!Right:: {
    Global IsActiveTest
    if (!IsActiveTest)
        return
    SaveResult("НЕРАБОЧИЙ")
}

!Down:: {
    Global IsActiveTest, IsSkinEvaluated, CurrentIndex
    if (!IsActiveTest)
        return
    if (!IsSkinEvaluated) {
        UpdateHud("Скин [" CurrentIndex "/" PedsBase.Length "]: " PedsBase[CurrentIndex] "`n❌ ОШИБКА: Сначала выберите статус! `n[Alt+Влево: Рабочий | Alt+Вправо: Нерабочий]")
        return
    }
    if (CurrentIndex >= PedsBase.Length) {
        UpdateHud("✅ ТЕСТ ПОЛНОСТЬЮ ЗАВЕРШЕН!`nЛог сохранен на Рабочий стол.")
        IsActiveTest := 0
        MsgBox("Все скины протестированы! Лог на рабочем столе.", "Готово")
        HideTestHud()
        return
    }
    CurrentIndex += 1
    IsSkinEvaluated := 0
    UpdateHud("Скин [" CurrentIndex "/" PedsBase.Length "]: " PedsBase[CurrentIndex] "`n🟡 Ожидание оценки...`n[Alt+Влево: Рабочий | Alt+Вправо: Нерабочий]")
    SendSkinToGame()
}

F10:: {
    static TextGui := 0
    if !IsObject(TextGui) || !TextGui.Visible {
        TextGui := Gui("+AlwaysOnTop +ToolWindow", "Просмотр текста")
        TextGui.SetFont("s10", "Segoe UI")
        TextGui.BackColor := "White"
        EditCtrl := TextGui.Add("Edit", "r20 w600 Multi +Wrap +VScroll", "")
        EditCtrl.Value := A_Clipboard
        BtnClose := TextGui.Add("Button", "w100 Default", "Закрыть")
        BtnClose.OnEvent("Click", (*) => TextGui.Destroy())
        TextGui.Show()
    }
    else {
        TextGui.Destroy()
    }
}

^!c:: {
    if !DirExist(TargetFolder) {
        MsgBox("Указанная папка не найдена!`nПроверь путь в настройках скрипта.", "Ошибка", "Icon! T3")
        return
    }
    DeletedCount := 0
    SoundBeep(600, 150)
    Loop Files TargetFolder "\*.*", "R" {
        FileCreationTime := FileGetTime(A_LoopFileFullPath, "C")
        FileAgeInDays := DateDiff(A_Now, FileCreationTime, "Days")
        if (FileAgeInDays >= DaysToKeep) {
            try {
                FileDelete(A_LoopFileFullPath)
                DeletedCount++
            }
        }
    }
    if (DeletedCount > 0) {
        SoundBeep(800, 200)
        MsgBox("Быстрая очистка завершена!`nУдалено старых откатов: " DeletedCount " шт.", "Успех", "Iconi T3")
    } else {
        MsgBox("Очистка завершена.`nСтарых файлов (старше " DaysToKeep " дней) не обнаружено.", "Инфо", "Iconi T3")
    }
}

Home:: {
    static RulesGui := 0

    if IsObject(RulesGui) && WinExist("ahk_id " RulesGui.Hwnd) {
        if DllCall("IsWindowVisible", "Ptr", RulesGui.Hwnd)
            RulesGui.Hide()
        else
            RulesGui.Show()
        return
    }

    RulesGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Правила RMRP")
    RulesGui.SetFont("s10 cBlack", "Consolas")
    RulesGui.BackColor := "Black"

    BtnPP := RulesGui.Add("Button", "x10 y10 w80 h30", "ПП")
    BtnPGO := RulesGui.Add("Button", "x100 y10 w80 h30", "ПГО")
    BtnPKO := RulesGui.Add("Button", "x190 y10 w80 h30", "ПКО")
    BtnFKZ := RulesGui.Add("Button", "x280 y10 w80 h30", "ФКЗ")
    BtnClose := RulesGui.Add("Button", "x700 y10 w100 h30", "Закрыть")

    EditCtrl := RulesGui.Add("Edit", "x10 y50 w800 h500 ReadOnly +Multi +Wrap +VScroll", "")
    SendMessage(0x00C5, 0x7FFFFFFE, 0, EditCtrl.Hwnd)
    EditCtrl.Value := pp_text

    BtnPP.OnEvent("Click", (*) => EditCtrl.Value := pp_text)
    BtnPGO.OnEvent("Click", (*) => EditCtrl.Value := pgo_text)
    BtnPKO.OnEvent("Click", (*) => EditCtrl.Value := pko_text)
    BtnFKZ.OnEvent("Click", (*) => EditCtrl.Value := fkz_text)
    BtnClose.OnEvent("Click", (*) => RulesGui.Hide())

    RulesGui.Show("x5 y50 NoActivate")
}

!w:: {
    WGui := Gui("+AlwaysOnTop +ToolWindow", "Управление игроком")
    WGui.SetFont("s10", "Segoe UI")
    WGui.Add("Text",, "Введите 6 цифр ID:")
    EdID := WGui.Add("Edit", "w250 Limit6", "")
    WGui.Add("Text",, "Причина (для предов и киков):")
    EdReason := WGui.Add("Edit", "w250", "Помеха съемке")

    Btn1 := WGui.Add("Button", "w250 y+15", "Выдать ПРЕДУПРЕЖДЕНИЕ (+ СМС)")
    Btn1.OnEvent("Click", (*) => CheckAndRun(1, EdID.Value, EdReason.Value, WGui))

    Btn2 := WGui.Add("Button", "w250", "Мгновенный КИК (/dimkick)")
    Btn2.OnEvent("Click", (*) => CheckAndRun(2, EdID.Value, EdReason.Value, WGui))

    Btn3 := WGui.Add("Button", "w250", "Пригласить в мир (/diminvite)")
    Btn3.OnEvent("Click", (*) => CheckAndRun(3, EdID.Value, EdReason.Value, WGui))

    Btn4 := WGui.Add("Button", "w250", "Выдать ПРОВЕРЕННЫЙ СКИН")
    Btn4.OnEvent("Click", (*) => CheckAndRun(4, EdID.Value, EdReason.Value, WGui))

    WGui.Show()
}

CheckAndRun(Type, RawID, Reason, GuiObj) {
    if (RawID ~= "^\d{6}$") {
        ProcessAction(Type, RawID, Reason, GuiObj)
    } else {
        MsgBox("ID должен состоять строго из 6 цифр!", "Ошибка")
    }
}

ProcessAction(Type, RawID, Reason, GuiObj) {
    if (Reason == "" and Type != 4)
        return MsgBox("Заполните цену/причину!", "Ошибка")
    GuiObj.Destroy()
    FID := SubStr(RawID, 1, 3) "-" SubStr(RawID, 4, 3)

    if (Type == 1) {
        WarningsMap[RawID] := WarningsMap.Has(RawID) ? WarningsMap[RawID] + 1 : 1
        ManageLV(1, FID, WarningsMap[RawID], Reason)
        TXT := "/sms " FID " Здравствуйте! Являюсь медиа Вадим Лопатин, выдвигаю вам предупреждение! По причине: " Reason "! После 3 предупреждения будете автоматически кикнуты из деменшена за помеху съемке."
        SetTimer(() => SendCmd(TXT), -200)
    }
    else if (Type == 2) {
        if WarningsMap.Has(RawID)
            WarningsMap.Delete(RawID)
        ManageLV(2, FID)
        SetTimer(() => SendCmd("/dimkick " FID " " Reason), -200)
    }
    else if (Type == 3)
        SetTimer(() => SendCmd("/diminvite " FID " " Reason), -200)
    else if (Type == 4)
        OpenPedsMenu(FID)
}

OpenPedsMenu(TargetID) {
    PM := Gui("+AlwaysOnTop +ToolWindow", "Проверенный гардероб")
    PM.SetFont("s10", "Segoe UI")
    PL := [["Эбигейл", "ig_abigail"], ["Андреас", "ig_andreas"], ["Эшли", "ig_ashley"], ["Пляжный М1", "a_m_m_beach_01"], ["Пляжный М2", "a_m_m_beach_02"], ["Пляжный М3", "a_m_y_beach_02"], ["Пляжная Ж", "a_f_m_beach_01"], ["Жених", "ig_bestmen"], ["Баллас 1", "g_m_y_ballaorig_01"], ["Баллас 2", "g_m_y_ballasout_01"], ["Баллас Ж", "g_f_y_ballas_01"], ["Спецназ/ЧВК", "s_m_y_blackops_02"], ["Бармен", "s_m_m_cntrybar_01"], ["Шеф-Повар", "ig_chef"], ["Повар фастфуда", "s_m_y_chef_01"], ["ДПС (М)", "s_m_y_cop_01"], ["ДПС (Ж)", "s_f_y_cop_01"], ["ФСБ", "s_m_m_fiboffice_02"], ["Охрана", "s_m_m_highsec_02"], ["Почта 1", "s_m_m_postal_01"], ["Почта 2", "s_m_m_postal_02"], ["Учёный", "s_m_m_scientist_01"], ["Шериф (М)", "s_m_y_sheriff_01"], ["Шериф (Ж)", "s_f_y_sheriff_01"]]
    PLV := PM.Add("ListView", "r12 w380 Grid", ["Роль актера", "Код модели"])
    PLV.ModifyCol(1, 230), PLV.ModifyCol(2, 120)
    For p in PL
        PLV.Add(, p[1], p[2])
    PM.Add("Button", "w380 Default", "Выдать скин").OnEvent("Click", (*) => (
        R := PLV.GetNext(),
        R ? (Model := PLV.GetText(R, 2), PM.Destroy(), SetTimer(() => SendCmd("/setmodel " TargetID " " Model), -200)) : 0
    ))
    PM.Show()
}

!v:: {
    static VM := 0
    if IsObject(VM) && WinExist("ahk_id " VM.Hwnd) {
        VM.Show()
        return
    }

    VM := Gui("+AlwaysOnTop +ToolWindow", "Гараж Медиа-Партнера (RMRP)")
    VM.SetFont("s10", "Segoe UI")
    T := VM.Add("Tab3", "w480 h450", ["BMW & Mercedes", "Audi & Porsche", "Суперкары & JDM", "Отечественные", "Гос. и Вертолеты"])

    CList := [
        [
            ["BMW M5 F90 Competition", "bmwm5f90"], ["BMW M8 Competition", "bmwm8"], ["BMW M5 E60", "bmwm5e60"], ["BMW M4 F82", "bmwm4"], ["BMW M3 G80", "bmwm3g80"], ["BMW X5M F95", "bmwx5m"], ["BMW X7 iPerformance", "bmwx7"], ["BMW 750iL E38", "bmwe38"],
            ["Mercedes-Benz G63 AMG (Гелик)", "g63"], ["Mercedes-Benz E63s W213", "e63s"], ["Mercedes-Benz S63 AMG W222", "s63w222"], ["Mercedes-Benz C63s AMG", "c63s"], ["Mercedes-Benz CLS63 AMG (Банан)", "cls63"], ["Mercedes-Benz AMG GT", "amggt"], ["Mercedes-Benz G500 4x4", "g500"], ["Mercedes-Benz E500 (Волчок)", "w124"]
        ],
        [
            ["Audi RS6 Avant C8", "audirs6c8"], ["Audi RS7 Sportback", "audirs7"], ["Audi R8 V10 Plus", "audir8"], ["Audi RS5 Coupé", "audirs5"], ["Audi Q8 RS", "audirsq8"],
            ["Porsche 911 Turbo S (992)", "p911turbos"], ["Porsche Taycan Turbo S", "taycan"], ["Porsche Cayenne Turbo", "cayenne"], ["Porsche Panamera Turbo", "panamera"]
        ],
        [
            ["Bugatti Chiron", "chiron"], ["Bugatti Veyron", "veyron"], ["Ferrari Pista", "488pista"], ["Ferrari LaFerrari", "laferrari"], ["Lamborghini Aventador SVJ", "svj"], ["Lamborghini Urus", "urus"], ["Lamborghini Huracan", "huracan"], ["Rolls-Royce Cullinan", "cullinan"], ["Rolls-Royce Ghost", "ghost"], ["Bentley Bentayga", "bentayga"],
            ["Nissan GT-R R35", "gtr"], ["Toyota Camry v70", "camry70"], ["Toyota Supra A90", "supra"], ["Subaru Impreza WRX STI", "subaru"], ["Mitsubishi Lancer Evolution X", "evo10"]
        ],
        [
            ["ВАЗ 2107 (Семерка)", "vaz2107"], ["ВАЗ 2114 (Четырка)", "vaz2114"], ["Лада Приора", "priora"], ["ВАЗ 2106 (Шестерка)", "vaz2106"], ["ГАЗ-24 (Волга)", "gaz24"], ["УАЗ Патриот", "uaz"], ["Нива Urban 4х4", "niva"],
            ["Toyota Chaser (Дрифт)", "chaser"], ["Nissan Silvia S15 (Дрифт)", "s15"]
        ],
        [
            ["Полиция Крузер (Police Car)", "police"], ["Полиция Интерцептор", "police2"], ["Полиция Крузер Немаркированный", "police4"], ["Шериф Джип (Sheriff SUV)", "sheriff2"], ["ФБР Джип (FBI SUV)", "fbi2"], ["ФБР Седан", "fbi"], ["Скорая Помощь (ЦГБ)", "ambulance"], ["Пожарная Машина", "firetruk"], ["Военный Бронетранспортер", "insurgent"],
            ["Полицейский вертолет (Maverick)", "polmav"], ["Медицинский вертолет (EMS)", "frogger2"], ["Новостной вертолет (News)", "maverick"], ["Военный штурмовой (Buzzard)", "buzzard2"], ["Грузовой вертолет (Cargobob)", "cargobob"], ["Роскошный вертолет (Swift)", "swift2"]
        ]
    ]

    LV_Array := []
    For i, category in CList {
        T.UseTab(i)
        L := VM.Add("ListView", "r15 w460 Grid", ["Название транспорта", "Spawn ID"])
        L.ModifyCol(1, 310), L.ModifyCol(2, 120)
        For c in category
            L.Add("", c[1], c[2])
        LV_Array.Push(L)
    }

    T.UseTab()
    VM.Add("Text", "x15 y+10", "Цвета (0 0 - черный):")
    C1 := VM.Add("Edit", "w50 x15 y+5", "0")
    C2 := VM.Add("Edit", "w50 x+10", "0")

    VM.Add("Button", "w480 x10 y+15 Default", "Заспавнить транспорт").OnEvent("Click", (*) => (
        A := T.Value,
        R := LV_Array[A].GetNext(),
        R ? (Car := LV_Array[A].GetText(R, 2), Col1 := (C1.Value != "" ? C1.Value : "0"), Col2 := (C2.Value != "" ? C2.Value : "0"), VM.Destroy(), SetTimer(() => SendCmd("/sveh " Car " " Col1 " " Col2), -200)) : 0
    ))

    VM.Show("AutoSize Center")
}

F1:: {
    Global MushroomsList
    static MGui := 0
    if IsObject(MGui) && WinExist("ahk_id " MGui.Hwnd) {
        MGui.Hide()
        return
    }
    
    MGui := Gui("+AlwaysOnTop +ToolWindow", "Грибы RMRP — Шпаргалка")
    MGui.SetFont("s10", "Segoe UI")
    
    MTab := MGui.Add("Tab3", "w400 h420", ["Цены и Шансы", "Карта зон сбора"])
    
    ; --- Вкладка 1: Цены и Шансы ---
    MTab.UseTab(1)
    MLV := MGui.Add("ListView", "r16 w380 Grid -Multi", ["Название", "Цена", "Шанс"])
    MLV.ModifyCol(1, 200)
    MLV.ModifyCol(2, 90)
    MLV.ModifyCol(3, 70)
    For m in MushroomsList
        MLV.Add(, m[1], m[2], m[3])
        
    ; --- Вкладка 2: Карта ---
    MTab.UseTab(2)
    MapPath := A_ScriptDir "\map.png"
    
    if FileExist(MapPath) {
        MGui.Add("Picture", "w380 h-1", MapPath)
    } else {
        MGui.Add("Text", "w380 h300 Center", "Карта не найдена!`n`nЧтобы она отображалась здесь:`n1. Сохраните карту как map.png`n2. Положите файл в папку со скриптом.")
    }
    
    MTab.UseTab()
    MGui.Show("AutoSize Center")
}

F11:: {
    Global IsGuiVisible
    IsGuiVisible := !IsGuiVisible
    if (IsGuiVisible)
        MyGui.Show("NoActivate")
    else
        MyGui.Hide()
}

F2:: SetTimer(() => SendCmd("/mediadimension"), -200)
!c:: SetTimer(() => SendCmd("/clearvehicles"), -200)
F12:: (WarningsMap.Clear(), LV.Delete(), ToolTip("Таблица очищена"), SetTimer(() => ToolTip(), -2000))

NumpadAdd:: {
    global ReportCount += 1
    SaveAndShowReports()
}

NumpadSub:: {
    global ReportCount
    if (ReportCount > 0) {
        ReportCount -= 1
        SaveAndShowReports()
    }
}

PgUp:: ShowToolTip("Репортов за сегодня: " ReportCount)
PgDn:: ShowHelpWindow()

Delete:: {
    Result := MsgBox("Вы уверены, что хотите обнулить репорты?", "Сброс счетчика", "YesNo Icon? Default2")
    if (Result = "Yes") {
        global ReportCount := 0
        SaveAndShowReports()
        ShowToolTip("Счетчик сброшен!")
    }
}

F8:: {
    if FileExist(TempFile)
        FileDelete(TempFile)

    PsCommand := "[Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null; "
              . "[Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; "
              . "$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; "
              . "$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height); "
              . "$g = [System.Drawing.Graphics]::FromImage($bmp); "
              . "$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size); "
              . "$bmp.Save('" TempFile "'); $g.Dispose(); $bmp.Dispose();"

    RunWait("powershell -NoProfile -Command `"" PsCommand "`"", , "Hide")

    if !FileExist(TempFile) {
        MsgBox("Не удалось сделать скриншот!`nПроверьте путь: " TempFile, "Ошибка", "IconX")
        return
    }
    MainMenu.Show()
}

::/md::/mediadimension
::/di::/diminvite
::/dk::/dimkick
::/sm::/setmodel
::/sv::/sveh
::/cv::/clearvehicles

ShowHelpWindow()
