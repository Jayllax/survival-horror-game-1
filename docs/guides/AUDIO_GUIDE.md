# Music, ambience and footsteps

Use Godot 4.7.2 Standard. The supplied tracks are integrated through reusable AudioCue resources and editor-authored audio-player scenes. No new story, starting-location change or safe-room placement has been added.

## What is already connected

| Location / event | Recording |
| --- | --- |
| `introduction_area_1` and `introduction_area_2` | `ambient_track_2.mp3`, continuing between both scenes |
| `town_01` | `ambient_track_1.mp3` |
| An awake hostile enemy sees the player | `scary_2.mp3` |
| Dedicated safe rooms you choose later | `save_room_1.mp3`, supplied as an assignable cue |
| Optional forest atmosphere | Converted `forest_ambience.ogg`, supplied as an assignable cue |
| Player movement | Concrete by default; dirt inside an authored dirt-footstep zone |

Music and ambience play in a persistent GameAudio autoload. They survive scene changes and crossfade instead of being destroyed with the old level. Assigning the same cue in both introduction scenes preserves its playback position. The original per-scene placeholder drone is disabled by default to keep it from playing over your music.

## Assign a scene's music without programming

1. Open the level and select its **root Location node**.
2. In the Inspector, expand **Audio**.
3. Drag an AudioCue from `data/audio/music/` into **Music Cue**.
4. Optionally drag `data/audio/ambience/forest.tres` into **Ambience Cue**.

The fields are:

- **Music Cue:** the music for this location.
- **Inherit Region Music:** when Music Cue is empty, continue the regional theme. The provided introduction and town cues establish region themes. Directly loading an otherwise unassigned room defaults to the town cue.
- **Ambience Cue:** a separate environmental recording, mixed beneath music. Empty fades the previous atmosphere out.
- **Enable Combat Music:** allow enemy-visibility changes to trigger the danger track.
- **Use Legacy Ambience:** optionally restore the old scene's AmbientSound drone. It is normally off.

For a dedicated safe room, assign `data/audio/music/save_room_1.tres` and uncheck **Enable Combat Music**. The safe-room cue is a local override: it does not replace the regional theme for connected rooms. This setting controls audio; your level design determines the room's gameplay safety.

For forest atmosphere without music, leave Music Cue empty, uncheck Inherit Region Music, and assign the forest Ambience Cue. Assign the intended region cue explicitly in rooms that must have a particular theme when loaded directly from a save.

## Adjust volume, fades and looping

Click a cue resource in FileSystem and edit its Inspector fields:

- **Stream:** the actual imported recording.
- **Volume Db:** its mix level. More negative is quieter.
- **Fade Seconds:** the scene-to-scene crossfade duration, normally 1.8 seconds.
- **Loop:** enabled for the supplied music and atmosphere.
- **Loop Offset:** where playback returns on repeat; leave at zero for a whole-track loop.
- **Continue In Connected Rooms:** establish a regional theme. Keep this off for local overrides such as safe-room music.

The original imported recordings are not modified at runtime: the controller uses private looping playback resources. Native MP3, Ogg Vorbis and WAV streams are supported. Music keeps playing while inventory, notes, conversations and the save menu pause gameplay.

The four MP3s are kept exactly as uploaded. Their cue gains compensate for different recording levels: the town recording is substantially quieter than the introduction recording, so its playback gain is higher. These are starting mix settings you can tune in the Inspector. A seamless musical loop needs its end to lead back into its beginning, without unwanted trailing silence or an end fade. After listening in game, you can refine that join in your music application and replace the recording. Exporting exact musical bars as WAV or Ogg Vorbis is useful for future loops; MP3 is supported too. Scene crossfades do not require tracks to have the same tempo or duration.

## Combat music

Open `scenes/audio/game_audio.tscn` and select its root to change:

- **Combat Music:** currently the scary_2 cue.
- **Combat Fade In:** 0.35 seconds.
- **Combat Fade Out:** 1.2 seconds.
- **Lost Sight Grace:** 0.6 seconds, preventing brief sight interruptions from making the music flicker. Set zero to begin fading immediately on sight loss.
- **Combat Duck Db:** -30 dB for the location music while danger is active.

The normal music continues quietly underneath, retaining its position. The danger track fades in when an awake hostile enemy can actually see the player. Sleeping enemies and hearing a noise alone do not trigger it. It fades out after losing sight or when seeing enemies are dead. With multiple enemies, another enemy still seeing the player keeps it active. Existing enemy awareness, stealth and attack behavior is unchanged.

Returning to the main menu fades gameplay music/ambience out. A dying player's soundtrack fades down; loading a location selects its audio again. Music position is not stored in the save file.

## Footsteps and floor materials

Your two original recordings contain several steps. Each now has six short mono variants, with tiny edge fades and matched peak levels. Alternating samples and small pitch differences reduce repetition.

The Player scene contains a reusable **Footsteps** child. It listens to the existing movement animation rather than running a continuous walking recording. It only sounds on the floor, while moving, at **Contact Frames** 0 and 3. Walking, sprinting, crouching and aiming movement therefore use their own animation cadence. Airborne movement and dodges do not play walking sounds. Pausing stops footstep voices.

Open `scenes/actors/player.tscn` and select **Footsteps** to adjust Enabled, Default Surface, Contact Frames, Minimum Step Seconds and crouch/sprint volume differences. If editing a Player instance in a level, enable **Editable Children** first. Update Contact Frames if you redraw the walking animations so that planted feet occur on different frames.

To put dirt footsteps on a floor:

1. Drag `scenes/objects/audio/dirt_footsteps.tscn` into the level.
2. Place its root at floor height; the supplied shape extends upward to cover the player's body.
3. Enable **Editable Children** and resize its CollisionShape2D to cover that stretch of ground.
4. Use **Surface Priority** to resolve overlapping zones: the higher value wins.

`concrete_footsteps.tscn` supplies the opposite override. `footstep_surface.tscn` is the generic version; assign any FootstepSurface resource to its Surface field. Shape resources are unique per instance, so resizing one zone does not resize the others.

The banks are in `data/audio/footsteps/`. Edit Samples, Volume Db and Pitch Variation there. Audible footstep settings do not change enemy hearing: use the Player's existing **Stealth Noise** properties for that. Crouch steps remain quiet and keep the existing zero-noise AI rule.

## Mix and folders

Godot's **Audio** dock contains Master, Music, Ambience and SFX buses. The existing in-game master-volume option still controls the whole mix. Relative bus levels can be adjusted and saved in `default_bus_layout.tres`; cue/bank volumes give finer control.

- `audio/music/`: your four unchanged music MP3s.
- `audio/ambience/`: the Godot-compatible forest Ogg.
- `audio/footsteps/`: short concrete and dirt variations used by the game.
- `audio/sources/`: unchanged original forest/footstep takes; ignored by Godot's importer.
- `data/audio/`: editable cues and surface banks.
- `scenes/audio/`: persistent mixer and player footstep nodes, all visible in the editor.
- `scenes/objects/audio/`: reusable surface zones.

The audio singleton loads the authored mixer scene at runtime, allowing a fresh editor to finish importing the audio files first. It does not generate level geometry.

## Test room and checks

Open `tests/fixtures/audio_sandbox.tscn` with F6 for a separate audio/stealth room with a dirt zone and forest atmosphere. It is not connected to the campaign. Automated checks run with `GODOT_BIN=/path/to/godot bash tools/check.sh audio`; these cover continuity, crossfades, sight/cover, multiple enemies, pause, regions/safe-room overrides and animated material footsteps.
