# Browns QB Reload Weapons by Brown Development
# Now works with qb, lj, ps, and ox inventory through a configurable bridge!
# Preview Video: https://youtu.be/TLSnJvRJPEI


IF YOU LIKE THIS SCRIPT THEN CHECK OUT MY TEBEX FOR MORE DOPE STUFF: https://brown-development.tebex.io/

Personal Discord: bwobrown
Discord Server: https://discord.gg/dGRHNbX5xc

[EXPORTS] (Reloads Weapon, CLIENT SIDED)

exports['Browns-QBWeaponReload']:ReloadWeapon()

[INSTALLATION] (IF YOU NEED HELP SETTING UP, OR FEEL LIKE YOU MAY BREAK SOMETHING CONTACT ME AT MY DISCORD ABOVE)

# STEP 1:

backup your qb-weapons (not because something may break but just because its a good habit to backup vital scripts like qb-weapons before modifying)

# STEP 2: 

go to qb-weapons > client > main.lua 

# STEP 3: 

find the 'weapons:client:AddAmmo' event (should be at around line 77) then DELETE THE ENTIRE EVENT

# STEP 4: 

go to qb-weapons > server > main.lua 

# STEP 5:

restore the QBCore.Functions.CreateUseableItem functions for each ammo type in `qb-weapons/server/main.lua` and make them trigger the new `inventory:client:UseAmmo` event. They should look like this:

```
for ammoItem, _ in pairs(Config.AmmoTypes) do
    QBCore.Functions.CreateUseableItem(ammoItem, function(source, item)
        TriggerClientEvent('inventory:client:UseAmmo', source)
    end)
end
```

Using an ammo item now calls the exported `ReloadWeapon` function. Players can still press **R** thanks to the key mapping in `client.lua`.

## Inventory Configuration

Set your inventory system in `config.lua` to one of the supported values: `qb-inventory`, `lj-inventory`, `ps-inventory`, or `ox_inventory`. The script automatically selects the correct adapter through the new inventory bridge.

## Manual Testing

Manual reload test cases for each supported inventory are available in [TESTING.md](TESTING.md).
