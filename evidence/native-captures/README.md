# Native desktop review captures

These are real Godot 4.6.3 renders, captured from the native project's viewport or
its full X11 window. They are original pixels, with no resizing, compositing or
browser/concept-art substitution. Each matrix includes eight actual native screens. The compact layout also has three additional scroll/pause QA captures.

- `desktop-1280x720`: landscape desktop viewport captures.
- `desktop-phone-800x450`: compact phone-shaped desktop viewport plus real parts-scroll, bottom-navigation and pause-modal QA captures. This is not a physical phone capture.
- `desktop-1600x1000`: landscape tablet-shaped desktop window, including the game's
  intentional letterboxing. This is not an iPad or Android tablet capture.
- `capture-results.json` beside each matrix records dimensions, scene descriptions,
  SHA-256 hashes, renderer, host CPU, load timing, memory and frame samples.
- `../native-performance.json` aggregates the actual desktop measurements.

Fresh isolated user-data directories protect existing saves. Captures 3–8 seed a
reachable unlocked state and a seven-section private track for review; model,
input, rendering and UI are the actual game. This does not prove naturally earned
progress, child comprehension, physical touch input or device performance.

Reproduce with Godot, Mesa and an X11 display:

```sh
python scripts/capture_native.py
python scripts/capture_native.py --width 800 --height 450 --label desktop-phone-800x450
python scripts/capture_native.py --width 1600 --height 1000 --label desktop-1600x1000
```

The script starts installed Xorg with its dummy driver. A sandbox must permit local
UNIX sockets. Alternatively supply `--display :89` for an existing display.

The optional actual gameplay video is a silent 22-second Linux desktop draft at
`builds/native-gameplay-desktop.mp4`, produced by
`python scripts/capture_native_trailer.py --display :89`. Its source sequence and
hash/probe evidence are in `trailer-evidence.json`. It is not a store-approved
app-preview movie. Device-specific store screenshots, physical-device video and
store metadata approval remain release work.

The final 800×450 and 1280×720 review matrices include observed source SHA-256 snapshots with their recording method and limitations. The 1600×1000 matrix and trailer predate the final compact layout/paint-heading correction; their exact loaded source hashes were not recorded. They remain genuine native development review captures, not proof of a byte-identical final exported binary. Future tooling records source hashes immediately before engine launch and checks them again afterward.
