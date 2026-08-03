# KURUKURU Shelf-only design QA

## Evidence

- Source visual truth for the requested split: `/var/folders/7n/g59dsf391lq943zpscxlcxg80000gn/T/codex-clipboard-c8bce6dd-77c5-455f-b39f-60bf1861a695.png`.
- Source visual truth for the complete device and previous full-width bar: `/var/folders/7n/g59dsf391lq943zpscxlcxg80000gn/T/codex-clipboard-ca58907d-1052-4a39-82d9-63105f0e2226.png`.
- Empty Shelf implementation: `/private/tmp/dopagak-shelf-only-final/kurukuru-preview.png`.
- Populated Shelf implementation: `/private/tmp/dopagak-shelf-only-final/kurukuru-populated-preview.png`.
- Transparent-window implementation: `/private/tmp/dopagak-shelf-only-final/kurukuru-window-alpha.png`.
- Full-view comparison evidence: `/private/tmp/dopagak-shelf-only-final/full-device-comparison.png`.
- Focused screen comparison evidence: `/private/tmp/dopagak-shelf-only-final/half-width-focused-comparison.png`.
- Focused populated-state evidence: `/private/tmp/dopagak-shelf-only-final/kurukuru-populated-screen-focused.png`.
- Viewport: deterministic 500 × 600 pt native SwiftUI render at 2× scale; focused screen crop is 212 × 153 pt at 2×.
- States: front-facing hardware with an empty Shelf, plus a populated three-item Shelf with the first row selected.

## Required fidelity surfaces

- Fonts and typography: the display uses compact native weights, a narrow 22 pt status bar, bold selected-row text, middle truncation for long filenames, and small monospaced metadata. No visible copy wraps or clips in either captured state.
- Spacing and layout rhythm: the 212 pt display is split at exactly 106 pt. The status bar exists only inside the left pane; the navy detail pane begins at the top edge and continues to the bottom edge. The 272 × 362 pt body, 230 × 167 pt outer display, 142 pt wheel, and screen-to-wheel spacing remain unchanged.
- Colors and visual tokens: the left pane preserves the silver-white menu surface and blue selection treatment; the right pane preserves the reference's navy gradient. KURUKURU hardware remains neutral silver, near-black glass, warm white, and medium gray.
- Image quality and asset fidelity: shell, wheel, and center remain high-resolution transparent model-derived PNG layers. The alpha-window capture has no opaque panel rectangle, stretching, crop, or transparency halo.
- Copy and content: visible screen copy is limited to the Shelf function and state (`SHELF`, item names, `DROP FILES`, `READY`). Toy, Settings, separate Clipboard destinations, application branding, and device branding do not appear.
- Icons: file kinds, Open, Copy, Reveal, Remove, batch drag, battery, and wheel controls use one native symbol family and remain optically centered at the compact size.
- Behavior and accessibility: the display is one Shelf surface rather than a pseudo-OS. Rows support selection, single-item drag, Open, Copy, Reveal, Remove, and context menus; the header exposes batch drag when multiple file-backed items exist. Wheel, trackpad, mouse wheel, D-pad, and keyboard inputs operate Shelf selection directly. Trackpad momentum is ignored and residual motion is cleared at gesture end. Detents and physical presses use macOS haptics only; the production source does not initialize an audio engine.

## Comparison history

1. Full-width status bar
   - Earlier finding: `MENU / HOME / battery` occupied the full display width and pushed both panes down, unlike the reference's left-only bar.
   - Fix: moved the status bar into an explicitly measured 106 pt left pane and let the right pane occupy the complete 153 pt screen height.
   - Post-fix evidence: `/private/tmp/dopagak-shelf-only-final/half-width-focused-comparison.png`.

2. Pseudo-OS content
   - Earlier finding: Home, Toy, Clipboard, and Settings destinations made the display a separate novelty OS instead of the requested ShelfDrop surface.
   - Fix: removed destination navigation, Toy, sound, glow, and on-device Settings. The screen now always shows the Shelf list and selected-item detail/actions.
   - Post-fix evidence: empty and populated implementation captures above.

3. Populated-list rendering and retained Shelf functions
   - Earlier finding: the first deterministic populated capture did not render lazy rows, and the AppKit batch-drag source produced a placeholder in offscreen rendering.
   - Fix: changed the compact list to a deterministic five-row selection window and separated the visible native batch icon from its AppKit drag hit surface. Restored explicit Copy, conditional Reveal, row drag, context menus, and batch drag.
   - Post-fix evidence: `/private/tmp/dopagak-shelf-only-final/kurukuru-populated-screen-focused.png`.

## Findings

- No actionable P0, P1, or P2 visual findings remain.

## Open questions

- None blocking handoff.

## Implementation checklist

- [x] Left Shelf/status pane is exactly 50% of each device display.
- [x] Right detail pane starts at the screen's top edge and uses the full height.
- [x] Shelf-only empty and populated states render without clipping or overflow.
- [x] Toy, Settings, audio feedback, and glow state are absent from the product flow.
- [x] Open, Copy, Reveal, Remove, single-item drag, batch drag, drop, clipboard add, ZIP, copy-all, move-all, and clear remain reachable.
- [x] Wheel, trackpad, mouse wheel, D-pad, keyboard, buttons, and screen actions use direct Shelf commands with haptic feedback where appropriate.
- [x] Transparent-window render has no visible panel rectangle.
- [x] Full verification passes with 61 tests in 12 suites plus installer, app-icon, and menu-bar-icon checks.
- [x] Fresh ZIP/DMG pass codesign and disk-image verification; the packaged binary links no audio framework and contains no stale Toy/audio navigation symbols.

## Resolved polish

- [x] The model-derived outer chamfer now uses high-precision curve tessellation and stays smooth at runtime size without flattening the hardware into a generic rounded rectangle.

final result: passed
