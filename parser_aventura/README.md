# Parser + programa de prueba

Archivos:

- `parser_aventura.py`: parser del lenguaje.
- `prueba.py`: programa interactivo que utiliza el parser.
- `aventura.txt`: aventura de ejemplo.

## Ejecutar

```bash
python prueba.py
```

Primero se ejecuta un test del parser y después comienza la aventura.

## Qué reconoce el parser

### Secciones

```text
# INICIO
```

### Texto

```text
Hola, aventurero.
```

### Condiciones

```text
?llave -> PUERTA
?moneda ?guante -> TIENDA
```

### Opciones

```text
1 Abrir la puerta -> FINAL
```

### Efectos

```text
1 Comprar -> TIENDA [+pocion, xp-5]
```

Los comentarios que empiezan con `//` se ignoran.

El parser además comprueba que las secciones destino existan y genera errores con el número de línea cuando encuentra sintaxis inválida.
