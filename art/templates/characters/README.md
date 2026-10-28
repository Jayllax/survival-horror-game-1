# Ignotum animation templates for Pixilart

Start with **`player_clips/walk.pixil`**. It opens as six **32×40-pixel** animation frames with a blank drawing layer, guides and your **Sparkle's palette**. Everything here is a working template for your drawings; the game's current assets are unchanged.

## Draw one animation at a time

1. Download/extract the template pack, then open [Pixilart's editor](https://www.pixilart.com/draw). Save any drawing already open first, then use **File → Open .pixil** and choose `player_clips/walk.pixil`.
2. Select the **DRAW HERE** layer. Draw the character facing **right**. Use the frame timeline to draw the next pose and preview the movement. Turn on onion skin if helpful.
3. Keep the canvas **32×40** at its native resolution. Zoom in to draw; do not enlarge the image itself. The game displays each art pixel at 2× automatically.
4. Save your editable **`.pixil`** project. Send it back when ready, even if you have only finished one animation. I will insert the frames, configure playback and align the flashlight/gun with your actual art. You do not need to change Godot resources or code.

There are six blank frames per animation as a starting point. You can add/remove timeline frames; tell me which ones loop and any timing preferences. You do not have to finish every file before sending your work.

## Keep the body stable

- The dashed **blue center line is X=16**. Keep the pelvis/body centered around it throughout the cycle. Animate the limbs rather than sliding the entire character left/right inside the frame: gameplay already moves the player.
- The **green bottom line is row Y=39**. During grounded movement, place the planted sole on that bottom pixel row; the floor is immediately below it at Y=40.
- The faint sand-colored bounds are an optional **20×36** standing reference inside the padded frame. They are not a mandatory body shape. Aim for roughly the same standing height across all clips and the enemy.
- Bend the knees/hips for crouching; keep the head's pixel size consistent. Do not squash the entire character.
- In jump/fall, keep the body origin consistent and animate the pose. The game supplies the overall vertical motion. Tucked legs may leave transparent space under the feet.
- Keep the entire canvas for every frame, including empty space. Do not auto-trim, auto-crop, add spacing between exported frames, or resize each pose to fill the frame.
- Only draw right-facing artwork. The game mirrors it for the left direction.

## Layers

| Layer | Use |
| --- | --- |
| **DRAW HERE** | Your artwork; selected when the file opens |
| **GUIDES - HIDE FOR EXPORT** | Locked reference lines below your art; hide for clean exports |
| **MARKERS - OPTIONAL - HIDE FOR EXPORT** | Optional attachment dots; keep separate from artwork |

The guide and marker layers are not game artwork. **Do not flatten them into your drawing.** Sending the layered `.pixil` is easiest: I can extract only DRAW HERE. If you export PNG/GIF yourself, hide both auxiliary layers **in every animation frame** first. Export transparent PNG at **100%**, without grid or checkerboard pixels.

## Optional markers: avoid guessing where your hands are

Use the **Attachment markers** palette on the optional MARKERS layer. One pixel per marker per frame is enough:

- **Cyan `#00ffff`**: the hand from which you want the handheld flashlight to shine.
- **Magenta `#ff00ff`**: chest/shoulder reference for the aiming pivot.
- **Yellow `#ffff00`**: pelvis/body center.

These colors belong only on MARKERS, never DRAW HERE. Leave the marker layer empty if you prefer; you can instead send a separate annotated picture. I will ask about anything unclear before aligning your assets.

The flashlight's behavior stays the same: **horizontal in facing direction normally; toward the cursor only while aiming**. These markers describe attachment positions, not new direction controls.

## Player files and master-sheet rows

Each file in `player_clips/` has six native animation frames. The optional `PLAYER_MASTER.pixil` instead holds all fourteen animations in one **192×560** sheet: six 32×40 cells across, one animation per row. Use whichever workflow you prefer; you do not need to complete both. `PLAYER_ROW_MAP.png` labels the master rows.

| Row | File / animation | What to draw | Playback in game |
| --- | --- | --- | --- |
| 1 | `idle` | Standing/breathing | Loop |
| 2 | `walk` | Normal walk, alternate right/left steps | Loop |
| 3 | `sprint` | Distinct running stride | Loop |
| 4 | `crouch_idle` | Low resting pose | Loop |
| 5 | `crouch_walk` | Low quiet steps | Loop |
| 6 | `jump` | Rising/already airborne pose | Once while rising |
| 7 | `fall` | Descending pose | Once while falling |
| 8 | `dodge` | Short evasive step | Once; current total 0.18 seconds |
| 9 | `aim_idle` | Standing head, torso and legs, **without arms or gun** | Loop |
| 10 | `aim_walk` | Walking head, torso and legs, **without arms or gun** | Loop |
| 11 | `crouch_aim_idle` | Crouched head, torso and legs, **without arms or gun** | Loop |
| 12 | `crouch_aim_walk` | Crouch walk, **without arms or gun** | Loop |
| 13 | `aim_jump` | Rising body, **without arms or gun** | Once while rising |
| 14 | `aim_fall` | Falling body, **without arms or gun** | Once while falling |

**Normal rows:** draw the whole body, arms and hands. Leave out the flashlight device/beam and gun; those are separate game objects.

**Aim rows:** the arms, hands and gun are separate so they can rotate toward the cursor. Draw only head, torso and legs, with a complete shirt behind where the arms attach. If you want a particular hand/grip design, send one extra reference drawing with the arms/gun shown; I can match the separate arm artwork to it.

For a quick start, just draw **idle, walk, sprint, crouch_idle and crouch_walk**. A single held frame is fine for jump/fall initially. The optional aim rows can follow later.

The player master now shares the **6-column × 14-row layout** of the current runtime `player_motion.png`. These templates are still blank. The [completed player pack](../../../docs/downloads/Ignotum-completed-player-animations.zip) contains the artwork based on your returned drawing. Send edits back for integration so attachment points stay matched to the new poses. The enemy master also matches the current seven-row enemy atlas. Completed NPC/enemy drawings are in the [cast animation pack](../../../docs/downloads/Ignotum-NPC-enemy-animations.zip).

## Optional enemy templates

`enemy_clips/` contains the same six-frame workflow, and `ENEMY_MASTER.pixil` is a **192×280** sheet with these seven rows:

| Row | Animation | What to draw |
| --- | --- | --- |
| 1 | `idle` | Subtle breathing |
| 2 | `walk` | Slow walk |
| 3 | `sleep` | Resting/sleeping pose |
| 4 | `wake` | Rise to alert; first frame matches sleep |
| 5 | `attack` | Frames 1–2 warning, 3–4 strike, 5–6 recovery |
| 6 | `hit` | Recoil/flinch, then recover |
| 7 | `death` | Collapse, ending in a grounded corpse |

Sleep/idle/walk loop. Wake/attack/hit/death play once. Attack phase lengths are adjustable; those frame groups match the current setup. Keep the corpse's final pose stable. If a fully extended attack or prone body needs a wider canvas, tell me rather than squashing the character to fit; I can adapt that clip when integrating it.

## PNG alternatives and returning work

`png/blank_frame.png`, `blank_six_frame_strip.png`, `blank_player_master.png`, and `blank_enemy_master.png` are completely transparent canvases. Their `guides_*.png` companions are reference overlays, not pictures to paint over destructively. The original current palette remains [art/pixel/ignotum.gpl](../../pixel/ignotum.gpl).

Return either the edited `.pixil` files, or transparent native PNG strips/individual frames. Include which animation each file represents and any extra frames/timing changes. A GIF can help show the intended motion, but keep the editable/PNG originals too.

The precise sheet sizes and row names are also in `layout.json` for integration. You can ignore that file while drawing. Templates are excluded from Godot's asset import, so experimenting here cannot replace runtime artwork by accident.

## Template validation

Both master projects and sample walk/aim-walk/attack projects were opened in Pixilart and checked for their dimensions, six-frame timelines, locked guides, selected drawing layer and palette. All 23 project structures, 128 frames, embedded PNG sizes, blank-canvas transparency and the download ZIP CRC were checked. No runtime scene, script or game artwork is changed by this pack.
