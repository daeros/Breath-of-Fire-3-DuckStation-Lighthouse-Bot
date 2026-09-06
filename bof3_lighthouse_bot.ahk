#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#MaxThreadsPerHotkey 1
#WinActivateForce

; ============================================================================
; BOF3 Lighthouse Bot v1.0.0
; Breath of Fire III Lighthouse boiler timing helper
; DuckStation / Windows / AutoHotkey v2
;
; Hotkeys:
;   F5  = move automatic press 20 ms later
;   F6  = move automatic press 20 ms earlier
;   F7  = test the K input path
;   F8  = run full automatic timing
;   F9  = graph / marker diagnostic
;   F10 = quit
;
; Default successful timing:
;   140 ms before the predicted marker flash
;
; How it works:
;   1. Finds the green Lighthouse boiler graph automatically.
;   2. Detects two synchronized marker flashes.
;   3. Measures the live cycle period.
;   4. Predicts the next flash.
;   5. Sends K 140 ms before the predicted flash.
;
; The DuckStation action you want to trigger must be bound to host key K.
; ============================================================================

global KHoldMs := 120
global PollMs := 3

; Default timing tuned for the Lighthouse boiler sequence.
; Larger LeadMs = EARLIER.
; Smaller LeadMs = LATER.
global LeadMs := 140

global DuckExe := "duckstation-qt-x64-ReleaseLTCG-SSE2.exe"
global DuckTitle := "Breath of Fire III"

; ---------------------------------------------------------------------------
; GRAPH SEEKING -- retained from the working v23 detector
; ---------------------------------------------------------------------------

global GraphGreen1 := 0x008000
global GraphGreen2 := 0x006E00
global GraphGreen3 := 0x236013

global SeedToGraphXFrac := 0.0107
global SeedToGraphYFrac := 0.0135
global GraphWidthFrac   := 0.2081
global GraphHeightFrac  := 0.2623

; Marker centers inside detected graph.
global TopMarkerXFrac    := 0.5111
global TopMarkerYFrac    := 0.1767

global BottomMarkerXFrac := 0.5111
global BottomMarkerYFrac := 0.8397

global LeftMarkerXFrac   := 0.1063
global LeftMarkerYFrac   := 0.5069

global RightMarkerXFrac  := 0.9041
global RightMarkerYFrac  := 0.5069

; Bright marker color used for the synchronized boiler markers:
; false positives are reduced by requiring at least 3 of 4 markers.
global BrightMarkerColor := 0xD0E0A0
global BrightMarkerVariation := 55

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")
SetTitleMatchMode(2)

; Improve millisecond Sleep resolution for the final scheduled press.
try DllCall("winmm\timeBeginPeriod", "UInt", 1)

; Keep integrity level matched with DuckStation.
if !A_IsAdmin
{
    try
    {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        ExitApp()
    }
}

ShowStatus(
    "BOF3 Lighthouse Bot v1.0.0`n"
    . "F7 = test K`n"
    . "F8 = FULL AUTO timing`n"
    . "F5 = later   F6 = earlier`n"
    . "F9 = diagnostic`n"
    . "F10 = quit",
    5000
)

; ============================================================================
; HOTKEYS
; ============================================================================

F7::
{
    KeyWait("F7")

    if !PressKInDuckStation()
    {
        SoundBeep(280, 350)
        ShowStatus("F7 FAILED.", 2500)
        return
    }

    SoundBeep(1200, 100)
    ShowStatus("F7: K SENT.", 1800)
}


F8::
{
    global LeadMs

    KeyWait("F8")

    if !ActivateDuckStation()
    {
        SoundBeep(280, 350)
        ShowStatus("F8: DuckStation activation failed.", 3000)
        return
    }

    Sleep(80)

    hwnd := FindDuckStation()
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)

    ; Get the pointer completely out of the graph.
    MouseMove(wx + ww - 20, wy + wh - 20, 0)

    ShowStatus("Seeking boiler graph...", 1200)

    if !FindGraphAndMarkers(
        &gl, &gt, &gw, &gh,
        &topX, &topY,
        &botX, &botY,
        &leftX, &leftY,
        &rightX, &rightY
    )
    {
        SoundBeep(250, 400)

        ShowStatus(
            "COULD NOT FIND BOILER GRAPH`n"
            . "Leave the graph visible and press F8 again.",
            4500
        )
        return
    }

    SoundBeep(550, 70)

    ShowStatus(
        "GRAPH FOUND`n"
        . "Learning live boiler period...`n"
        . "Waiting for flash 1/2",
        2200
    )

    ; ------------------------------------------------------------------------
    ; Flash #1.
    ; WaitForFlash returns the timestamp of the FIRST qualifying sample,
    ; not the later confirmation sample.
    ; ------------------------------------------------------------------------

    t1 := WaitForFlash(
        topX, topY,
        botX, botY,
        leftX, leftY,
        rightX, rightY,
        gw, gh,
        9000
    )

    if !t1
    {
        SoundBeep(250, 400)
        ShowStatus("FLASH 1 NOT DETECTED.", 4000)
        return
    }

    SoundBeep(750, 80)

    ShowStatus(
        "FLASH 1/2 FOUND`n"
        . "Waiting for flash 2/2...",
        1500
    )

    ; ------------------------------------------------------------------------
    ; Flash #2.
    ; ------------------------------------------------------------------------

    t2 := WaitForFlash(
        topX, topY,
        botX, botY,
        leftX, leftY,
        rightX, rightY,
        gw, gh,
        7000
    )

    if !t2
    {
        SoundBeep(250, 400)
        ShowStatus("FLASH 2 NOT DETECTED.", 4000)
        return
    }

    period := t2 - t1

    ; Recorded cycles are around 4.8 seconds.
    ; Reject a false event instead of pressing randomly.
    if (period < 4300 || period > 5400)
    {
        SoundBeep(250, 450)

        ShowStatus(
            "BAD CYCLE MEASUREMENT`n"
            . "period=" period " ms`n"
            . "Expected roughly 4800 ms.`n"
            . "K NOT SENT.",
            5000
        )
        return
    }

    SoundBeep(900, 80)
    SoundBeep(1100, 80)

    ; Predict next marker flash, then back up by LeadMs.
    fireAt := t2 + period - LeadMs

    remaining := fireAt - A_TickCount

    ShowStatus(
        "TIMING LOCKED`n"
        . "cycle=" period " ms`n"
        . "lead=" LeadMs " ms`n"
        . "K in ~" Round(remaining / 1000.0, 2) " sec",
        3000
    )

    ; IMPORTANT:
    ; Do not call WinActivate at the critical moment.
    ; DuckStation is already foreground.  Earlier versions added activation
    ; latency here and ruined otherwise-correct timing.
    WaitUntil(fireAt)

    ; K goes down immediately when the predicted pre-flash instant arrives.
    if !SendKNow()
    {
        SoundBeep(250, 450)

        ShowStatus(
            "FIRE TIME REACHED`n"
            . "but DuckStation lost focus.`n"
            . "K NOT SENT.",
            4500
        )
        return
    }

    ; Only beep AFTER the key has already been delivered.
    SoundBeep(1550, 140)

    ShowStatus(
        "K SENT BEFORE FLASH`n"
        . "cycle=" period " ms`n"
        . "lead=" LeadMs " ms`n"
        . "F5=later  F6=earlier",
        5000
    )
}


F5::
{
    global LeadMs

    ; Smaller lead = later.
    LeadMs := Max(20, LeadMs - 20)

    SoundBeep(650, 70)

    ShowStatus(
        "TIMING MOVED LATER`n"
        . "lead=" LeadMs " ms",
        1800
    )
}


F6::
{
    global LeadMs

    ; Larger lead = earlier.
    LeadMs += 20

    SoundBeep(900, 70)

    ShowStatus(
        "TIMING MOVED EARLIER`n"
        . "lead=" LeadMs " ms",
        1800
    )
}


F9::
{
    if !ActivateDuckStation()
        return

    if !FindGraphAndMarkers(
        &gl, &gt, &gw, &gh,
        &topX, &topY,
        &botX, &botY,
        &leftX, &leftY,
        &rightX, &rightY
    )
    {
        ShowStatus("F9: graph not found.", 3500)
        return
    }

    lit := CountBrightMarkers(
        topX, topY,
        botX, botY,
        leftX, leftY,
        rightX, rightY,
        gw, gh
    )

    ShowStatus(
        "BOF3 v1.0.0 GRAPH FOUND`n"
        . "graph " gl "," gt " " gw "x" gh "`n"
        . "TOP " topX "," topY
        . "  BOT " botX "," botY "`n"
        . "LEFT " leftX "," leftY
        . "  RIGHT " rightX "," rightY "`n"
        . "bright right now: " lit "/4",
        7000
    )
}


F10::
{
    try DllCall("winmm\timeEndPeriod", "UInt", 1)
    ExitApp()
}

; ============================================================================
; FLASH TIMING
; ============================================================================

WaitForFlash(
    topX, topY,
    botX, botY,
    leftX, leftY,
    rightX, rightY,
    gw, gh,
    TimeoutMs
)
{
    global PollMs

    started := A_TickCount

    ; First require a clean non-flash state.
    ; This prevents the tail of an existing flash from being counted.
    dimSamples := 0

    while (dimSamples < 3)
    {
        if ((A_TickCount - started) > TimeoutMs)
            return 0

        lit := CountBrightMarkers(
            topX, topY,
            botX, botY,
            leftX, leftY,
            rightX, rightY,
            gw, gh
        )

        if (lit <= 1)
            dimSamples += 1
        else
            dimSamples := 0

        Sleep(PollMs)
    }

    ; Now catch the next rising event.
    ; We require two observations >=3/4, but preserve the timestamp
    ; of the FIRST observation so confirmation doesn't shift our phase.
    brightSamples := 0
    candidateTick := 0

    loop
    {
        if ((A_TickCount - started) > TimeoutMs)
            return 0

        lit := CountBrightMarkers(
            topX, topY,
            botX, botY,
            leftX, leftY,
            rightX, rightY,
            gw, gh
        )

        if (lit >= 3)
        {
            if (brightSamples = 0)
                candidateTick := A_TickCount

            brightSamples += 1

            if (brightSamples >= 2)
                return candidateTick
        }
        else
        {
            brightSamples := 0
            candidateTick := 0
        }

        Sleep(PollMs)
    }
}


WaitUntil(TargetTick)
{
    ; Coarse sleep far away, fine sleep near target.
    ; timeBeginPeriod(1) is enabled at startup.
    loop
    {
        remaining := TargetTick - A_TickCount

        if (remaining <= 0)
            return

        if (remaining > 60)
            Sleep(15)
        else if (remaining > 20)
            Sleep(5)
        else if (remaining > 6)
            Sleep(2)
        else
            Sleep(1)
    }
}

; ============================================================================
; GRAPH SEEKER
; ============================================================================

FindGreenSeed(&seedX, &seedY, wx, wy, ww, wh)
{
    global GraphGreen1, GraphGreen2, GraphGreen3

    sx1 := wx + Round(ww * 0.20)
    sx2 := wx + Round(ww * 0.80)

    sy1 := wy + Round(wh * 0.04)
    sy2 := wy + Round(wh * 0.43)

    try
    {
        if PixelSearch(
            &seedX, &seedY,
            sx1, sy1,
            sx2, sy2,
            GraphGreen1,
            35
        )
            return true
    }

    try
    {
        if PixelSearch(
            &seedX, &seedY,
            sx1, sy1,
            sx2, sy2,
            GraphGreen2,
            28
        )
            return true
    }

    try
    {
        if PixelSearch(
            &seedX, &seedY,
            sx1, sy1,
            sx2, sy2,
            GraphGreen3,
            24
        )
            return true
    }

    return false
}


FindGraphAndMarkers(
    &gl, &gt, &gw, &gh,
    &topX, &topY,
    &botX, &botY,
    &leftX, &leftY,
    &rightX, &rightY
)
{
    global SeedToGraphXFrac, SeedToGraphYFrac
    global GraphWidthFrac, GraphHeightFrac
    global TopMarkerXFrac, TopMarkerYFrac
    global BottomMarkerXFrac, BottomMarkerYFrac
    global LeftMarkerXFrac, LeftMarkerYFrac
    global RightMarkerXFrac, RightMarkerYFrac

    hwnd := FindDuckStation()

    if !hwnd
        return false

    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)

    if !FindGreenSeed(&seedX, &seedY, wx, wy, ww, wh)
        return false

    gl := seedX + Round(ww * SeedToGraphXFrac)
    gt := seedY + Round(wh * SeedToGraphYFrac)

    gw := Round(ww * GraphWidthFrac)
    gh := Round(wh * GraphHeightFrac)

    if (gl < wx || gt < wy)
        return false

    if ((gl + gw) > (wx + ww) || (gt + gh) > (wy + wh))
        return false

    topX := gl + Round(gw * TopMarkerXFrac)
    topY := gt + Round(gh * TopMarkerYFrac)

    botX := gl + Round(gw * BottomMarkerXFrac)
    botY := gt + Round(gh * BottomMarkerYFrac)

    leftX := gl + Round(gw * LeftMarkerXFrac)
    leftY := gt + Round(gh * LeftMarkerYFrac)

    rightX := gl + Round(gw * RightMarkerXFrac)
    rightY := gt + Round(gh * RightMarkerYFrac)

    return true
}

; ============================================================================
; MARKER DETECTION
; ============================================================================

MarkerIsBright(cx, cy, gw, gh)
{
    global BrightMarkerColor, BrightMarkerVariation

    halfW := Max(14, Round(gw * 0.085))
    halfH := Max(8, Round(gh * 0.045))

    try
    {
        return PixelSearch(
            &px, &py,
            cx - halfW,
            cy - halfH,
            cx + halfW,
            cy + halfH,
            BrightMarkerColor,
            BrightMarkerVariation
        )
    }
    catch
    {
        return false
    }
}


CountBrightMarkers(
    topX, topY,
    botX, botY,
    leftX, leftY,
    rightX, rightY,
    gw, gh
)
{
    count := 0

    if MarkerIsBright(topX, topY, gw, gh)
        count += 1

    if MarkerIsBright(botX, botY, gw, gh)
        count += 1

    if MarkerIsBright(leftX, leftY, gw, gh)
        count += 1

    if MarkerIsBright(rightX, rightY, gw, gh)
        count += 1

    return count
}

; ============================================================================
; DUCKSTATION / KNOWN-GOOD K INPUT
; ============================================================================

FindDuckStation()
{
    global DuckExe, DuckTitle

    hwnd := WinExist("ahk_exe " DuckExe)

    if hwnd
        return hwnd

    for exe in [
        "duckstation-qt-x64-ReleaseLTCG.exe",
        "duckstation-qt-x64.exe",
        "duckstation.exe"
    ]
    {
        hwnd := WinExist("ahk_exe " exe)

        if hwnd
            return hwnd
    }

    hwnd := WinExist(DuckTitle)

    if hwnd
        return hwnd

    return 0
}


ActivateDuckStation()
{
    hwnd := FindDuckStation()

    if !hwnd
        return 0

    selector := "ahk_id " hwnd

    try WinRestore(selector)
    try WinActivate(selector)

    if WinWaitActive(selector, , 0.80)
        return hwnd

    try DllCall(
        "user32\SwitchToThisWindow",
        "Ptr", hwnd,
        "Int", 1
    )

    Sleep(80)

    if WinActive(selector)
        return hwnd

    try WinSetAlwaysOnTop(1, selector)
    Sleep(20)
    try WinActivate(selector)
    Sleep(80)
    try WinSetAlwaysOnTop(0, selector)

    if WinWaitActive(selector, , 0.60)
        return hwnd

    return 0
}


PressKInDuckStation()
{
    hwnd := ActivateDuckStation()

    if !hwnd
        return false

    Sleep(80)

    return SendKNow()
}


SendKNow()
{
    global KHoldMs

    hwnd := FindDuckStation()

    if !hwnd
        return false

    ; During F8 automation DuckStation is already active.
    ; Do NOT call WinActivate here.
    if !WinActive("ahk_id " hwnd)
        return false

    ; K DOWN immediately.
    DllCall(
        "user32\keybd_event",
        "UChar", 0x4B,
        "UChar", 0x25,
        "UInt", 0,
        "UPtr", 0
    )

    Sleep(KHoldMs)

    ; K UP.
    DllCall(
        "user32\keybd_event",
        "UChar", 0x4B,
        "UChar", 0x25,
        "UInt", 0x0002,
        "UPtr", 0
    )

    return true
}

; ============================================================================
; UI
; ============================================================================

ShowStatus(Text, DurationMs := 1800)
{
    ToolTip(Text, 25, 25)
    SetTimer(() => ToolTip(), -DurationMs)
}
