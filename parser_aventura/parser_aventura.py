"""
Parser para el lenguaje de aventuras.

Sintaxis soportada:

# SECCION
Texto narrativo.

?llave -> PUERTA
?moneda ?guante -> TIENDA

1 Acción -> SECCION
2 Acción -> SECCION [+pocion, xp-5]
"""

from dataclasses import dataclass, field
import re


@dataclass
class ConditionalJump:
    conditions: list[str]
    target: str
    line: int


@dataclass
class Option:
    number: int
    text: str
    target: str
    effects: list[str] = field(default_factory=list)
    line: int = 0


@dataclass
class Section:
    name: str
    text: list[str] = field(default_factory=list)
    conditions: list[ConditionalJump] = field(default_factory=list)
    options: list[Option] = field(default_factory=list)


@dataclass
class Adventure:
    sections: dict[str, Section]


class ParseError(Exception):
    pass


SECTION_RE = re.compile(r"^#\s+(.+?)\s*$")
CONDITION_RE = re.compile(r"^((?:\?\w+\s*)+)->\s*(\w+)\s*$")
OPTION_RE = re.compile(r"^(\d+)\s+(.+?)\s*->\s*(\w+)(?:\s*\[(.*?)\])?\s*$")
EFFECT_RE = re.compile(r"^[+-](?:\w+|xp[+-]\d+)$")


def strip_comment(line: str) -> str:
    """Elimina comentarios // sin tocar el texto antes del comentario."""
    return line.split("//", 1)[0].rstrip()


def parse_effects(raw: str | None, line_number: int) -> list[str]:
    if not raw:
        return []

    effects = []
    for item in raw.split(","):
        item = item.strip()
        if not item:
            continue
        if not EFFECT_RE.fullmatch(item):
            raise ParseError(
                f"Línea {line_number}: efecto no válido: {item!r}"
            )
        effects.append(item)

    return effects


def parse(text: str) -> Adventure:
    sections: dict[str, Section] = {}
    current: Section | None = None

    for line_number, raw_line in enumerate(text.splitlines(), 1):
        line = strip_comment(raw_line).strip()

        if not line:
            continue

        # Nueva sección
        match = SECTION_RE.match(line)
        if match:
            name = match.group(1).strip()

            if name in sections:
                raise ParseError(
                    f"Línea {line_number}: sección duplicada: {name!r}"
                )

            current = Section(name=name)
            sections[name] = current
            continue

        if current is None:
            raise ParseError(
                f"Línea {line_number}: contenido fuera de una sección."
            )

        # Salto condicional
        match = CONDITION_RE.match(line)
        if match:
            condition_text, target = match.groups()
            conditions = re.findall(r"\?(\w+)", condition_text)

            current.conditions.append(
                ConditionalJump(
                    conditions=conditions,
                    target=target,
                    line=line_number,
                )
            )
            continue

        # Opción numerada
        match = OPTION_RE.match(line)
        if match:
            number, option_text, target, raw_effects = match.groups()

            current.options.append(
                Option(
                    number=int(number),
                    text=option_text.strip(),
                    target=target,
                    effects=parse_effects(raw_effects, line_number),
                    line=line_number,
                )
            )
            continue

        # Texto narrativo
        current.text.append(line)

    if not sections:
        raise ParseError("No se ha encontrado ninguna sección.")

    # Validaciones posteriores
    for section in sections.values():
        for condition in section.conditions:
            if condition.target not in sections:
                raise ParseError(
                    f"Línea {condition.line}: la sección destino "
                    f"{condition.target!r} no existe."
                )

        for option in section.options:
            if option.target not in sections:
                raise ParseError(
                    f"Línea {option.line}: la sección destino "
                    f"{option.target!r} no existe."
                )

    return Adventure(sections=sections)


def parse_file(filename: str) -> Adventure:
    with open(filename, "r", encoding="utf-8") as file:
        return parse(file.read())
