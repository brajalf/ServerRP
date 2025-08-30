# qb-jobcreator

## Zonas de tienda y recetas de crafteo

Las zonas de tipo `shop` ahora permiten gestionar artículos desde la interfaz web.  Cada artículo posee:

- `name` – nombre del ítem en el inventario.
- `price` – precio de venta al jugador.
- `count` – cantidad disponible inicialmente.
- `info` – metadatos opcionales (se envían como `metadata` al abrir la tienda).

Los elementos se almacenan en `jobcreator_zones.data.items` y el servidor valida los datos al crear o actualizar la zona.

### Relacionar tiendas y crafteo

Para cerrar el ciclo de materiales puedes vincular estas tiendas con las recetas de crafteo definidas en `Config.CraftingRecipes`:

1. Configura en la receta los `inputs` que los empleados deberán comprar o recolectar.
2. Añade esos mismos ítems como productos en la tienda del trabajo, para que los jugadores puedan adquirirlos.
3. El `output` de la receta puede venderse nuevamente en otra tienda o utilizarse como material para nuevas recetas.

Ejemplo simple:

```lua
-- config.lua
Config.CraftingRecipes = {
  metal_bar = {
    inputs = { { item = 'metal_ore', amount = 2 } },
    output = { item = 'metal_bar', amount = 1 },
    time = 3000,
    blueprint = 'metal_bar_blueprint', -- opcional
    skill = 'smithing',                -- opcional
    successChance = 80                 -- 0-100
  }
}
```

En la tienda del herrero añade `metal_ore` con el precio y stock deseado.  Los trabajadores comprarán el mineral, lo refinarán mediante la receta anterior y luego podrán vender las `metal_bar` o utilizarlas en otras recetas.
## Crafteo integrado

`qb-jobcreator` ahora incluye un módulo de crafteo propio.  Las recetas se definen en
`Config.CraftingRecipes` y cada zona de tipo `crafting` puede habilitar una lista de
recetas permitidas.  Cada receta requiere `inputs`, `time` y `output`, y puede
incluir opcionalmente `blueprint`, `skill` y `successChance`.

Se soportan planos opcionales y bonificaciones por habilidad mediante `qb-skillz`;
el servidor verifica los materiales y entrega el resultado al jugador cuando el
proceso finaliza.

## Integraciones de inventario

En `config.lua`, dentro de `Config.Integrations`, se añadieron las opciones:

```lua
UseOxInventory = false, -- habilita la capa para ox_inventory si el recurso está iniciado
UseQbInventory = false, -- fuerza el uso de qb-inventory
```

Las funciones de manejo de inventario (`HasItem`, `RemoveItem` y `AddItem`) detectan automáticamente `ox_inventory` y utilizan la integración apropiada.
