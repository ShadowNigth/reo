# UMBRAL — avisos de terceros

Fecha de preparación: 2026-10-29. Proyecto personal no comercial. Las licencias originales se conservan junto a los recursos.

## Mapa y texturas

- **Abandoned Spaceship Godot Demo** — Jaanus Jaggo / Perfoon. Repositorio: https://github.com/perfoon/Abandoned-Spaceship-Godot-Demo (commit `5ddf086848abdcb67414406d148dc81a8b06b15b`).
- Recursos del mapa: **CC BY-NC 4.0** (atribución, no comercial). Código original del demo: MIT. Texto incluido: `game/assets/world/HANGAR_LICENSE.txt`.
- Archivos usados: `SpaceCraftHangar.glb`, `Objects.glb`, `Outside.glb`, texturas PBR dehormigón/metal/vegetación y 190 colocaciones de props extraídas a `layout.json`.
- Modificaciones: recorte de texturas, conversión de escenas a datos de colocación, materiales PBR simplificados, colisiones, navegación y paneles destructibles añadidos. El casco arquitectónico original no es totalmente destructible.

## Modelos 3D

- **Quaternius — Zombie Apocalypse Kit** (CC0 1.0): zombis, bate, escopeta, rifle y SMG. Fuente original: https://quaternius.com/packs/zombieapocalypsekit.html. Copia GLB obtenida de https://github.com/Saos-EBB/kev.dev; aviso incluido en `game/assets/models/UPSTREAM_NOTICE.md`.
- **Kenney — Weapon Pack** (CC0 1.0): 30 armas/ammo OBJ convertidos a GLB preservando posiciones, normales y colores. Fuente: https://kenney.nl/assets/weapon-pack; espejo https://github.com/ETdoFresh/kenney.nl (commit `45df48c4d45f8716216b1a9e22df0b69cd9f5932`). Licencia: `game/assets/weapons/KENNEY_LICENSE.txt`.
- **Kenney — Starter Kit FPS** (MIT para el código; recursos CC0): blaster y blaster-repeater. Repositorio https://github.com/KenneyNL/Starter-Kit-FPS (commit `185fd2326d74a5cf858cffc616f87cf9696f9cc0`).

## Efectos visuales

- **Kenney — Particle Pack 1.1** (CC0 1.0): 10 texturas PNG para humo, sangre, chispas, decals y trazas. Fuente: https://kenney.nl/assets/particle-pack; espejo ETdoFresh/kenney.nl. Licencia: `game/assets/fx/KENNEY_LICENSE.txt`.
- Los sistemas de partículas, decals, trazas, explosiones y ragdolls están implementados en GDScript sobre esos recursos.

## Audio

- **Kenney** (CC0 1.0): blaster, recarga, pasos, impactos, UI y ambiente. Fuente: https://kenney.nl/assets/category:Audio; espejo Starter Kit FPS y ETdoFresh/kenney.nl.
- **OpenGameArt / open-game-sfx-index** (CC0 1.0): zombis, golpes, vidrio, roturas, slime, explosiones y ambiente. Índice: https://github.com/Legerdo/open-game-sfx-index (commit `d463e4d24ea2c18a75b27de8da1532642d80483c`).
- Inventario completo con archivo original, autor, fuente, licencia y SHA-256: `docs/audio_manifest.json`. Copias legibles: `game/assets/audio/ATTRIBUTION.md` y `SOURCES.md`.

### Grupos de audio descargados

- **impact-sounds** — Kenney / ver SOURCES.md · CC0-1.0 · https://kenney.nl/assets/impact-sounds · 23 archivos.
- **oga-rubberduck-breaking-75** — rubberduck · CC0-1.0 · https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx · 6 archivos.
- **oga-rubberduck-loops-30** — rubberduck · CC0-1.0 · https://opengameart.org/content/30-cc0-sfx-loops · 5 archivos.
- **oga-rubberduck-scifi-50** — rubberduck · CC0-1.0 · https://opengameart.org/content/50-cc0-sci-fi-sfx · 2 archivos.
- **oga-rubberduck-water-40** — rubberduck · CC0-1.0 · https://opengameart.org/content/40-cc0-water-splash-slime-sfx · 5 archivos.
- **oga-zombies** — Kenney / ver SOURCES.md · CC0-1.0 · https://opengameart.org/content/zombies-sound-pack · 6 archivos.
- **rpg-audio** — Kenney / ver SOURCES.md · CC0-1.0 · https://kenney.nl/assets/rpg-audio · 16 archivos.

## Fuentes

- **Barlow Condensed** — Jeremy Tribby / Barlow Project Authors, SIL OFL 1.1. Fuente: https://github.com/google/fonts/tree/main/ofl/barlowcondensed. Licencia: `game/assets/fonts/OFL.txt`.
- **Lilita One** — included con Kenney Starter Kit FPS; licencia del paquete: `game/assets/fonts/KENNEY_LICENSE.md`.

## Motor y runtime web

- **Godot Engine** — MIT. Proyecto editado para Godot 4.5+. La vista previa web usa el runtime oficial 4.7.2 nothreads (WebGL2) empaquetado con los recursos del proyecto. Licencia: `web/GODOT_LICENSE.txt`.
- Runtime web obtenido de https://github.com/ChanceFlow/godot-web-templates (commit `36ea472a53b68b4f644c8466e2ee8a668d13e5c7`); worklets de audio del repositorio godotengine/godot, tag 4.7.2-stable.

## Nota de alcance

UMBRAL es un prototipo ampliable, no un juego AAA terminado. La destrucción se aplica a tabiques, cristales, cajas y barriles diseñados para gameplay; no a toda la malla arquitectónica. Los cinco arquetipos de enemigo comparten dos mallas base con variaciones de escala, color, velocidad, vida y comportamiento. Las 29 armas comparten familias de mecánicas (melee, hitscan, perdigones, proyectiles, energía) con parámetros propios.

El uso personal no elimina las licencias. No redistribuir el mapa con fines comerciales sin permiso de su autor.