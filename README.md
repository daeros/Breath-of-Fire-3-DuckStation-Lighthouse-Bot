# BOF3 Lighthouse Bot

A small AutoHotkey v2 helper for the **Lighthouse boiler timing minigame in Breath of Fire III** when playing in **DuckStation on Windows**.

The script automatically finds the boiler graph, watches the four timing markers, measures the live cycle, predicts the next synchronization point, and presses the configured host key shortly **before** the visible flash.

The default release timing is **140 ms early**, which was the successful setting during testing.

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/)
- DuckStation
- Breath of Fire III
- DuckStation running the game at normal speed
- The intended DuckStation controller action bound to host keyboard key **K**
- Configuration.
  
## Quick start

1. Install AutoHotkey v2.
2. Download `bof3_lighthouse_bot.ahk`.
3. In DuckStation, make sure the button/action you need for the boiler is bound to **K**.
4. Load the Lighthouse boiler sequence and leave the green graph visible.
5. Run `bof3_lighthouse_bot.ahk`.
6. Press **F7** once to confirm the script can send K to DuckStation.
7. Reload your save state if needed.
8. Press **F8** and leave DuckStation in the foreground.

The bot will:

1. locate the green boiler graph;
2. detect two synchronized marker flashes;
3. measure the actual cycle period;
4. predict the next flash;
5. press **K 140 ms before** the predicted flash.

## Hotkeys

| Key | Action |
|---|---|
| **F5** | Move the automatic press 20 ms **later** |
| **F6** | Move the automatic press 20 ms **earlier** |
| **F7** | Test the K input path |
| **F8** | Run the full automatic timing sequence |
| **F9** | Show graph/marker diagnostic information |
| **F10** | Exit the bot |

### Timing adjustment

The default lead is:

```text
140 ms early
```

If your setup behaves slightly differently:

- press **F6** to make the input 20 ms earlier;
- press **F5** to make the input 20 ms later.

The adjustment remains active until the script exits.

## What the bot detects

The Lighthouse graph has four small timing markers around the grid. The bot looks for the synchronized bright state of those markers rather than trying to follow the moving pressure trace.

To reduce false detections it requires at least **3 of 4 markers** to match the bright-state test.

After detecting two flashes, it measures the live period instead of assuming a hard-coded cycle length.

## Why it presses before the flash

Pressing at the visible flash is too late. The successful timing is slightly before it.

At the game's 30 FPS logic rate:

- 3 frames is about 100 ms;
- 4 frames is about 133 ms.

The tested default is **140 ms early**.

## Troubleshooting

### F7 does not press K

Check that:

- DuckStation is running;
- the game window title contains `Breath of Fire III`;
- your DuckStation mapping really uses host key **K**;
- AutoHotkey v2 is installed.

The script may relaunch itself as administrator so its integrity level matches DuckStation.

### F8 says it cannot find the graph

Make sure:

- the Lighthouse boiler graph is visible;
- DuckStation is not minimized;
- the game is running at normal speed;
- heavy shaders, unusual color filters, HDR conversion, or extreme post-processing are disabled.

Press **F9** for diagnostic information.

### It detects the flashes but misses the timing

Use:

- **F6** for 20 ms earlier;
- **F5** for 20 ms later.

If a different lead works consistently on your system, please open an issue with the working value.

### It reports a bad cycle measurement

The script expects a cycle roughly in the 4.3-5.4 second range. Make sure DuckStation is at normal emulation speed and that fast-forward is off.

## Required configuration

Most users should only need to change a few variables near the top of
`bof3_lighthouse_bot.ahk`.

### DuckStation executable name

The script was originally tested with:

```ahk
global DuckExe := "duckstation-qt-x64-ReleaseLTCG-SSE2.exe"
Your DuckStation executable may have a different name.

For example:

global DuckExe := "duckstation.exe"

or:

global DuckExe := "duckstation-qt-x64-ReleaseLTCG.exe"

To find yours:

Start DuckStation.
Open Windows Task Manager.
Go to the Details tab.
Find the DuckStation process.
Copy the exact .exe filename into DuckExe.

The script also automatically tries these common fallback names:

duckstation-qt-x64-ReleaseLTCG.exe
duckstation-qt-x64.exe
duckstation.exe

so you may not need to change anything if your build uses one of those names.

## Limitations

- Windows only.
- AutoHotkey v2 only.
- Designed specifically for DuckStation and this Breath of Fire III Lighthouse sequence.
- Visual detection can be affected by shaders, color-changing filters, HDR, unusual scaling, or emulator UI changes.
- The script intentionally does not modify game memory or save data.

## Project status

Version **1.0.0** is the first public release.

Bug reports are welcome, especially from different DuckStation versions, resolutions, scaling factors, and graphics backends.

## Disclaimer

This is an unofficial fan-made utility. It is not affiliated with or endorsed by Capcom, DuckStation, Sony, or the AutoHotkey project.

Breath of Fire and related trademarks belong to their respective owners.

## License

MIT. See [LICENSE](LICENSE).
