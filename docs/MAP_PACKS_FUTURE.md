# ZeMobida — Posible separación futura de mapas

**Estado:** propuesta de mejora futura. No implementada.

## Objetivo

Separar el desarrollo del juego/motor del desarrollo de los mapas para que varias personas puedan crear mapas sin trabajar sobre el mismo proyecto principal ni interferir entre sí.

La idea sería tratar los mapas como contenido distribuible, mientras ZeMobida conserva toda la lógica de juego.

## Posible modelo

Cada mapa podría desarrollarse en un proyecto Godot independiente y exportarse como un paquete `.pck`.

Ejemplo:

```text
ZeMobida
    → juego / motor

ZeMobida-map-aldea
    → proyecto de trabajo del mapa Aldea
    → exporta aldea.pck

ZeMobida-map-urrea
    → proyecto de trabajo del mapa Urrea
    → exporta urrea.pck
```

ZeMobida cargaría posteriormente esos paquetes mediante `ProjectSettings.load_resource_pack()`.

## Responsabilidades

El mapa debería definir únicamente contenido y configuración:

```text
mapa
├── Fondo
├── Preview
├── SpawnPlayer
├── colisiones
├── capa frontal opcional
└── definiciones de PNJ
```

El motor seguiría siendo responsable de:

```text
Player
PNJ real
seguimiento
interacción
diálogos
inventario
XP
persistencia
cámara
UI
```

## PNJ: definición en el mapa, comportamiento en el motor

Una posible mejora especialmente interesante es que el paquete del mapa **no contenga `pnj.gd` ni una copia funcional de `pnj.tscn`**.

El creador del mapa sólo definiría los datos necesarios de cada PNJ, por ejemplo:

```text
juan
├── posición
├── sprite
└── tipo_seguimiento
```

Al cargar el mapa, ZeMobida utilizaría esa definición para instanciar **su propio** `pnj.tscn` y aplicarle la configuración:

```text
definición de Juan en el mapa
        ↓
ZeMobida instancia su pnj.tscn
        ↓
aplica nombre
aplica posición
aplica sprite
aplica tipo de seguimiento
        ↓
PNJ funcionando con la lógica del motor
```

De esta forma, el creador del mapa decide **qué PNJ existe y cómo se presenta**, pero no puede modificar la implementación del comportamiento del PNJ.

## Ventajas

- Cada creador puede trabajar en un repositorio/proyecto independiente.
- Un mapa no necesita incluir ni mantener una copia de `pnj.gd`.
- Una corrección en el PNJ del motor se aplicaría automáticamente a todos los mapas compatibles.
- El contenido queda separado de la lógica de juego.
- Se reduce el riesgo de que un creador de mapas modifique accidentalmente scripts centrales.
- Los mapas podrían distribuirse o actualizarse independientemente del ejecutable principal.

## Rutas y aislamiento

Si se adopta este sistema, cada mapa debería tener un espacio de rutas propio para evitar colisiones entre paquetes.

Ejemplo:

```text
res://map_packs/aldea/...
res://map_packs/urrea/...
res://map_packs/casco_viejo/...
```

## Seguridad

Un `.pck` no es una sandbox.

Si se admitieran paquetes creados por usuarios no confiables, no deberían poder introducir scripts arbitrarios que el juego ejecute. El modelo basado en datos y en PNJ instanciados por el motor ayudaría a limitar esa superficie.

## Decisión actual

No se implementa todavía.

El proyecto continúa usando los mapas integrados en:

```text
res://mapas/
```

Esta propuesta se conserva como posible evolución de producción/distribución cuando la separación entre motor y creación de mapas sea necesaria.
