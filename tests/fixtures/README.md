# Regression fixtures

These four former sandbox levels are retained only as isolated automated-test fixtures. They are not campaign locations and are not linked to the menu. The designer removed their originals from scenes/levels/; those removals remain intact. Tests now load these authored copies so gameplay verification does not depend on designer level layouts.

The weapon workbench contains the new equipment pickups and is used for independent upgrade/save/combat checks. The broad fence in the historical fence fixture explicitly retains a 100-unit interaction radius so that its wide collider can be approached; this does not change the designer’s 50-unit reusable fence scene.

`pushable_sandbox.tscn` contains the child-component nightstand, a blocking wall, a bicycle and a raised ledge. The actual player can push the furniture into place, jump onto it and use it to reach the ledge. The automated `pushables` suite also uses this editor-authored room for saved-position and collision checks. It has no campaign entrance or tutorial text.

- `dialogue_choices_sandbox.tscn`: isolated response branches, saved story flags, a conditional pickup, an entrance and a passage blocker. No campaign destination links point to it.

- `audio_sandbox.tscn`: separate soundtrack/forest ambience, two enemies, a sight blocker and a dirt-footstep zone. No campaign links point here.

- `room_door_sandbox.tscn`: two rooms in one level separated by a reusable, physical side-view door, with an upper divider, movable nightstand, player, HUD and bicycle. It is isolated from campaign levels.

- `story_activation_sandbox.tscn`: inherits the current house_03_1 for testing the real Jax-controlled enemy, adding an isolated bicycle and a second actor with an inverse condition inside its own subtree. No campaign entrance links to this fixture. The suite also plays the actual house_03_2 conversation and returns through normal fades.
