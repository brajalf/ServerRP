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
    time = 3000
  }
}
```

En la tienda del herrero añade `metal_ore` con el precio y stock deseado.  Los trabajadores comprarán el mineral, lo refinarán mediante la receta anterior y luego podrán vender las `metal_bar` o utilizarlas en otras recetas.

## Integración con RaySist-Crafting

Este recurso delega el sistema de crafteo en **RaySist-Crafting**, por lo que dicho recurso debe estar instalado y en ejecución.

- Las recetas y categorías de crafteo se almacenan en la base de datos del recurso externo.
- Configura las recetas y categorías necesarias antes de utilizar las mesas de crafteo creadas con `qb-jobcreator`.
- RaySist-Crafting gestiona el inventario, las habilidades y los planos requeridos para cada receta.

Sin esta dependencia las zonas de tipo `crafting` no funcionarán correctamente.
