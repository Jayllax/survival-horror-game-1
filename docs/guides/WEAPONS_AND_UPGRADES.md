# Weapons and item upgrades

Use **Godot 4.7.2 Standard**. Upgrades change the individual item you combine them with. Another handgun of the same type keeps its own damage, footprint and loaded rounds. The grid itself does not grow.

[Shotgun in game](../previews/shotgun-aim.png) · [Inventory example](../previews/equipment-inventory.png)

## Place weapons and upgrades

Drag scenes from **`scenes/objects/equipment/`** into your level:

| Scene | Gives the player |
| --- | --- |
| `handgun.tscn` | One empty handgun |
| `shotgun.tscn` | One empty shotgun |
| `shotgun_shells.tscn` | Four buckshot shells by default |
| `compact_saw.tscn` | One compact saw kit |
| `damage_kit.tscn` | One damage kit |

Select the placed root to change **Quantity**, **Interaction Radius**, **Prompt Offset** or **Persistent Id**. Weapons and kits should normally have Quantity 1. Shells stack in groups of 12. Use the existing `scenes/objects/ammo.tscn` for 9mm ammunition; it does not reload the shotgun.

Pickups show their artwork and a nearby generic interaction prompt. Their names/descriptions are read in the inventory. Finding a weapon does not automatically equip it or give it free loaded ammunition: select it in the inventory, choose Equip, and reload with the correct ammunition.

Keep Persistent Id empty to use the object's unique scene path, or assign a unique value yourself. Do not reuse an explicit ID for two different pickups.

## Apply upgrades in the inventory

Select a kit, press **Combine**, then select its target. Selecting the target first also works. Alternatively, drag the kit onto the target, or the target onto the kit.

- **Compact saw kit:** consumed once to reduce the target's cell footprint. Handgun **2×1 → 1×1**; shotgun **3×1 → 2×1**; bolt cutters **3×1 → 2×1**. The actual world artwork stays the same size. Loaded rounds, identity, rotation, equipment and damage are preserved.
- **Damage kit:** consumed once to multiply that weapon's damage by **1.25**, rounded to a whole number per projectile. Handgun **26 → 33**. Shotgun **14 → 18 per pellet**.

The supplied kits have **Use Behavior → Remove After Use** checked. Uncheck it on a kit definition to keep it after successful upgrades; see [item-use settings](ITEM_USE_GUIDE.md).

Each item accepts one upgrade of each effect. A weapon can have both. Repeated or incompatible attempts leave the kit and target unchanged. Shrinking keeps the target at its current grid position and frees the removed cells. It also works when the grid is full. Ammo stacks and one-cell objects cannot be compacted.

The inventory detail panel displays the item's actual footprint, current damage and installed upgrades. Longer descriptions scroll inside their existing panel. Ordinary stack merging and cloth/antiseptic crafting remain available.

## Starting loadout and grid size

Select **`data/inventory_settings.tres`** in Godot's FileSystem:

- **Columns / Rows** control starting grid dimensions. For example, 6 columns and 3 rows gives 18 cells. The supplied capacity remains 8×4 so you can choose your preferred size.
- **Starting Weapon** is now empty, so new games start unarmed. Enter `pistol` or `shotgun` if you later want that weapon at the start.
- **Starting Ammo** is reserve 9mm ammunition; it remains 0. A configured starting weapon begins with its magazine loaded.

These settings affect **new games**. Existing save slots keep their stored grid size, items, equipment and ammunition. An empty starting loadout does not remove guns from an existing save.

## Handgun versus shotgun

| Setting | Handgun | Shotgun |
| --- | --- | --- |
| Ammunition ID | `ammo` (9mm) | `shotgun_shells` (buckshot) |
| Magazine | 6 | 4 |
| Projectiles per shot | 1 | 6 |
| Base damage per projectile | 26 | 14 |
| Full spread angle | 0° | 14° |
| Maximum range, world pixels | 900 | 430 |
| Seconds between shots | 0.28 | 0.9 |
| Reload | 1.35 seconds for the magazine | 0.7 seconds per shell |

Buckshot uses a consistent spread centered on the aim direction. Every pellet checks its own hit and stops at cover. At a distance, fewer pellets hit a small target. One shot consumes one shell, not six. The shotgun has its own sound and stronger visual recoil.

Reloading inserts one shell at a time until the shotgun is full or reserves run out. Firing with a loaded shell interrupts reloading; an empty shotgun continues loading. Changing or unequipping a weapon cancels its unfinished reload without transferring ammunition to the new weapon. The handgun keeps its existing magazine reload.

Both weapons draw only while aiming. The flashlight follows the cursor while aim is held and the character's facing otherwise. Changing weapon artwork scale preserves the flashlight's existing width, distance, color and Z range.

## Make another weapon without programming

1. Duplicate a weapon resource under **`data/items/`**. Give it a unique **Id** and Display Name. Keep **Is Weapon** on and **Max Stack** at 1.
2. Assign its Icon and Weapon Texture, choose its Grid Size and optional Compact Grid Size, and set its ammunition ID, magazine, damage, interval, reload and range.
3. Choose **Pellets Per Shot = 1** for a single shot, or several pellets with a nonzero Spread Degrees for a spread weapon. **Reload One At A Time** selects shell-style reloading. Reload Seconds means per shell when that setting is on.
4. Add the weapon and its ammunition resources to **`data/catalog.tres` → Items**. Give new ammunition its own stable item ID, icon and stack limit. The IDs must match exactly.
5. Duplicate a pickup scene, choose **Make Unique** for any resource you intend to change, and assign your weapon's Item Definition on its root. Assign its Sprite2D texture for the editor preview and set Quantity 1.
6. Test equipping, reloading, firing and saving before placing it across the town.

For new native art, use **Weapon Scale (2,2)**. The older handgun retains its existing texture scale. Enable **Custom Weapon Pose** to set **Near Grip**, **Far Grip**, **Muzzle Offset** and **Flashlight Offset**. These coordinates are measured from the texture's center, before Weapon Scale. The aiming rig mirrors them when facing left. Keep the hand points on the rear grip and front support, and the muzzle at the barrel end.

The new PNGs live in **`art/pixel/equipment/`**. Edit them in Pixilart at their existing native size, export at 100%, and use `art/pixel/ignotum.gpl`. There are no enlarged source/export duplicates.

## Make other items upgradeable

On the target's item resource, set **Compact Grid Size** to a smaller footprint. **(0,0)** disables compacting. Each dimension must be at least 1 and no larger than its original counterpart, and total cells must decrease. This guarantees shrinking can keep the item in place. Rotated items use the rotated compact dimensions automatically.

Items must have **Max Stack = 1** to accept upgrades. Damage upgrades also require Is Weapon. Compacting preserves the item ID, so existing key/tool checks still recognize it.

The kit's item definition has an **Upgrade** resource. The examples are in **`data/upgrades/`**. Choose its effect and damage multiplier there. **Target Item Ids** is empty for all eligible targets; fill the list to restrict a kit to particular weapons/tools. To make a shotgun-only damage kit, duplicate both the kit item and its Upgrade resource, give the item a new ID, then add `shotgun` to the upgrade's target list. Register the kit in the catalog.

No combination recipe is needed for upgrades. Existing `data/recipes/` resources continue handling ordinary crafting.

## Saves and animation attachments

Version-4 bicycle saves store installed upgrade IDs, actual item layout, per-weapon rounds and equipment alongside health and world progress. Loading another slot replaces the whole state. Version-2 and version-3 saves remain readable; missing upgrade lists mean unmodified items. Unknown, incompatible or repeated installed upgrades are rejected before changing the active game.

Keep item IDs and saved resource paths stable after release. Changing a compact footprint or deleting an upgrade definition can make a saved layout invalid; test old saves when deliberately changing those definitions.

Your uploaded `player_attachments.tres` is preserved, including its empty point lists. The aiming rig now has **Fallback Attachment Profile**, using the previous calibrated points in `data/animations/player_attachment_defaults.tres`. Nonempty custom point lists take priority. This keeps the current character aligned without changing your movement, camera, lighting or animation artwork. If both saved profiles have empty point lists, **Use Calibrated Reference When Empty** supplies the existing character’s built-in calibration without modifying either resource. For unrelated character artwork, supply your own points or turn that final fallback off deliberately.

## Test separately from your town

Open **`tests/fixtures/weapon_workbench.tscn`** and press **F6**. It contains authored weapon/ammo/kit pickups, a bicycle, floor and a durable enemy. It is not linked into your campaign and contains no story or control legend. No pickups were inserted into your authored town or introduction scenes.

For development checks:

```sh
GODOT_BIN=/path/to/godot-4.7.2 bash tools/check.sh equipment grid_inventory aiming narrative combat stealth fences character_art interiors forest
```

Save checks use isolated test-data directories. They never touch your normal Godot saves.
