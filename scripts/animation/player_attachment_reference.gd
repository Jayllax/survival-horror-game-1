extends RefCounted
## Native points calibrated to the designer's completed player sheet.
## Entries follow SpriteFrames playback order, including authored body translations.
const TRACKS := {
    &"idle": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 15.5],
        "aim_origins": [16.5, 18.5, 16.5, 19.5, 16.5, 18.5, 16.5, 19.5, 16.5, 18.5, 15.5, 19.5],
        "flashlight_hands": [22.5, 26.5, 22.5, 27.5, 22.5, 26.5, 22.5, 27.5, 22.5, 26.5, 21.5, 27.5],
    },
    &"walk": {
        "body_centers": [15.5, 15.5, 15.5, 15.5, 16.5, 15.5],
        "aim_origins": [15.5, 18.5, 15.5, 19.5, 15.5, 18.5, 15.5, 18.5, 16.5, 19.5, 15.5, 18.5],
        "flashlight_hands": [21.5, 26.5, 21.5, 27.5, 21.5, 26.5, 21.5, 26.5, 22.5, 27.5, 21.5, 26.5],
    },
    &"sprint": {
        "body_centers": [14.5, 14.5, 14.5, 14.5, 15.5, 14.5],
        "aim_origins": [14.5, 18.5, 14.5, 19.5, 14.5, 18.5, 14.5, 18.5, 15.5, 19.5, 14.5, 18.5],
        "flashlight_hands": [21.5, 23.5, 21.5, 24.5, 21.5, 24.5, 21.5, 25.5, 22.5, 25.5, 21.5, 24.5],
    },
    &"crouch_idle": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 27.5, 16.5, 26.5, 16.5, 27.5, 16.5, 26.5, 16.5, 26.5, 16.5, 27.5],
        "flashlight_hands": [22.5, 31.5, 22.5, 31.5, 22.5, 31.5, 22.5, 31.5, 22.5, 31.5, 22.5, 31.5],
    },
    &"crouch_walk": {
        "body_centers": [14.5, 15.5, 17.5, 15.5, 16.5, 16.5],
        "aim_origins": [14.5, 26.5, 15.5, 27.5, 17.5, 26.5, 15.5, 27.5, 16.5, 26.5, 16.5, 27.5],
        "flashlight_hands": [20.5, 31.5, 21.5, 32.5, 23.5, 31.5, 21.5, 32.5, 22.5, 31.5, 22.5, 32.5],
    },
    &"jump": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 19.5, 16.5, 18.5, 16.5, 18.5, 16.5, 19.5, 16.5, 19.5, 16.5, 19.5],
        "flashlight_hands": [22.5, 27.5, 23.5, 23.5, 23.5, 23.5, 23.5, 25.5, 23.5, 26.5, 23.5, 25.5],
    },
    &"fall": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 18.5, 16.5, 18.5, 16.5, 18.5, 16.5, 18.5, 16.5, 18.5, 16.5, 19.5],
        "flashlight_hands": [23.5, 23.5, 23.5, 23.5, 23.5, 24.5, 23.5, 25.5, 23.5, 24.5, 23.5, 25.5],
    },
    &"dodge": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 17.5, 16.5, 21.5, 16.5, 26.5, 16.5, 26.5, 16.5, 20.5, 16.5, 17.5],
        "flashlight_hands": [23.5, 22.5, 23.5, 26.5, 22.5, 31.5, 22.5, 31.5, 23.5, 26.5, 23.5, 23.5],
    },
    &"aim_idle": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 15.5],
        "aim_origins": [16.5, 18.5, 16.5, 19.5, 16.5, 18.5, 16.5, 19.5, 16.5, 18.5, 15.5, 19.5],
        "flashlight_hands": [],
    },
    &"aim_walk": {
        "body_centers": [15.5, 15.5, 15.5, 15.5, 16.5, 15.5],
        "aim_origins": [15.5, 18.5, 15.5, 19.5, 15.5, 18.5, 15.5, 18.5, 16.5, 19.5, 15.5, 18.5],
        "flashlight_hands": [],
    },
    &"crouch_aim_idle": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 26.5, 16.5, 27.5, 16.5, 26.5, 16.5, 27.5, 16.5, 26.5, 16.5, 27.5],
        "flashlight_hands": [],
    },
    &"crouch_aim_walk": {
        "body_centers": [14.5, 15.5, 17.5, 15.5, 16.5, 16.5],
        "aim_origins": [14.5, 26.5, 15.5, 27.5, 17.5, 26.5, 15.5, 27.5, 16.5, 26.5, 16.5, 27.5],
        "flashlight_hands": [],
    },
    &"aim_jump": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 19.5, 16.5, 18.5, 16.5, 18.5, 16.5, 19.5, 16.5, 19.5, 16.5, 19.5],
        "flashlight_hands": [],
    },
    &"aim_fall": {
        "body_centers": [16.5, 16.5, 16.5, 16.5, 16.5, 16.5],
        "aim_origins": [16.5, 18.5, 16.5, 18.5, 16.5, 18.5, 16.5, 18.5, 16.5, 18.5, 16.5, 19.5],
        "flashlight_hands": [],
    },
}

static func create_profile() -> CharacterAttachmentProfile:
    var profile := CharacterAttachmentProfile.new()
    for animation in TRACKS:
        var track := CharacterAttachmentTrack.new()
        track.animation = animation
        var data: Dictionary = TRACKS[animation]
        track.body_centers = PackedFloat32Array(data["body_centers"])
        for field in ["aim_origins", "flashlight_hands"]:
            var points := PackedVector2Array()
            var values: Array = data[field]
            for i in range(0, values.size(), 2):
                points.append(Vector2(values[i], values[i + 1]))
            track.set(field, points)
        profile.tracks.append(track)
    return profile
