# Character animation and gun combat

Open `scenes/levels/combat_sandbox.tscn` with **F6** in Godot **4.7.2 Standard**. Player and enemy use matching simple pixel art, distinct movement/reaction poses and editor-editable **Body → Sprite Frames** resources. F5 starts your main menu and town.

## Edit the supplied animation atlases

`art/pixel/player_motion.png` and `enemy_motion.png` are each **192×240 native pixels**, arranged **6 columns × 6 rows**, with **32×40 pixels per frame**. They are single editable PNGs, not enlarged export pairs. Keep the padded frame canvas and align feet to its bottom. Body uses **Position (0,32)**, **Offset (0,-20)** and **Scale (2,2)**. One native pixel is two world pixels.

| Row (top to bottom) | Player atlas | Enemy atlas |
| --- | --- | --- |
| 1 | Walk, six frames | Walk, six frames |
| 2 | Run, six frames | Sleep frames 1–2; wake frames 2–6 |
| 3 | Crouch walk, six frames | Attack, six frames |
| 4 | Aim walk torso/legs, arms omitted | Hit reaction, six frames |
| 5 | Crouch aim walk, arms omitted | Death, six frames |
| 6 | Idle; crouch idle; jump; fall; dodge; aim idle | Idle breathing, six frames |

The player has brown **hair**, no hat, and a flat face without a protruding nose. The enemy matches its proportions with green skin and a burgundy shirt. Crouch and death are drawn poses; all temporary pose-compression options are disabled in the supplied scenes.

1. Open `scenes/actors/player.tscn` or `enemy.tscn`, select **Body**, and click **Sprite Frames**.
2. Select an animation by name. Replace its frames with individual PNGs or **Add frames from a sprite sheet** (6 horizontal, 6 vertical for these atlases).
3. Keep the animation names. Set FPS and Loop, then save the shared `.tres` resource. To vary one enemy, use **Make Unique → Save As** first.
4. Keep native replacement frames 32×40 if using the supplied Body transform. For already-enlarged 64×80 frames, use Body Scale (1,1) and Offset (0,-40) instead. Keep feet at the bottom.

## Player states

`idle`, `walk`, `sprint`, `crouch_idle`, `crouch_walk`, `jump`, `fall`, `dodge` are selected by gameplay. Walk, run and crouch use distinct six-frame drawings. Jump, fall and the short dodge currently have dedicated single-pose drawings; add more frames through SpriteFrames for fuller airborne/evasion animation.

Aiming uses `aim_idle`, `aim_walk`, `crouch_aim_idle`, `crouch_aim_walk`, `aim_jump`, `aim_fall` when those clips exist. These bodies omit dangling arms so the aim rig can supply them. Missing optional aim clips fall back to their normal state; other missing states fall back to idle. Keep idle present.

The walk/crouch/run playback rate follows actual movement speed, so tuning speed does not leave a full-speed gait at a slow walk. Armed backwards movement reverses the walking cycle. The dodge clip fits **Dodge Seconds** without changing physics timing. Idle and other nonmoving states use their resource FPS.

## Hands holding the handgun

Hold right mouse to draw and aim the equipped weapon. Body facing follows aim even while moving in the other direction. Release it to holster the weapon and aiming arms; the flashlight returns to walking direction. Dodge temporarily hides the weapon/arms.

`Player/WeaponArms` instances `scenes/actors/weapon_arms.tscn`. Two simple editor-visible sleeve segments and a hand on each arm follow the gun's grip points. Both hands stay attached as the gun rotates, flips left, recoils and lowers for crouch. No additional inventory item is involved.

Select **WeaponArms** to tune **Near/Far Shoulder**, **Crouch Shoulder Offset**, **Near/Far Grip** (coordinates on the Gun sprite), **Upper Arm Length** and **Forearm Length**. Under Near/Far, select the Polygon2D sleeves and hands to change colors/shapes. Keep them simple to match your pixel art. The far sleeve is a darker palette shade. When substituting a differently shaped gun, move the grip points and `Aim/Gun/Muzzle` to its handle and barrel. The current rig targets one equipped weapon; future weapons with different grip geometry can be given additional resource settings later.

The existing gun and flashlight node paths remain `Aim/Gun`, `Aim/Gun/Flashlight` and `Aim/Gun/Muzzle`, preserving firing and Godot lighting. The Gun node remains active when its texture is hidden so its light children still work. The arm rig only changes presentation, not ammunition or damage.

## Movement tuning

Your uploaded player scene retains **Move Speed 125**, **Jump Velocity -200**, camera offset **(0,-110)**, zoom **(1.4,1.4)** and your camera limit settings. These can be overridden per scene as before. Other root settings include acceleration, gravity, jump buffering and coyote time.

| Setting | Default | Meaning |
| --- | --- | --- |
| Sprint Multiplier | 1.55 | Normal speed multiplier |
| Crouch Speed Multiplier | 0.45 | Normal speed multiplier |
| Crouch Height | 36 | Physical capsule height; feet stay planted |
| Dodge Speed / Seconds | 260 / 0.18 | Short grounded motion, about 47 world pixels |
| Dodge Invulnerability Seconds | 0.12 | Separate, shorter protected part of the dodge |
| Dodge Cooldown Seconds | 0.65 | Delay before the next dodge |

Crouching blocks jumping/dodging. Releasing crouch under a low ceiling keeps the smaller capsule until standing is safe. The drawn crouch silhouette can extend a few pixels outside the capsule, so check any tightly fitted ceilings with your final artwork. Aiming overrides sprint. Movement respects physical barriers. No stamina system is added.

## Enemy animation timing

Enemy clips: `idle`, `walk`, `sleep` loop; `wake`, `attack`, `hit`, `death` do not. Sleep/wake and attack/hit/death have real separate frames. **Wake Seconds**, **Hit Reaction Seconds**, and **Death Seconds** fit their respective clips to gameplay durations. Corpse Linger Seconds holds the final death frame; Leave Corpse keeps it until leaving the scene.

The default attack commits within 40 world pixels and uses a 40×44 hitbox matched to the short drawn strike. Attack visuals follow the actual **wind-up, active hit, recovery** phases. **Attack Windup Frames** defaults to 2, **Attack Contact Frames** to 2; the remaining two frames play during recovery. Change these counts if you insert a different number of frames. Changing phase durations stretches only that phase, keeping the arm strike synchronized to contact. Missing attack art still falls back safely without changing the damage rules.

Defeat immediately disables combat and records its world flag, which bicycle saves restore independently. Partial enemy HP, alertness, active attacks and corpse poses are transient. See [ENEMY_AI_GUIDE.md](ENEMY_AI_GUIDE.md) for hearing, sight, stealth bypasses and interruption rules.

## Controls in the editor

Project Settings → Input Map retains your bindings. Move left/right; Shift sprints; Ctrl/S/Down crouches; Space/W jumps; Alt dodges; right mouse aims; left mouse fires while aiming; R reloads; F toggles flashlight; E interacts; I/Tab toggles inventory; Esc closes panels or pauses. R rotates dragged inventory items. Control legends remain absent from the game for your authored tutorial.

## In-game previews

![Player hands holding the aimed pistol in a separate test scene](../previews/aiming.png)

![Matching enemy strike art in the combat sandbox](../previews/enemy-strike.png)
