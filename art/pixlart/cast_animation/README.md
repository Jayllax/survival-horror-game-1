# Matching NPC and enemy animations

## Designer-redrawn enemy

`enemy_motion.pixil` is now the designer's **192×560** template. Edit the visible **Layer 2**. The original Background and hidden template layers, visibility flags and palette are preserved. `enemy_redesign.pixil` archives the original upload unchanged. Only the cached global thumbnail was repaired in the editable master.

`art/pixel/enemy_motion.png` is the exact visible drawing-layer PNG, including its partially transparent face/death pixels. Runtime cells remain **32×40**: the first seven rows are **idle, walk, sleep, wake, attack, hit, death**. Use a **6×14** picker grid and select only those populated rows. Existing animation timings, attack phases, actor/collision transforms, AI and saved progress are unchanged. [Actual enemy previews and verification](../../../docs/previews/refined_cast/ENEMY.md).

## Designer-redrawn Jax

`npc_jax_motion.pixil` is now the designer's full **192×560** template, with the drawing on **Layer 1** and an empty Background layer. `jax_redesign.pixil` archives the original upload unchanged. The cached global thumbnail was repaired and Layer 1 selected in the editable master; drawing layers and palette are unchanged.

The PNG in `art/pixel/npc_jax_,motion.png` is the exact drawing-layer PNG. Runtime frames stay 32×40: idle comes from row 1, talking from row 2, and the remaining empty template rows are ignored. Use a **6×14** grid when selecting replacement frames from this full sheet. Jax retains the previous custom sequence durations, idle/talking speeds, dialogue, world placement and saved identity. [Actual Jax previews and verification](../../../docs/previews/refined_cast/JAX.md).

The following generic NPC notes and older animation pack describe the earlier templates. Use the current enemy/Jax masters above for their redesigned artwork.


Open `enemy_motion.pixil` or `npc_motion.pixil` in Pixilart. These editable masters match the runtime PNG layout exactly. Cells are **32×40**, with six frames per row. The [download pack](../../../docs/downloads/Ignotum-NPC-enemy-animations.zip) also includes one timeline `.pixil` file per animation and PNG strips.

The generic NPC keeps its existing artwork and native cell size. The current player, Jax and enemy drawings use their respective designer-supplied palettes. Preserve the enemy's marked shirt and distorted face as drawn; do not recolour it to an older template palette.

Enemy rows: **idle, walk, sleep, wake, attack, hit, death**. Idle/walk/sleep loop; the other clips play once. Attack frames 1–2 warn, 3–4 strike, and 5–6 recover, following the existing combat phases. The death clip finishes in a prone pose with bent legs so the original full-sized head fits inside the cell. Sleep is a bowed resting pose; waking rises to the same standing silhouette.

NPC rows: **idle, walk**. The placed NPC plays idle automatically and faces the player when spoken to. The walk artwork is available to preview/replace in SpriteFrames; this art update adds no NPC patrol or navigation behavior. Dialogue and saved progress use the existing systems.

Both scenes use Body Position **(-1,32)**, Offset **(0,-20)** and Scale **(2,2)**, centering the odd-width artwork over the scene origin with feet on the ground. For an individual design, duplicate the SpriteFrames resource with **Make Unique → Save As** before changing it. Keep the animation names and native cell size.

Existing levels, player artwork and movement tuning are unchanged. Only the player's flashlight shape was adjusted separately: Transform Scale **(0.85,1.25)** keeps the origin attached, reduces reach by 15% and widens the beam by 25%. Right-click aiming and the F toggle are unchanged.
