# Manual Reload Testing

The following cases verify weapon reloading using each supported inventory system.

## qb-inventory
1. Set `config.inventory` to `qb-inventory`.
2. Give a player an ammo item (e.g. `pistol_ammo`).
3. Fire a few rounds and press **R**.
4. Confirm that ammo is added to the weapon and the item count decreases.

## lj-inventory
1. Set `config.inventory` to `lj-inventory`.
2. Provide the appropriate ammo item.
3. Reload the weapon with **R** or the `ReloadWeapon` export.
4. Ensure the ammo item is removed and the weapon ammo increases.

## ps-inventory
1. Set `config.inventory` to `ps-inventory`.
2. Give a player an ammo item.
3. Reload and verify ammo usage mirrors inventory counts.

## ox_inventory
1. Set `config.inventory` to `ox_inventory`.
2. Grant the player ammo and attempt a reload.
3. Check that `ox_inventory` shows the item count reduced by the reloaded amount.
