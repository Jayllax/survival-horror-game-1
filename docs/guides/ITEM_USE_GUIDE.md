# Reusable and single-use items

Select an item's **`.tres` resource under `data/items/`**. Expand **Use Behavior** and set **Remove After Use**:

- **On:** remove one unit after the action succeeds.
- **Off:** keep the item so it can be used again.

This is a setting on the item definition. All copies of that item ID share it. To have both reusable and disposable versions in one game, use separate item resources with different IDs.

## Place bolt cutters

| Pickup scene | Behavior |
| --- | --- |
| `scenes/objects/bolt_cutters.tscn` | Existing reusable cutters |
| `scenes/objects/equipment/bolt_cutters_single_use.tscn` | Opens one fence, then removes that pair |

Both work with existing cuttable fences whose **Required Tool** is `bolt_cutters`. No fence edits are necessary. Place as many independent pickup instances as you need. Quantity 1 gives one pair, and each pair occupies its own inventory entry. The disposable version shares the existing artwork and supports the existing compact upgrade.

Cutting removes the selected disposable pair only after the animation completes. Starting a cut, pressing interact repeatedly, failing a requirement or approaching from too far away does not remove it. Opening an already cut fence costs nothing. If one disposable pair is used for overlapping cuts, only the first completed cut succeeds; the other returns to its closed pose.

When the player carries both versions, the reusable pair is preferred, conserving disposable pairs. Within either type, the first matching inventory entry is used.

## Make your own variants

1. Duplicate the original `.tres` under `data/items/`.
2. Give the duplicate a **new Id**, such as `bolt_cutters_rusty`. Keep IDs stable once they appear in save files.
3. Set its Display Name, Description, icon and Remove After Use as desired.
4. Set **Use As Item Id** to the original requirement, for example `bolt_cutters`.
5. Add the new resource to **`data/catalog.tres` → Items**.
6. Duplicate a pickup scene and assign the new **Item Definition**. Match its Sprite2D texture to the icon for the editor preview.

**Use As Item Id** lets a variant satisfy world tool/key/puzzle requirements without pretending to be the same inventory item. Leave it empty when no alias is needed. If a particular lock must accept only one variant, set its requirement to that variant's actual ID. Recipe Input A/B continue matching actual item IDs.

Do not give two different item resources the same Id: the catalog would treat them as one definition, so they could not have independent behavior.

## Where the checkbox applies

| Action | Result on success |
| --- | --- |
| Inventory Use on a healing item | Heal, then remove one unit if checked |
| Applying an upgrade kit | Upgrade the target; remove the kit if checked |
| Crafting | Each ingredient follows its own checkbox |
| Solving a switchboard puzzle | Its required input follows the checkbox |
| Opening a physical key/tool door | Its selected key/tool follows the checkbox |
| Entering a locked scene entrance | Its selected key follows the checkbox after travel succeeds |
| Cutting a fence | Its selected tool follows the checkbox after the cut finishes |

An unchecked upgrade kit can upgrade multiple different targets; each target still accepts only one upgrade of each effect. An unchecked crafting ingredient acts as a reusable tool/catalyst. Plan recipes accordingly.

Wrong puzzle answers, incompatible upgrades, full-health healing attempts and crafting/puzzle rewards that cannot fit leave the inventory unchanged. Puzzle/crafting checks preserve exact item positions, rotations and upgrades if the result fails.

Equipping, moving, rotating, stacking and picking up items are not use actions. Reloading still transfers ammunition into a weapon, and firing still spends loaded rounds. The checkbox controls item removal during the actions in the table; it does not remove a weapon when equipping or firing it.

## Keys and backtracking

A successfully unlocked entrance records its unlocked state. Even when its key is removed, that entrance remains available on later visits and after saving/loading. Completed physical doors and cut fences likewise stay open. Power requirements remain separate.

An invalid destination or a key that disappears before the fade finishes prevents the entrance from committing its unlock. It does not spend another key as a replacement.

The old physical-door **Consume Key** field remains under **Legacy Compatibility**. If it is on, it forces key removal for older scenes. Leave it off to follow the item definition's Remove After Use setting. It is off in the supplied scenes.

## Existing defaults and saves

Existing bolt cutters and keys remain reusable. Bandages, fuses, cloth, antiseptic, compact kits and damage kits retain their previous consumable behavior through checked item settings.

Save files keep each slot's actual inventory and world progress: saving before a cut retains the tool and closed route; saving after it records the spent tool and open route. No save-format change is needed. Resource settings apply to that item type, including copies loaded from older saves, so changing a shared resource changes its behavior throughout the project.

The new disposable pickup is ready to place; it has not been added to your authored levels. Your movement, lighting, camera settings, level geometry and story text are unchanged.
