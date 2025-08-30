# Invictus Craft (QBCore + ox_inventory)

Sistema de crafteo por **zonas** (sin props) para FiveM con colas, colores por disponibilidad de materiales, bloqueo por trabajo/skill, persistencia de outputs listos para recoger, NUI moderna y multilenguaje.

## Requisitos
- qb-core
- ox_inventory
- qb-target **o** ox_target (elige en `Config.InteractionType`)
- (opcional) ox_lib para notificaciones y textUI

## Instalación
1. Copia la carpeta `invictus_craft` a `resources/[custom]/invictus_craft`.
2. En tu `server.cfg`:
   ```
   ensure ox_lib
   ensure ox_inventory
   ensure qb-target   # o ox_target
   ensure invictus_craft
   ```
3. Edita `config.lua` para ajustar estaciones, recetas e idioma.

## Notas
- Validaciones de materiales/job/skills se hacen **server-side**.
- La cola se limpia en reinicios; los ítems listos se **persisten** por licencia (KVP).
