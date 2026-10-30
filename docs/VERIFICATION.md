# Verificación

## Lógica headless (Godot 4.5)

Comando:

```bash
godot --headless --path game --quit-after 120 -- --smoke-test
```

Resultado: `UMBRAL_SMOKE_END checks=79 failures=0`.

Cobertura: catálogo de 29 armas, existencia de modelos, tres ranuras, compatibilidad melee/fuego, munición inicial, consumo por disparo, recarga con transferencia real, reemplazo persistente, vidrio y tabiques acumulativos, spawn enemigo, daño melee, impulso por masa, muerte, ragdoll articulado, caja única, munición acotada, spawner sin repetición inmediata, daño al jugador y estado de muerte.

Log: `docs/smoke-test.log`.

## Navegador (WebGL2)

Se probó la vista previa con Chromium headless y renderizado por software:

- Arranque del motor y carga del paquete sin errores de consola.
- Menú, entrada a partida, movimiento con teclado, disparo, recarga, apertura de caja, selección de reemplazo, ragdoll, pausa y muerte.
- Navegación con ruta válida de 11 puntos entre el jugador y el sector opuesto.
- Capturas: `docs/menu-preview.png`, `docs/gameplay-preview.png`, `docs/loot-preview.png`.

Nota: el sandbox no tiene GPU; las pruebas automáticas usan SwiftShader y pueden ir a 1–3 FPS. En un navegador de escritorio con aceleración gráfica el rendimiento esperado es mayor. La calidad web por defecto es baja y reduce resolución 3D, sombras y presupuesto de enemigos.
