extends Node
var checks := 0
var failures := 0
var room: Node2D
var player: CharacterBody2D
var foe: CharacterBody2D
var hud: CanvasLayer
func check(ok: bool, description: String) -> void:
    checks += 1
    if ok: print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)
func frames(count: int = 2) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()
func run() -> void:
    verify_inventory()
    await verify_gameplay()
    await verify_saves()
    Input.action_release("aim")
    get_tree().paused = false
    if is_instance_valid(room):room.queue_free()
    await frames(5)
    print("IGNOTUM EQUIPMENT: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_inventory() -> void:
    for old_path in LocationPaths.RENAMED:
        var current := LocationPaths.resolve(old_path)
        check(current == LocationPaths.RENAMED[old_path] and ResourceLoader.exists(current), "Renamed designer location resolves: " + old_path)
    var old_world := {"res://scenes/levels/town.tscn:Interactables/Item": true, "power:street": true, "my_explicit_id": false}
    var mapped_world := LocationPaths.resolve_world(old_world)
    check(mapped_world.get("res://scenes/levels/town_01.tscn:Interactables/Item", false) and mapped_world["power:street"] and not mapped_world["my_explicit_id"], "Old location-prefixed progress migrates while explicit IDs and puzzle flags stay intact")
    check(old_world.has("res://scenes/levels/town.tscn:Interactables/Item") and LocationPaths.resolve_world(mapped_world) == mapped_world, "Location migration leaves the input untouched and is safe to apply again")
    Game.reset_run()
    var settings: InventorySettings = load("res://data/inventory_settings.tres")
    check(Game.count_item("pistol") == 0 and not Game.has_equipped_weapon() and settings.starting_weapon.is_empty(), "Designer starts new games unarmed")
    var capacity := Vector2i(Game.inventory.columns, Game.inventory.rows)
    Game.add_item("pistol", 2)
    var first: int = Game.inventory.entries[0]["uid"]
    var second: int = Game.inventory.entries[1]["uid"]
    Game.equip_weapon(second)
    Game.magazine = 4
    Game.move_item(second, Vector2i(7, 2), true)
    Game.add_item("compact_saw")
    var tool := Game.inventory.first_uid("compact_saw")
    check(Game.combine_uids(tool, second), "Combining a saw with a two-cell handgun applies its compact upgrade")
    var compact := Game.inventory.entry(second)
    check(Game.inventory.item_dimensions(compact) == Vector2i.ONE and compact["rotated"] and compact["x"] == 7 and compact["y"] == 2, "Compacting retains location and rotation and releases only the removed cells")
    check(Game.equipped_uid == second and Game.magazine == 4 and Game.last_combined_uid == second, "Compacting preserves the exact equipped instance and loaded rounds")
    check(Game.count_item("compact_saw") == 0 and Game.inventory.entry(tool).is_empty(), "An applied saw kit is consumed once")
    check(Game.inventory.item_dimensions(Game.inventory.entry(first)) == Vector2i(2, 1) and Game.item_catalog["pistol"].grid_size == Vector2i(2, 1), "Other handguns and their shared definition remain unchanged")
    check(Game.inventory.item_at(Vector2i(7, 3)) == -1 and Game.move_item(second, Vector2i(7, 3), true), "The released cell becomes usable and a compact gun fits at the grid boundary")
    Game.add_item("damage_kit")
    check(Game.combine_uids(second, Game.inventory.first_uid("damage_kit")), "Damage and compact upgrades can coexist in either combination order")
    check(Game.inventory.weapon_damage(second) == 33 and Game.inventory.weapon_damage(first) == 26 and Game.item_catalog["pistol"].bullet_damage == 26, "Damage is increased per instance without changing the other gun or base resource")
    check(Vector2i(Game.inventory.columns, Game.inventory.rows) == capacity, "Item upgrades never increase grid capacity")
    Game.add_item("compact_saw")
    Game.add_item("damage_kit")
    var before := Game.inventory.snapshot()
    check(not Game.combine_uids(second, Game.inventory.first_uid("compact_saw")) and Game.inventory.snapshot() == before, "A second size upgrade is rejected without consuming its kit")
    check(not Game.combine_uids(Game.inventory.first_uid("damage_kit"), second) and Game.inventory.snapshot() == before, "A second damage upgrade is rejected atomically")
    Game.add_item("ammo", 3)
    before = Game.inventory.snapshot()
    check(not Game.combine_uids(Game.inventory.first_uid("ammo"), Game.inventory.first_uid("compact_saw")) and Game.inventory.snapshot() == before, "Stackable ammunition cannot be compacted")
    check(not Game.combine_uids(Game.inventory.first_uid("damage_kit"), Game.inventory.first_uid("compact_saw")) and Game.inventory.snapshot() == before, "Damage kits do not alter tools or other upgrade kits")
    Game.add_item("bolt_cutters")
    var cutters := Game.inventory.first_uid("bolt_cutters")
    check(Game.combine_uids(cutters, Game.inventory.first_uid("compact_saw")) and Game.inventory.item_dimensions(Game.inventory.entry(cutters)) == Vector2i(2, 1), "Nonweapon tools can opt into footprint upgrades while retaining their identity")
    check(Game.count_item("bolt_cutters") == 1, "Compacting a tool preserves the ID used by its world interactions")
    var restored := GridInventory.restore(JSON.parse_string(JSON.stringify(Game.inventory.snapshot())), Game.item_catalog)
    check(restored != null and restored.snapshot() == Game.inventory.snapshot(), "JSON round-trip preserves upgrades, compact bounds, identity, ammo and orientation")
    for invalid in [["missing_kit"], ["compact_saw", "compact_saw"], [12], ["compact_saw", "ammo"]]:
        var corrupt := Game.inventory.snapshot()
        corrupt["items"][1]["upgrades"] = invalid
        check(GridInventory.restore(corrupt, Game.item_catalog) == null, "Invalid or duplicate installed upgrades are rejected: " + str(invalid))
    var legacy := GridInventory.new(Game.item_catalog, 8, 4)
    legacy.add("pistol")
    var old := legacy.snapshot()
    old["items"][0].erase("upgrades")
    check(GridInventory.restore(old, Game.item_catalog) != null, "Old grid saves without upgrade metadata remain readable")
    # In a full grid, consuming one kit and shrinking its target still works.
    var full := GridInventory.new(Game.item_catalog, 4, 2)
    full.add("pistol")
    full.add("compact_saw")
    for i in 4:full.add("filler_%d" % i)
    Game.inventory = full
    check(Game.combine_uids(full.first_uid("pistol"), full.first_uid("compact_saw")) and Game.inventory.entries.size() == 5, "A compact upgrade succeeds in a completely occupied inventory")
    var small := GridInventory.new(Game.item_catalog, 6, 3)
    small.add("shotgun")
    small.add("compact_saw")
    Game.inventory = small
    check(Game.combine_uids(small.first_uid("compact_saw"), small.first_uid("shotgun")) and Game.inventory.columns == 6 and Game.inventory.rows == 3, "Upgrades work in an independently configured smaller grid")
    var shotgun := Game.inventory.entry(Game.inventory.first_uid("shotgun"))
    check(Game.inventory.item_dimensions(shotgun) == Vector2i(2, 1) and Game.move_item(shotgun["uid"], Vector2i(4, 0), false), "A compact shotgun shrinks from three cells to two and fits its actual bounds")
    var restricted := InventoryItemDefinition.new()
    restricted.id = "test_shotgun_kit"
    restricted.upgrade = InventoryUpgrade.new()
    restricted.upgrade.effect = InventoryUpgrade.Effect.DAMAGE
    restricted.upgrade.target_item_ids.assign(["shotgun"])
    var catalog := Game.item_catalog.duplicate()
    catalog[restricted.id] = restricted
    var future := InventoryItemDefinition.new()
    future.id = "test_puzzle_object"
    future.grid_size = Vector2i(3, 2)
    future.compact_grid_size = Vector2i(2, 1)
    catalog[future.id] = future
    var model := GridInventory.new(catalog)
    model.add("pistol")
    model.add("shotgun")
    model.add(future.id)
    check(not model.can_apply_upgrade(model.first_uid("pistol"), restricted.id) and model.can_apply_upgrade(model.first_uid("shotgun"), restricted.id), "Inspector target-ID restrictions distinguish compatible weapons")
    check(model.apply_upgrade(model.first_uid(future.id), "compact_saw") and model.item_dimensions(model.entry(model.first_uid(future.id))) == Vector2i(2, 1), "Future multicell puzzle objects can opt into compacting through their resource settings")

func equip(uid: int) -> void:
    if Game.equipped_uid != uid:Game.equip_weapon(uid)
    player.sync_weapon()

func aim_right() -> void:
    Input.action_press("aim")
    player.facing = 1
    player.body_art.flip_h = false
    player.sync_weapon()
    player.aim.rotation = 0

func verify_gameplay() -> void:
    Game.reset_run()
    room = load("res://tests/fixtures/weapon_workbench.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    await frames(5)
    player = room.get_node("Actors/Player")
    foe = room.get_node("Actors/Enemy")
    hud = room.get_node("HUD")
    player.set_physics_process(false)
    foe.set_physics_process(false)
    var handgun: Area2D = room.get_node("Interactables/Handgun")
    var shotgun: Area2D = room.get_node("Interactables/Shotgun")
    var shells: Area2D = room.get_node("Interactables/Shells")
    handgun.interact(player)
    shotgun.interact(player)
    shells.interact(player)
    await frames()
    var pistol_uid := Game.inventory.first_uid("pistol")
    var shotgun_uid := Game.inventory.first_uid("shotgun")
    check(pistol_uid >= 0 and shotgun_uid >= 0 and Game.count_item("shotgun_shells") == 12, "Placed handgun, shotgun and buckshot scenes grant their own items")
    check(not Game.has_equipped_weapon() and Game.inventory.entry(shotgun_uid)["magazine"] == 0, "Found weapons are empty and wait for the player's equipment choice")
    equip(shotgun_uid)
    aim_right()
    Game.magazine = 4
    player.position = Vector2(1100, 588)
    foe.position = Vector2(1195, 588)
    await frames()
    player.aim.rotation = 0
    var before: int = foe.health
    var tracer_count := player.get_parent().get_children().filter(func(n):return n is Line2D).size()
    player.shoot()
    var tracers := player.get_parent().get_children().filter(func(n):return n is Line2D)
    check(Game.magazine == 3 and tracers.size() - tracer_count == 6, "One buckshot shell produces six independently traced pellets")
    check(foe.health == before - 84, "All six close-range pellets damage the real enemy")
    player.shoot()
    check(Game.magazine == 3 and player.shot_cooldown > 0.8, "The pump interval prevents a second immediate shot")
    foe.position = Vector2(1750, 588)
    await frames()
    player.aim.rotation = 0
    player.shot_cooldown = 0
    before = foe.health
    player.shoot()
    check(foe.health == before, "Buckshot cannot damage an enemy beyond the shotgun's range")
    equip(pistol_uid)
    aim_right()
    Game.magazine = 3
    player.shoot()
    check(foe.health == before - 26 and Game.magazine == 2, "The handgun retains its longer single-projectile shot and independent magazine")
    equip(shotgun_uid)
    aim_right()
    Game.magazine = 3
    foe.position = Vector2(1195, 588)
    var cover := room.get_node("Geometry/Cover") as StaticBody2D
    cover.position = player.position + Vector2(28, -40)
    cover.get_node("Shape").disabled = false
    await frames()
    player.aim.rotation = 0
    before = foe.health
    player.shoot()
    check(foe.health == before and Game.magazine == 2, "Every pellet is blocked when the shotgun barrel visually extends through thin cover")
    cover.get_node("Shape").disabled = true
    await frames()
    Game.magazine = 0
    player.shot_cooldown = 0
    player.reload_weapon()
    player.shoot()
    check(player.reload_remaining > 0 and Game.magazine == 0, "An empty shotgun cannot interrupt reload by shooting")
    player.reload_remaining = 0.001
    player._physics_process(0.01)
    check(Game.magazine == 1 and Game.count_item("shotgun_shells") == 11 and player.reload_remaining > 0, "Reload inserts exactly one shell and schedules the next")
    player.aim.rotation = 0
    player.shoot()
    check(Game.magazine == 0 and player.reload_remaining == 0 and Game.count_item("shotgun_shells") == 11, "Firing an available shell interrupts reload without consuming future shells")
    player.shot_cooldown = 0
    player.reload_weapon()
    equip(pistol_uid)
    check(player.reload_remaining == 0 and Game.inventory.entry(shotgun_uid)["magazine"] == 0, "Changing equipment cancels reload without transferring rounds")
    Game.magazine = 0
    Game.add_item("ammo", 5)
    player.reload_weapon()
    player.reload_remaining = 0.001
    player._physics_process(0.01)
    check(Game.magazine == 5 and Game.count_item("ammo") == 0 and Game.count_item("shotgun_shells") == 11, "Handgun reload remains a batch operation using only 9mm")
    equip(shotgun_uid)
    Game.take_item("shotgun_shells", 11)
    Game.add_item("ammo", 2)
    player.reload_weapon()
    check(player.reload_remaining == 0 and Game.magazine == 0, "Handgun ammunition cannot reload the shotgun")
    Game.add_item("shotgun_shells", 2)
    player.reload_weapon()
    for i in 2:
        player.reload_remaining = 0.001
        player._physics_process(0.01)
    check(Game.magazine == 2 and Game.count_item("shotgun_shells") == 0 and player.reload_remaining == 0, "Shell-by-shell reload ends cleanly when reserves run out")
    Game.add_item("shotgun_shells", 12)
    Game.add_item("shotgun_shells", 2)
    var stacks := Game.inventory.entries.filter(func(e):return e["id"] == "shotgun_shells")
    Game.inventory.consume_uid(stacks[0]["uid"], 4)
    check(Game.merge_items(stacks[0]["uid"], stacks[1]["uid"]) and Game.count_item("shotgun_shells") == 10, "Buckshot stacks can be combined using the existing inventory controls")
    await verify_pose(pistol_uid, shotgun_uid)
    await verify_ui(shotgun_uid)

func verify_pose(pistol_uid: int, shotgun_uid: int) -> void:
    var rig: Node2D = player.get_node("WeaponArms")
    var gun: Sprite2D = player.get_node("Aim/Gun")
    var light: PointLight2D = gun.get_node("Flashlight")
    var base_scale: Vector2 = player.default_light_scale
    for uid in [pistol_uid, shotgun_uid]:
        equip(uid)
        var definition := Game.active_weapon()
        var hands := true
        var beam := true
        var shoulders := true
        Input.action_press("aim")
        for facing in [1.0, -1.0]:
            player.facing = facing
            player.body_art.flip_h = facing < 0
            var event := InputEventMouseMotion.new()
            event.position = get_viewport().get_canvas_transform() * (player.position + Vector2(180 * facing, -100))
            event.global_position = event.position
            Input.parse_input_event(event)
            await frames(1)
            player.sync_weapon()
            for clip in [&"aim_idle", &"aim_walk", &"crouch_aim_idle", &"crouch_aim_walk", &"aim_jump", &"aim_fall"]:
                player.body_art.play_state(clip)
                player.body_art.pause()
                for frame in player.body_art.sprite_frames.get_frame_count(clip):
                    player.body_art.frame = frame
                    rig.update_pose()
                    var mirror := Vector2(1, -1 if gun.flip_v else 1)
                    var near_point: Vector2 = definition.near_grip if definition.custom_weapon_pose else rig.near_grip
                    var far_point: Vector2 = definition.far_grip if definition.custom_weapon_pose else rig.far_grip
                    hands = hands and rig.get_node("Near/Hand").global_position.distance_to(gun.to_global(near_point * mirror)) < 0.01
                    hands = hands and rig.get_node("Far/Hand").global_position.distance_to(gun.to_global(far_point * mirror)) < 0.01
                    var offset: Vector2 = definition.flashlight_offset if definition.custom_weapon_pose else rig.barrel_flashlight_offset
                    beam = beam and light.global_position.distance_to(gun.to_global(offset * mirror)) < 0.01
                    shoulders = shoulders and player.aim.global_position.is_finite()
        check(hands and shoulders, "Both hands follow every armed frame in both directions: " + definition.id)
        check(beam and light.global_scale.is_equal_approx(base_scale), "Weapon artwork scaling preserves flashlight placement and beam dimensions: " + definition.id)
        Input.action_release("aim")
        var horizontal := true
        for facing in [1.0, -1.0]:
            player.facing = facing
            player.body_art.flip_h = facing < 0
            for clip in [&"idle", &"walk", &"sprint", &"crouch_idle", &"crouch_walk", &"jump", &"fall", &"dodge"]:
                player.body_art.play_state(clip)
                player.body_art.pause()
                for frame in player.body_art.sprite_frames.get_frame_count(clip):
                    player.body_art.frame = frame
                    rig.update_pose()
                    horizontal = horizontal and Vector2.RIGHT.rotated(light.global_rotation).distance_to(Vector2(facing, 0)) < 0.001
        check(horizontal, "Holstered flashlight faces walking direction throughout unarmed clips: " + definition.id)
    player.sync_weapon()

func verify_ui(uid: int) -> void:
    Game.add_item("compact_saw")
    var saw := Game.inventory.first_uid("compact_saw")
    hud.open_inventory()
    hud.select_item(saw)
    hud.begin_combine()
    hud.select_item(uid)
    check(hud.selected_uid == uid and Game.inventory.item_dimensions(Game.inventory.entry(uid)) == Vector2i(2, 1), "Combine button keeps selection on the upgraded target when the kit was selected first")
    Game.add_item("damage_kit")
    var kit := Game.inventory.entry(Game.inventory.first_uid("damage_kit"))
    var grid: Control = hud.get_node("Root/InventoryPanel/Grid")
    grid.pick(kit["uid"], Vector2i(kit["x"], kit["y"]))
    var target := Game.inventory.entry(uid)
    check(grid.drop_at(Vector2i(target["x"], target["y"])) and hud.selected_uid == uid, "Dragging a damage kit onto the weapon applies it and selects that exact weapon")
    check(hud.get_node("Root/InventoryPanel/Footprint").text.begins_with("2 × 1") and "DAMAGE 18" in hud.get_node("Root/InventoryPanel/Description").text, "Inventory detail shows actual compact footprint, current damage and installed upgrades")
    check(hud.get_node("Root/InventoryPanel/Description") is RichTextLabel, "Long upgrade descriptions scroll within the existing item panel")
    hud.close_panels()

func verify_saves() -> void:
    for i in Game.SAVE_SLOT_COUNT:
        if FileAccess.file_exists(Game.slot_path(i)):DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(i)))
    var bike: Area2D = room.get_node("Interactables/SaveBicycle")
    var uid := Game.inventory.first_uid("shotgun")
    equip(uid)
    player.position = bike.position + Vector2(0, -32)
    Game.magazine = 2
    Game.health = 91
    Game.world["test_puzzle"] = true
    var first_inventory := Game.inventory.snapshot()
    check(Game.save_slot(0, bike), "Bicycle slot A saves both item upgrade types with the equipped shotgun")
    var first_file := FileAccess.get_file_as_string(Game.slot_path(0))
    Game.inventory = GridInventory.new(Game.item_catalog, 6, 3)
    Game.add_item("pistol")
    equip(Game.inventory.first_uid("pistol"))
    Game.magazine = 5
    Game.health = 62
    Game.world["test_puzzle"] = false
    var second_inventory := Game.inventory.snapshot()
    check(Game.save_slot(1, bike) and FileAccess.get_file_as_string(Game.slot_path(0)) == first_file, "Slot B can store a smaller unupgraded inventory without changing slot A")
    for index in [0, 1, 0]:
        check(Game.load_slot(index), "Saved equipment slot loads: " + str(index))
        await frames(8)
        room = get_tree().current_scene
        player = room.get_node("Actors/Player")
        foe = room.get_node("Actors/Enemy")
        hud = room.get_node("HUD")
        player.set_physics_process(false)
        foe.set_physics_process(false)
        var expected := first_inventory if index == 0 else second_inventory
        check(Game.inventory.snapshot() == expected, "Slot restores its own footprint, upgrades and loaded rounds: " + str(index))
        check(Game.health == (91 if index == 0 else 62) and Game.world["test_puzzle"] == (index == 0), "Slot restores independent health and world progress: " + str(index))
        check(player.bullet_damage == (18 if index == 0 else 26) and Game.magazine == (2 if index == 0 else 5), "Equipped weapon uses the restored instance's damage and ammo: " + str(index))
    var data: Dictionary = JSON.parse_string(first_file)
    data["version"] = 3
    for item in data["inventory"]["items"]:item.erase("upgrades")
    # Use an ordinary, noncompacted grid layout for the old version's payload.
    data["inventory"] = second_inventory.duplicate(true)
    for item in data["inventory"]["items"]:item.erase("upgrades")
    data["equipped_uid"] = data["inventory"]["items"][0]["uid"]
    check(Game._save_error(data).is_empty(), "Version-3 saves remain valid after the version-4 upgrade format")
    var old_file := FileAccess.open(Game.slot_path(2), FileAccess.WRITE)
    old_file.store_string(JSON.stringify(data))
    old_file.close()
    check(Game.save_info(2)["valid"] and Game.load_slot(2), "A version-3 slot can be previewed and loaded")
    await frames(8)
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    check(Game.magazine == 5 and player.bullet_damage == 26 and Game.has_equipped_weapon(), "Loading version 3 restores equipment and unmodified damage")
    var before := Game.inventory.snapshot()
    data["version"] = 4
    data["inventory"]["items"][0]["upgrades"] = ["missing_kit"]
    var file := FileAccess.open(Game.slot_path(2), FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
    file.close()
    check(not Game.load_slot(2) and Game.inventory.snapshot() == before, "A malformed upgrade save is rejected without altering the active inventory")
    data["version"] = 2
    data["slots"] = [{"id":"ammo","count":6}, {}, {}, {}, {}, {}, {}, {}]
    data["magazine"] = 4
    var legacy_file := FileAccess.open(Game.slot_path(3), FileAccess.WRITE)
    legacy_file.store_string(JSON.stringify(data))
    legacy_file.close()
    check(Game.save_info(3)["valid"] and Game.load_slot(3), "A legacy version-2 bicycle slot still loads")
    await frames(8)
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    check(Game.has_equipped_weapon() and Game.magazine == 4 and Game.count_item("ammo") == 6 and player.bullet_damage == 26, "Legacy implicit handgun migrates independently of the new unarmed starting loadout")
    data["scene"] = "res://scenes/levels/town.tscn"
    data["world"] = {"res://scenes/levels/town.tscn:Interactables/Item": true}
    var renamed_file := FileAccess.open(Game.slot_path(3), FileAccess.WRITE)
    var saved_text := JSON.stringify(data)
    renamed_file.store_string(saved_text)
    renamed_file.close()
    var migrated: Dictionary = Game._read_slot(3)
    check(migrated["scene"] == "res://scenes/levels/town_01.tscn" and Game._save_error(migrated).is_empty() and migrated["world"].has("res://scenes/levels/town_01.tscn:Interactables/Item"), "Reading an older save resolves the renamed scene and its collected/opened object IDs")
    check(FileAccess.get_file_as_string(Game.slot_path(3)) == saved_text, "Previewing an older renamed-location save never rewrites the user's file")
