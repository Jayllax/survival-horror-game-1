# Character animation and gun combat

For sleeping enemies, stealth, hearing, sight, searching, and timed enemy attacks, see [ENEMY_AI_GUIDE.md](ENEMY_AI_GUIDE.md).

Open `scenes/levels/combat_sandbox.tscn` and press **F6** to try the framework in Godot **4.7.2 Standard**. It contains a flat street, ammunition, a low passage for crouching, an enemy, and a save bicycle. All objects are authored editor nodes. F5 still starts the existing main menu and town.

The enemy is now an exact palette swap of your player's six walking frames: pale sage skin, plum shirt, charcoal hat, and the same blue trousers. No eyes, claws, extra detail, or silhouette changes were added. The player's artwork is preserved.

## Replace animations without programming

Both `scenes/actors/player.tscn` and `scenes/actors/enemy.tscn` have a **Body** node of type **AnimatedSprite2D**. Its **Sprite Frames** resource contains named animations. The scripts select names, rather than hard-coding sprite-sheet frame numbers.

1. Open the character scene and select **Body**.
2. Click **Sprite Frames** in the Inspector to open Godot's SpriteFrames animation editor at the bottom.
3. Choose the animation you want to replace. Remove its placeholder frames, then drag individual PNGs into its frame list or use **Add frames from a sprite sheet**.
4. For the supplied 240 × 72 sheets, set the sheet grid to **6 horizontal, 1 vertical**. Each game frame is **40 × 72 pixels**. Keep that frame size and position the feet at the bottom of the frame for easy replacement. The matching native art is 20 × 36 pixels, exported at exactly 2× with nearest-neighbor.
5. Set FPS and Loop in the animation editor. Keep the animation names below unchanged. Save the character scene and its resource.
6. Once you provide real crouch/dodge poses, select the **Player root → Animation Placeholders** and disable the relevant placeholder options. For a real enemy death sequence, disable **Enemy root → Use Death Placeholder Pose**.

**Body Position = (0, 32)** and **Offset = (0, -36)** place the bottom of a 72-pixel frame at the player's feet. Keep these values when swapping equal-sized game frames. Use transparent padding above shorter crouch poses so every frame retains the same canvas. Do not change Body's scale to 2× for sheets that are already exported at 2×.

If you want a particular enemy to have different animations, use its Sprite Frames resource menu → **Make Unique**, then **Save As** a new `.tres`. The shared defaults live in `data/animations/player_frames.tres` and `data/animations/enemy_frames.tres`. Editing a shared resource deliberately changes every character that uses it. Preview each clip with the SpriteFrames editor's play button.

## Player animation names

| Name | Selected when | Loop |
| --- | --- | --- |
| `idle` | Standing still | Yes |
| `walk` | Moving normally or while aiming | Yes |
| `sprint` | Moving with sprint held, without aiming/crouching | Yes |
| `jump` | Airborne and moving upward | No |
| `fall` | Airborne and descending | No |
| `crouch_idle` | Crouching still | Yes |
| `crouch_walk` | Moving while crouched | Yes |
| `dodge` | Performing the short grounded dodge | No |

The supplied walking cycle is the existing player art. Sprint plays it faster. Jump/fall use still poses; crouch/dodge use existing frames with temporary body compression. These are working placeholders for your animation artwork, not newly drawn final jump/crouch/dodge sequences. The optional compression pivots at the feet and does not move the character's collision shape. Disable each placeholder setting when your frames contain the actual pose.

The dodge clip is fitted to the root's **Dodge Seconds** automatically; changing its frame count does not change the movement duration. Other looping player clips use their configured FPS. Missing or empty optional clips fall back to `idle` without stopping gameplay.

## Movement settings

All values are on the **Player root** in the Inspector. Existing Move Speed, Acceleration, Jump Velocity, Gravity, Coyote Seconds, Jump Buffer Seconds, and Aiming Move Multiplier remain available.

| Setting | Default | Effect |
| --- | --- | --- |
| Sprint Multiplier | 1.55 | Multiplies normal movement speed |
| Crouch Speed Multiplier | 0.45 | Slower movement while crouched |
| Crouch Height | 36 | Actual crouched capsule height in world pixels |
| Dodge Speed | 260 | Short dodge movement speed |
| Dodge Seconds | 0.18 | Dodge motion duration |
| Dodge Invulnerability Seconds | 0.12 | Invulnerable portion, capped to dodge duration |
| Dodge Cooldown Seconds | 0.65 | Minimum time between dodge starts |

The default standing capsule is 64 pixels high. Crouching shortens it while keeping its bottom at the same height. The gun and flashlight lower together. Releasing crouch beneath a ceiling keeps the player crouched until there is enough room to stand. Crouching begins on the ground and prevents jumping and dodging until the player stands. Aiming overrides sprint; sprint does not override crouching. There is no stamina system in this foundation.

The dodge is a short grounded step of approximately **47 world pixels**, rather than the old long dash. It respects walls, ends its extra horizontal momentum, and cannot be repeatedly triggered during cooldown. Its animation and invulnerability have separate timings. These are adjustable Ignotum defaults inspired by the requested short-step feel, not a claim to match Silver Pines' exact internal timing.

## Enemy hit and death animations

The enemy Body has `idle`, `walk`, `sleep`, `wake`, `attack`, `hit`, and `death` animations. Keep idle/walk/sleep looping; keep wake/attack/hit/death non-looping. Replace frames through the same SpriteFrames editor.

On the **Enemy root → Hit and Death**, **Hit Reaction Seconds** (0.18) briefly stops movement and attacks after nonlethal gun damage. A second hit interrupts only when Stagger Cooldown Seconds has expired; damage still applies. See ENEMY_AI_GUIDE.md for attack interruption rules. The `hit` clip is fitted to that duration. The sample uses existing poses and brief color feedback until you add hit artwork.

**Death Seconds** (0.6) controls the death clip duration. **Corpse Linger Seconds** (0.35) holds its last frame before removal. Enable **Leave Corpse** to keep that last pose in the current location. The placeholder death compresses existing art toward the feet; turn that option off when adding a real death animation.

A dying enemy immediately stops attacking, stops taking further damage, and no longer blocks gun rays. Its defeat is recorded immediately, even while its animation is still playing. Bicycle saves include that world flag: a later save restores it as defeated, while an earlier save can restore it alive. Corpses are not restored separately when revisiting a defeated enemy's location. Missing hit/death clips safely use the idle fallback and cannot prevent cleanup.

Enemies can sleep, patrol, investigate, chase, search, and perform timed attacks on flat ground. Automatic contact damage is removed. They do not navigate jumps. Player melee damage, its arc graphic, and the Q binding have been removed; player combat now uses equipped firearms only.

## Controls for your tutorial

These bindings remain in **Project → Project Settings → Input Map**: A/D or arrows move; Shift sprints; hold Ctrl, S, or Down to crouch; Space/W jumps; Alt dodges; right mouse aims; left mouse fires while aiming; R reloads; F toggles the flashlight; E interacts; I/Tab opens or closes inventory; Esc closes panels or pauses. R still rotates inventory items while that panel is open.

There are no in-game control lists or keyboard hints on buttons. Nearby world interactions show only their generic action, such as Read, Talk, or Take. The bindings remain functional for the tutorial you will author.

## Check your animation changes

Test standing, moving, sprinting, jumping/falling, crouching in and out of the low passage, and a dodge beside a wall. Then shoot the enemy, observe hit/death playback, and save before/after defeat in different bicycle slots. Test entering your actual levels too; their existing camera setups are preserved.

`GODOT_BIN=/path/to/godot bash tools/check.sh aiming narrative combat stealth` runs the current feature suites in isolated save directories. The original five suites still assume the original item settings and layouts; see README's validation notes before running those against designer-edited content.
