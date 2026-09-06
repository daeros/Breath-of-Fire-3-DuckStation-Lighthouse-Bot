# BOF3 Lighthouse Bot v1.0.0

First public release.

## What it does

BOF3 Lighthouse Bot automates the timing portion of the Breath of Fire III Lighthouse boiler minigame in DuckStation on Windows.

It automatically:

- finds the green boiler graph;
- detects synchronized timing-marker flashes;
- measures the live cycle period;
- predicts the next synchronization point;
- presses K **140 ms before** the predicted flash.

## Controls

- **F5** - 20 ms later
- **F6** - 20 ms earlier
- **F7** - test K
- **F8** - full automatic timing
- **F9** - diagnostic
- **F10** - quit

## Requirements

- Windows
- AutoHotkey v2
- DuckStation
- Breath of Fire III
- target DuckStation action mapped to host key K
- normal emulation speed

## Tested default

The successful default lead is:

```text
140 ms early
```

If your setup needs a small adjustment, F5/F6 change the lead in 20 ms increments.

## Notes

This is an unofficial fan utility and is not affiliated with Capcom, DuckStation, Sony, or AutoHotkey.
