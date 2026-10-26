# Native performance evidence and current3Dacceptance

Current3Dsource captures are reproduced with `python scripts/capture_3d.py` and recorded with source hashes and scene scope in the current delivery evidence. They are short Linux/llvmpipe renderer samples, not named-phone GPU, thermal or battery measurements. The current-build phase must measure actual Valley/Marsh driving, demanding existing Canyon/Summit geometry, effects/finish activity and editor/QuickDrive comparison on named supported hardware. Record loading, p50/p95/p99/max frame times, native/process/GPU memory separately and at least10minutes sustained play with battery/thermal state. Select a supported60fps target or justified30fps mode only from that evidence. No new content or speculative optimization is needed to collect it.

The2026-10-25 investigation below is specifically **2DQuickDrive RiverBridges**. Its earlier1600×1000 capture averaged40.77fps; the repeatable component benchmark isolates that scene's frame costs. It does not diagnose3Dbottlenecks or satisfy mobile acceptance. Keep its actual logs as historical evidence rather than treating a new3Dbuild as a rerun.

## Reproduce

```sh
python scripts/benchmark_native.py --width 1600 --height 1000 --frames 180 --label baseline-1600x1000
```

Requires the pinned Godot4.6.3 executable, Xorg with its dummy driver, Mesa and permission to create local X11 sockets. The helper creates a temporary display and isolated application/config/cache directories, uses the actual native main scene, and shuts down its display afterward. It writes evidence under `evidence/native-benchmark/<label>/`. Existing displays can be selected with `--display`.

`native/tests/benchmark.gd` is developer-only tooling excluded by every export preset. It subclasses the actual world renderer solely to time synchronous drawing-command generation; it does not replace the simulation, scenery, parts, controls or terrain. The actual main scene selects Parcel Truck with trail tires and firm springs on River Bridges. It warms90rendered frames, then samples180frames per scenario. The model advances exactly1/60second per sampled rendered frame, making all three moving scenarios reach the same route position even when renderer speed differs. No production save is touched.

## Actual baseline result

Host: Linux6.18.55x86_64, AMD EPYC9V7480-Core Processor (5logical CPUs exposed), Mesa25.0.7/llvmpipe LLVM19.1.7 software renderer, Compatibility/OpenGL4.5, Xorg dummy1600×1000. Raw logs and runtime source SHA-256 fingerprints are in `evidence/native-benchmark/baseline-1600x1000/`.

| Scenario | Mean frame | p95frame | What it isolates |
|---|---:|---:|---|
| Full scene |22.01ms|24.80ms|Real moving game/model/UI; about45.4fps in this run |
| World only |20.10ms|23.06ms|Same moving model/world, actual UI hidden |
| UI only |7.17ms|8.33ms|Same model/UI updates, world hidden |
| Frozen canvas |19.98ms|24.14ms|Last warmup picture retained, redraw and simulation stopped; diagnostic only |

Synchronous GDScript world drawing-command submission averaged**0.765ms**, p95**0.864ms** in the full scene. Full-scene rendering averaged about118draw calls and8,696primitives. The three moving scenarios ended at the same `x=709.35903980454,y=410` state. All runtime source fingerprints remained unchanged during the run.

The large majority of the frame cost persists when the canvas is frozen and GDScript is no longer generating world commands. Terrain calculations, temporary arrays and StyleBox allocation inside `_draw()` therefore are not the dominant measured bottleneck on this host. Caching those small CPU costs cannot be presented as a demonstrated cure for the below60fps software-render result. Raster/render workload on this software device is the stronger next profiling target; actual mobile GPU measurements must decide whether that is also a supported-device bottleneck.

The driver emitted a warning that changing VSync mode is unsupported. The command requests `--disable-vsync`; that warning is retained in the log. UI-only renders faster than60fps, but no universal claim about driver synchronization is inferred. Frame-rate variation from prior capture results is expected: different warmup/route/capture workloads and host scheduling make these separate measurements, not a before/after optimization comparison.

## Limits and next action

No runtime optimization was applied without a demonstrated benefit. No art, effects, course geometry, drawing detail, text resolution or launch content was reduced. The frozen-canvas number is not a gameplay result and must not be used to advertise performance. Component measurements are diagnostics, not additive costs: engine monitor values update at engine intervals and can include rendering/waits; they should not be subtracted as if all were independent CPU timers.

Godot allocator memory and Linux child maximumRSS are recorded separately; neither substitutes for mobile resident/thermal/battery measurements. No supported Android/iOS floor,60fps device pass or justified lower-device target has been approved. Device QA must measure representative scenes on named supported hardware before closing the P1performance gate. If mobile profiling shows a renderer bottleneck, compare a precise visual-preserving change with this same replay and actual-device before/after traces; do not optimize from desktop llvmpipe timings alone.
