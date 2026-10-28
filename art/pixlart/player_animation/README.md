# Player animation artwork

`animations-human-made.pixil` is the original uploaded drawing, preserved byte for byte. `player_motion.pixil` is the completed 192×560 master. It uses the same 32×40 cells and fourteen rows as the blank template. Open it in Pixilart and select **DRAW HERE**. Guides and optional attachment markers are hidden by default.

The [download pack](../../../docs/downloads/Ignotum-completed-player-animations.zip) also includes fourteen individual `.pixil` projects with six timeline frames each, transparent PNG strips, the runtime master PNG and this guide. Use those files to preview/adjust one movement at a time.

Rows: idle, walk, sprint, crouch_idle, crouch_walk, jump, fall, dodge, aim_idle, aim_walk, crouch_aim_idle, crouch_aim_walk, aim_jump, aim_fall. Only draw right-facing art; the game mirrors it. Aim bodies deliberately omit the arms so the separate aiming arms and gun can rotate toward the mouse.

The original idle/walk/run drawings were kept, with feet lowered one native pixel to meet the frame boundary. The deepest idle bob now holds the neighboring authored pose instead; shorter final walk/run frame duration avoids a long repeated pose at the loop seam. The supplied first jump/fall sketches remain the entry poses. New motions reuse the original hair/face pixels and clothing colors; the head is never scaled down to crouch. No nose, eyes, extra clothing detail or texture was added.

Grounded soles meet native row 39. Air poses keep a stable upper-body origin: physics, rather than sprite-sheet movement, supplies the jump trajectory. Crouch idle has subtle one-pixel breathing; jump/fall/dodge play once and hold their final frame as appropriate. Dodge playback fits the existing 0.18-second action; its range and invulnerability are unchanged.

Each state/frame has recalibrated hand/chest/body-center entries in `data/animations/player_attachments.tres`. Update those points when changing poses; moving the flashlight node alone will be overridden. The light still points horizontally in facing direction except while holding right mouse, when it aims toward the cursor.

No enemy artwork, levels, movement values, camera settings, input bindings or save format were changed.
