# Alles Ausladen - Quick Unload

Arma 3 QoL addon: unloads the complete cargo of a vehicle or crate via the scroll menu in a single click. No more clicking through 80 Stingers one by one.

**Requires: [CBA_A3](https://steamcommunity.com/sharedfiles/filedetails/?id=450814997)**  
Server AND all clients need this mod.

## Features
- **Unload all** → dumps entire cargo on the ground in front of the object
- **Pull cargo from nearby** → pulls the nearest cargo source (configurable radius) into this container
- **What's inside?** → posts top 5 contents to group chat (visible for all players)
- Magazine fill levels and weapon attachments are preserved
- Worn backpacks and equipment are never looted
- Driver seat lock (configurable)
- CBA settings menu (driver lock, loot radius, toggle actions/hint)
- Easter egg 🥤

## Installation
1. Copy `@AllesAusladen` into your Arma 3 directory
2. Load via the Arma 3 Launcher as a local mod alongside CBA_A3
3. Server AND all clients require the mod (`verifySignatures = 0` on private servers)

## Building from source
```
python3 pack.py
```
Requires Python 3. Output: `@AllesAusladen/addons/bob_unload.pbo`

## Changelog
- **v1.0** — Initial release. Unload to ground, pull cargo from nearby.
- **v1.1** — Driver seat lock, backpack protection, item count in chat.
- **v1.1a** — Fix: item count message now reaches the triggering player correctly.
- **v1.1b** — Switched from hint to systemChat, survives Antistasi hint spam.
- **v1.1c** — "What's inside?" action, CBA settings menu, Easter egg.
- **v1.1d-f** — Bugfixes: actions on foot/existing objects, Can classname, grabCargo syntax.

## Workshop
[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3769280136)

## License
MIT
