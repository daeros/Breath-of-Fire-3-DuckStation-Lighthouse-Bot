# Technical Notes

## Detection pipeline

`F8` performs the following sequence:

1. Activate the DuckStation window.
2. Search the upper portion of the window for one of several known graph-green colors.
3. Use that hit as an anchor to reconstruct the boiler graph rectangle.
4. Derive the four marker regions from normalized positions inside the graph.
5. Wait for a synchronized marker flash.
6. Wait for a second synchronized marker flash.
7. Measure the period between the two flash onsets.
8. Reject obviously invalid periods.
9. Predict the next flash time.
10. Send K `LeadMs` before that predicted time.

## Marker test

The release uses a bright-marker reference near:

```text
0xD0E0A0
```

with a variation of:

```text
55
```

The bot checks all four marker regions and treats the event as synchronized when at least three of the four are bright.

This is intentionally more tolerant than demanding all four markers, because filtering and scaling can slightly change individual regions.

## Timing

Default:

```text
LeadMs = 140
```

A larger value fires earlier.

A smaller value fires later.

F5 decreases `LeadMs` by 20 ms.

F6 increases `LeadMs` by 20 ms.

## Input delivery

The script uses the Win32 `keybd_event` API for host key `K` because this input path was found to work reliably with the tested DuckStation configuration.

The script avoids re-activating DuckStation at the critical firing instant because window activation itself can introduce latency.

## Timer resolution

The script requests a 1 ms Windows timer period with:

```text
timeBeginPeriod(1)
```

and releases it when exiting through F10.

Near the target time, the scheduler transitions from coarse sleeps to 1 ms sleeps.

## Expected cycle period

The script accepts measured periods between:

```text
4300 ms and 5400 ms
```

The tested boiler sequence is approximately 4.8 seconds per synchronized event.

## Portability considerations

Things that can affect visual detection:

- emulator shaders;
- HDR conversion;
- color grading;
- unusual scaling;
- emulator UI/layout changes;
- non-standard game speed;
- future DuckStation rendering changes.

If detection problems appear on another system, useful issue-report data includes:

- DuckStation version;
- graphics backend;
- display resolution;
- Windows scaling percentage;
- game/video FPS shown by DuckStation;
- whether F7 works;
- F9 output;
- screenshots of the normal and bright marker states.
