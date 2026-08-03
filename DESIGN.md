# DOPA-GAK! design direction

## Product idea

DOPA-GAK! is a floating pocket shelf for the Mac. Its reward comes from the short ritual of turning, pressing, and feeling a response while moving real Shelf items—not from a separate toy mode, sound effects, or permanent neon.

## Shelf UI / Pocket Hardware

- KURUKURU is restrained color-era hardware: satin silver, black glass, warm-white wheel, blue selection.
- POCHITTO is skeleton-era hardware: smoky lavender polycarbonate, charcoal controls, visible olive PCB, copper flex, four-level LCD.
- Raspberry/magenta belongs to the app icon and POCHITTO construction details; it is not an idle wash or interaction glow.
- The product UI carries no brand or device names. Controls are described by function (`Click Wheel` / `D-Pad`), while small technical labels may describe the hardware itself.
- Materials need construction logic. Edges, screws, speaker chambers, cables, screens, and controls should look placed for a reason.
- The display is always ShelfDrop: a compact item list on the left and the selected item's actions on the right. There are no Toy, Settings, or other pseudo-OS destinations.

## Window behavior

- The floating panel itself is invisible: no native rectangular border or rectangular shadow.
- The device silhouette owns its local shadow, with transparent breathing room around it.
- Window dragging is an invisible, non-overlapping hardware surface along the top edge.
- The hardware face carries no window controls. Escape, the global shortcut, and the menu-bar toggle hide the panel.

## Feedback

- Idle is quiet.
- Rotation gives short detents through macOS haptics only.
- Trackpad momentum is ignored and gesture residuals are cleared, so interaction stops when the hand stops.
- Select and physical button presses give a distinct generic haptic response.
- The app does not initialize or link an audio engine for device feedback.

## Icon

The app icon fuses the two devices into one mark: a cream click wheel around a raspberry D-pad inside a smoky violet shell. Large sizes keep the internal construction; 16/32/64 px use an optically simplified master.
