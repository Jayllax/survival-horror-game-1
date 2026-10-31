# Recorded dialogue

Put voice recordings here, optionally grouped into character folders such as `jax/`.
Godot supports `.wav`, `.ogg` and `.mp3`; use one recording per DialogueLine.
Assign the file to the line's **Voice (optional) → Voice Audio** field in the Inspector.
**Voice Volume Db** adjusts that one line, and the **Voice** audio bus controls the whole voice mix.

Playback starts when the line appears and continues if the player reveals its text.
Advancing or selecting an answer stops the previous clip before the next line begins.
Lines without audio keep working. Dialogue advances manually; recordings never force the player past a line.

No placeholder speech or changes to your written dialogue are included.
See `docs/guides/DIALOGUE_CHOICES_GUIDE.md` for branches, animation and voice setup.
