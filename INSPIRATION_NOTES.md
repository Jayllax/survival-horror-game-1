# Mechanics reference / Silver Pines

Reviewed 27 October 2026. Sources are the game's official Steam listing, its official screenshots, and Team17's game page. This is research from published material, not a claim to have played or reverse-engineered the game.

- [Steam listing and gallery](https://store.steampowered.com/app/2333000/Silver_Pines/)
- [Team17 game page](https://www.team17.com/games/silver-pines/)

The Steam description explicitly emphasizes fighting **or avoiding** enemies, scarce resources, limited inventory space, puzzles, locked doors/hidden paths, and access expanding through tools and weapons. Official screenshots show unobstructed exploration views, compact ammunition feedback, and an inventory with item artwork and Use / Combine / Examine actions.

## Applied to Ignotum

| Published reference | Ignotum implementation |
| --- | --- |
| Unobstructed exploration screenshots | Removed fixed HUD panels, title, location label, control strip, cooldown text, and permanent crosshair |
| Compact ammunition feedback | Small ammo display during aiming, shooting feedback, or reload; no permanent exploration counter |
| Item-focused inventory screenshot | Resizable rectangular grid with multi-cell items, drag placement, rotation, inspection and equipment |
| Use / Combine / Examine | Examination through selection, medical item Use, and designer-authored two-item recipes |
| Resource scarcity / limited space | Finite authored pickups, ammo stacks, rectangular storage capacity, medical supplies consumed on use, atomic crafting when space is full |
| Tools opening access | Bolt cutters found in the interior open a chained alley gate; the tool is reusable and the route stays open across visits/manual saves |
| Fight or avoid | Existing free movement, sprint/crouch, short grounded dodge with adjustable brief invulnerability, finite ammunition, and a held aiming stance with reduced movement |

The user's explicit request supplies the additional rule that world pickups reveal **no item title**: only a generic nearby action appears, and identity is read in inventory. Pickups do not announce their names in a toast. Saving happens only at a bicycle station; successful collection briefly shows only an inventory hint. The bell interaction and four-slot bicycle save system are the user's requested design, implemented with original artwork and sound.

Right-mouse aiming, exact HUD visibility timing, 30-point healing, recipe inputs, and tool placement are Ignotum design decisions, not asserted replicas of Silver Pines' exact rules. No storyline, campaign, boss encounters, map system, copied UI artwork, or Silver Pines assets were introduced. This is a reusable foundation for the designer's own content.

The later grid iteration adds original implementations of spatial inventory placement and 90-degree rotation, plus independent weapon instances. It uses existing original artwork and does not reproduce another game’s inventory graphics or campaign content.

The narrative framework adds the user's requested environmental note reader and a visual-novel-style bottom dialogue box, with Inspector-authored speakers and text colors. Official Steam/Team17 pages were consulted again on 28 October 2026; exact dialogue controls, typewriter timing, completion flags, and repeat conversation rules here are Ignotum implementation choices. All writing is replaceable instructional placeholder text. The sample NPC reuses the existing player sheet with a tint; no Silver Pines characters, writing, or artwork are included.

The character iteration removes player melee and control legends. Default dodge motion is 0.18 seconds at 260 world pixels/second, with 0.12 seconds of invulnerability; these are adjustable Ignotum settings. The enemy uses the player’s exact pixel geometry with skin/clothing color replacements, following the user’s request to simplify the initial monster concept. Named SpriteFrames resources provide editable character states without copying another game’s animations.

The later enemy AI iteration implements the user’s requested quiet crouch bypass of sleeping enemies, directional vision and hearing, disturbance investigation, memory/search/return, patrols, spacing, and committed timed strikes. These are original Ignotum rules and editable timings; no Silver Pines AI code, characters, animation artwork, or exact internal values were used.
