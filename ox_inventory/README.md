## ⚠️ Notice

This version of `ox_inventory` has been modified to improve compatibility with the latest versions of **qb-core**. It began as a continuation of an older fork which originally reintroduced QB compatibility but is no longer available. Since then, this fork has evolved into a community-focused version aimed at ensuring broad compatibility while introducing small, non-intrusive quality-of-life enhancements.

**Important:**
The original `ox_inventory` was developed by the **Overextended** team, but is no longer actively maintained by them and remains under its original license.
This modified version is **not officially supported by the Overextended team**.
Please do **not contact them** for issues related to this fork.

---

### Purpose

This fork exists to provide a more collaborative and inclusive solution for the FiveM community. We believe in open-source software that evolves with the input of its users, encouraging innovation and adaptation through collective development.

---

## Key Differences from Other Forks

### Rarity Indicators (Optional Visual Feature)

* Items can now display colored borders and glow effects based on a `"rarity"` metadata key.
* Supported values: `common`, `uncommon`, `rare`, `epic`, `legendary`, `artifact`, `red`, `pink`, `gold`.

### Modern QB-Core Compatibility Restored

* Fully re-integrated with the latest versions of **qb-core**.
* Preserves full support for **ESX**, **ox\_core**, **QBox**, and **ND\_Core** — no features are lost for users of these frameworks.

### Additional Image Extensions Supported

* Out-of-the-box support for `.jpg`, `.jpeg`, and `.gif` image formats.
* No need for manual configuration to use these file types.

### More Image Hosting Sources Allowed

* Now supports image links from additional domains like **img.bb** and **Discord CDN**.
* Simplifies the use of externally hosted images for inventory icons or embedded content.


# ox_inventory

A complete inventory system for FiveM, implementing items, weapons, shops, and more without any strict framework dependency.

![](https://img.shields.io/github/downloads/TheOrderFivem/ox_inventory/total?logo=github)
![](https://img.shields.io/github/downloads/TheOrderFivem/ox_inventory/latest/total?logo=github)
![](https://img.shields.io/github/contributors/TheOrderFivem/ox_inventory?logo=github)
![](https://img.shields.io/github/v/release/TheOrderFivem/ox_inventory?logo=github)

## 📚 Documentation

https://coxdocs.dev/ox_inventory

## 💾 Download

https://github.com/TheOrderFivem/ox_inventory/releases/latest/download/ox_inventory.zip

## Supported frameworks

We do not guarantee compatibility or support for third-party resources.

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [esx](https://github.com/esx-framework/esx_core)
- [qbox](https://github.com/Qbox-project/qbx_core)
- [ox_core](https://github.com/communityox/ox_core)
- [nd_core](https://github.com/ND-Framework/ND_Core)

## Wrapper exports

To simplify cross-resource integrations, `ox_inventory` provides generic server exports
that automatically call the appropriate inventory system based on `shared.framework`.
Scripts should prefer these helpers over directly invoking a specific inventory API.

```lua
-- open a stash for a player
exports.ox_inventory:OpenStash(source, 'mystash')

-- open a registered shop
exports.ox_inventory:OpenShop(source, 'twentyfourseven')
```

## ✨ Features

- Server-side security ensures interactions with items, shops, and stashes are all validated.
- Logging for important events, such as purchases, item movement, and item creation or removal.
- Supports player-owned vehicles, licenses, and group systems implemented by frameworks.
- Fully synchronised, allowing multiple players to [access the same inventory](https://user-images.githubusercontent.com/65407488/230926091-c0033732-d293-48c9-9d62-6f6ae0a8a488.mp4).

### Items

- Inventory items are stored per-slot, with customisable metadata to support item uniqueness.
- Overrides default weapon-system with weapons as items.
- Weapon attachments and ammo system, including special ammo types.
- Durability, allowing items to be depleted or removed overtime.
- Internal item system provides secure and easy handling for item use effects.
- Compatibility with 3rd party framework item registration.

### Shops

- Restricted access based on groups and licenses.
- Support different currency for items (black money, poker chips, etc).

### Stashes

- Personal stashes, linking a stash with a specific identifier or creating per-player instances.
- Restricted access based on groups.
- Registration of new stashes from any resource.
- Containers allow access to stashes when using an item, like a paperbag or backpack.
- Access gloveboxes and trunks for any vehicle.
- Random item generation inside dumpsters and unowned vehicles.

## Copyright

Copyright © 2024 Overextended <https://github.com/overextended>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
