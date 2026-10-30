# Verificación

## Lógica headless (Godot 4.5)

Comando:

```bash
godot --headless --path game --quit-after 120 -- --smoke-test
```

Resultado: `UMBRAL_SMOKE_END checks=82 failures=0` (plantilla debug de Godot 4.5).

Cobertura: catálogo de 29 armas, existencia de modelos, tres ranuras, compatibilidad melee/fuego, munición inicial, consumo por disparo, recarga con transferencia real, reemplazo persistente, vidrio y tabiques acumulativos, spawn enemigo, daño melee, impulso por masa, muerte, ragdoll articulado, caja única, munición acotada, spawner sin repetición inmediata, daño al jugador y estado de muerte.

Log: `docs/smoke-test.log`. Arranque en debug: `docs/startup-debug.log` (sin `SCRIPT ERROR`, sin error de `cell_height` y sin fugas de ObjectDB).

Correcciones verificadas tras el reporte en editor Linux/XFCE:

- El HUD se crea antes del primer `equip`; `equip/replace_slot` toleran HUD ausente.
- Navegación: `default_cell_size=0.25` y `default_cell_height=0.2` coinciden con el navmesh.
- Se eliminó `no_depth_test` del viewmodel y MSAA 3D en Compatibility para evitar artefactos/pantalla blanca en drivers OpenGL problemáticos.
- Se corrigieron las 7 advertencias de GDScript (ternaria incompatible, parámetro sin uso, divisiones enteras, nombres sombreados y color de traza sin uso).
- `CPUParticles3D` se reinicia con `emitting=false/true`, no con un método `stop()` inexistente.
- El audio libera playbacks Ogg al salir; en headless se omite el driver dummy para evitar fugas en CI.

## Navegador (WebGL2)

Se probó la vista previa con Chromium headless y renderizado por software:

- Arranque del motor y carga del paquete sin errores de consola.
- Menú, entrada a partida, movimiento con teclado, disparo, recarga, apertura de caja, selección de reemplazo, ragdoll, pausa y muerte.
- Navegación con ruta válida de 11 puntos entre el jugador y el sector opuesto.
- Capturas: `docs/menu-preview.png`, `docs/gameplay-preview.png`, `docs/loot-preview.png`.

Nota: el sandbox no tiene GPU; las pruebas automáticas usan SwiftShader y pueden ir a 1–3 FPS. En un navegador de escritorio con aceleración gráfica el rendimiento esperado es mayor. La calidad web por defecto es baja y reduce resolución 3D, sombras y presupuesto de enemigos.
