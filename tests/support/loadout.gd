extends RefCounted
## Combat fixtures supply equipment explicitly; new games may start unarmed.
static func handgun() -> void:
    if Game.count_item("pistol") == 0:
        Game.add_item("pistol")
    var uid := Game.inventory.first_uid("pistol")
    if Game.equipped_uid != uid:
        Game.equip_weapon(uid)
    Game.magazine = 6
    Game.changed.emit()
