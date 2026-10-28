# Matching NPC and enemy animations

Open `enemy_motion.pixil` or `npc_motion.pixil` in Pixilart. These editable masters match the runtime PNG layout exactly. Cells are **32×40**, with six frames per row. The [download pack](../../../docs/downloads/Ignotum-NPC-enemy-animations.zip) also includes one timeline `.pixil` file per animation and PNG strips.

The player, NPC and enemy share the designer's head/hair outline, flat featureless face, broad shirt, leg dimensions, native pixel size and standing height. NPC colors are muted green clothing and navy trousers. Enemy colors retain the plum shirt, dark hair and pale green skin. All colors come from `art/pixel/ignotum.gpl`.

Enemy rows: **idle, walk, sleep, wake, attack, hit, death**. Idle/walk/sleep loop; the other clips play once. Attack frames 1–2 warn, 3–4 strike, and 5–6 recover, following the existing combat phases. The death clip finishes in a prone pose with bent legs so the original full-sized head fits inside the cell. Sleep is a bowed resting pose; waking rises to the same standing silhouette.

NPC rows: **idle, walk**. The placed NPC plays idle automatically and faces the player when spoken to. The walk artwork is available to preview/replace in SpriteFrames; this art update adds no NPC patrol or navigation behavior. Dialogue and saved progress use the existing systems.

Both scenes use Body Position **(-1,32)**, Offset **(0,-20)** and Scale **(2,2)**, centering the odd-width artwork over the scene origin with feet on the ground. For an individual design, duplicate the SpriteFrames resource with **Make Unique → Save As** before changing it. Keep the animation names and native cell size.

Existing levels, player artwork and movement tuning are unchanged. Only the player's flashlight shape was adjusted separately: Transform Scale **(0.85,1.25)** keeps the origin attached, reduces reach by 15% and widens the beam by 25%. Right-click aiming and the F toggle are unchanged.
