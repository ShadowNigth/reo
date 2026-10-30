# UMBRAL — Protocolo Cero

FPS 3D de supervivencia y horror hecho en **Godot**. Proyecto personal, ampliable y no comercial.

## Jugar

- **Vista previa web:** usá el preview en vivo de Arena. Requiere WebGL2, teclado y ratón. Si el navegador o el iframe bloquean la captura del ratón, podés arrastrar con clic para apuntar.
- **Proyecto editable:** abrí `game/project.godot` con **Godot 4.5 o superior** y ejecutá el proyecto (`F6` sobre la escena principal o `F5`).
- Escena principal: `game/scenes/main.tscn`.
- La vista previa web empaqueta los mismos recursos raw del proyecto y usa un runtime Godot 4.7.2 nothreads. El proyecto fuente está pensado para Godot 4.5+.

## Controles

| Acción | Tecla / ratón |
|---|---|
| Moverse | W A S D |
| Apuntar | Ratón |
| Correr | Shift |
| Saltar | Espacio |
| Atacar / disparar | Clic izquierdo |
| Apuntar con arma | Clic derecho |
| Recargar | R |
| Recoger / abrir caja | E |
| Equipar ranura | 1 / 2 / 3 |
| Arma anterior | Q o rueda |
| Linterna | F |
| Granada | G |
| Pausa | Esc |

## Qué incluye

- Mapa 3D descargado: **Abandoned Spaceship** de Jaanus Jaggo / Perfoon, con texturas PBR, vegetación, props y colisiones.
- Oleadas infinitas hasta morir o salir. El director mantiene un límite de enemigos activos, pero no un límite total de partida.
- 5 arquetipos de enemigo: errante, desgarrador, coloso, reptante y acechador. Varían vida, velocidad, daño, masa, tamaño, color y comportamiento.
- Spawner con 12 puntos candidatos, variación aleatoria de posición, bolsas por oleada y bloqueo de repetición inmediata.
- 29 armas: melee, pistolas, escopetas, SMG, rifle, ametralladora, francotiradores, lanzacohetes/lanzagranadas, lanzallamas y energía.
- Tres ranuras: la 1 solo admite melee; la 2 y la 3 admiten cualquier arma de fuego. Al abrir la caja elegís qué reemplazar.
- Una única plataforma de caja especial. Tras reclamarla, vuelve a los 75 segundos.
- Munición escasa: 12% de probabilidad por baja,garantía a los 14 asesinatos sin suministro y máximo 3 cajas de munición en el suelo.
- Melee con barrido físico, empuje por masa, hitstop, sacudida, sonido y daño.
- Ragdolls articulados con `PhysicalBone3D` al morir, con presupuesto máximo de cadáveres activos.
- Destrucción acumulativa de tabiques, cristales, cajas y barriles explosivos. Las explosiones también dañan al jugador.
- Sangre, decals, partículas, trazas, fragmentos rígidos, audio 3D, linterna, granadas, menú, pausa, configuración y pantalla de muerte.
- Presupuesto de efectos y enemigos para sesiones largas: pooling de audio/partículas/trazas, límites de decals y fragmentos, y limpieza de cadáveres.

## Alcance honesto

Esto es un **prototipo jugable ampliable**, no un AAA terminado.

- La destrucción se aplica a elementos de gameplay añadidos al mapa, no a toda la malla arquitectónica original.
- Los enemigos usan dos mallas base descargadas con variaciones de escala, material y parámetros; no son cinco modelos completamente distintos.
- Las armas comparten familias de mecánicas con parámetros propios. No hay animaciones únicas de recarga por arma ni manos en primera persona.
- La navegación se recalcula tras destruir elementos. En máquinas lentas puede haber un pequeño tirón al rehorneear.
- La vista previa web depende de WebGL2 y de la GPU del navegador. En el sandbox de Arena se usa renderizado por software para las pruebas, por eso las capturas automáticas pueden ir lentas.

## Estructura

```text
game/
  project.godot
  scenes/main.tscn
  scripts/          # mundo, jugador, enemigos, director, armas, FX, audio, HUD
  assets/           # recursos descargados y licencias
  tests/smoke.gd    # prueba headless de lógica
web/                # runtime y paquete de la vista previa
tools/              # preparación de recursos, empaquetado y servidor local
docs/               # controles, alcance, licencias e inventario de audio
```

## Pruebas

Con un binario de Godot 4.5+ disponible en el PATH:

```bash
godot --headless --path game --quit-after 120 -- --smoke-test
```

Regresión de arranque recomendada con plantillas **debug** (las release no imprimen todos los errores de GDScript):

```bash
godot --headless --path game --quit-after 10
```

Debe terminar sin `SCRIPT ERROR`, sin errores de navegación y sin `ObjectDB instances leaked`.

Resultado esperado:

```text
UMBRAL_SMOKE_END checks=82 failures=0
```

La prueba cubre catálogo de armas, ranuras, munición inicial, disparo, recarga, reemplazo, destrucción, daño enemigo, ragdoll, caja única, munición, spawner sin repetición inmediata, daño al jugador y muerte.

Para servir la vista previa web localmente:

```bash
python tools/serve_web.py
# abrir http://localhost:8060
```

Para reempaquetar los recursos raw si se modifica `game/`:

```bash
godot --headless --path game --script tools/package_game.gd -- web/umbral.pck
```

## Licencias y créditos

Ver [docs/THIRD_PARTY_NOTICES.md](docs/THIRD_PARTY_NOTICES.md). El mapa es **CC BY-NC 4.0**, adecuado para este proyecto personal no comercial. El uso personal no elimina las licencias; no redistribuir el mapa con fines comerciales sin permiso de su autor.
