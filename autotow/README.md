# invictus_autotow

Automated Tow Script for FiveM – **QBCore** compatible. Elimina vehículos desocupados cada X minutos (configurable) tras mostrar una **notificación** y permite cancelar mediante **ACE permissions**.

## ✨ Características
- ⏱️ Limpieza automática cada `Config.IntervalMinutes` minutos
- 📣 Notificaciones en pantalla con ox_lib
- 👥 Verificación de **todos los asientos** antes de borrar un vehículo
- 🔁 Rutina de verificación compartida entre cliente y servidor para garantizar el mismo filtrado
- 🧯 Filtros: distancia a jugadores, clases/vehículos en blacklist, emergencia/boats/aircraft opcional
- 🛡️ Permisos **ACE** para cancelar o disparar manualmente
- 🧩 100% configurable desde `config.lua`
- 🔧 Compatible con Lua 5.4 / fxmanifest (cerulean)

## 📦 Instalación
1. Copia la carpeta `invictus_autotow/` a `resources/`.
2. Añade al `server.cfg` (ajusta a tus grupos/identificadores):
   ```cfg
   ensure invictus_autotow

   # Permisos ACE
   add_ace group.admin invictus.tow.* allow
   add_ace group.admin invictus.tow.cancel allow
   add_ace group.admin invictus.tow.trigger allow

   # Ejemplo de asociación de principal a admin (ajusta al identificador real)
   # add_principal identifier.steam:110000112345678 group.admin
