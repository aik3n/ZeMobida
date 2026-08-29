# ZeMobida — Technical Audit

**Fecha:** 2026-08-29  
**Estado:** sincronización incremental implementada y validada en ejecución.

## Resultado

La sincronización de guiones ahora incluye:

- `Actualizar guiones al iniciar: Sí / No`;
- manifest local con SHA por archivo;
- descargas incrementales;
- almacenamiento temporal;
- validación antes de activar;
- conservación de caché anterior ante fallo;
- timeout global configurable de 30 segundos por defecto;
- comprobación antes de permitir entrar al mapa.

La implementación fue probada en ejecución y confirmada como funcional.

## Riesgos pendientes

### Alto — Referencia remota mutable
Actualmente se utiliza `main`.

**Recomendación:** estudiar una referencia inmutable, como commit SHA o release de contenido.

### Alto — Tests automatizados
No existe una suite automatizada completa visible para parser, validator, updater y persistencia.

**Recomendación:** añadir tests headless y CI.

### Alto — Metadatos de distribución
Persisten elementos de prototipo en configuración/exportación.

**Recomendación:** completar identidad, package ID, versión y firma antes de release.

### Medio — Ciclos automáticos
El runtime sigue saltos automáticos recursivamente y el validator no detecta todos los ciclos.

**Recomendación:** detectar ciclos y añadir límite de transiciones.

### Medio — Tablas de XP duplicadas
Los umbrales aparecen en más de un lugar.

**Recomendación:** centralizar configuración.

### Bajo — Acoplamiento al SceneTree
Algunas partes dependen de nombres concretos y búsquedas dinámicas.

**Recomendación:** mejorar contratos si el proyecto crece.

## Estado documental

La documentación actual refleja el comportamiento implementado, incluyendo sincronización por SHA, opción de usuario, timeout, validación previa y fallback a caché.

El contenido de `guiones/` del repositorio es contenido versionado; `user://dialogues/` es la caché runtime.
