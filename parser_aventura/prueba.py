"""
Programa de prueba del parser.

Ejecutar:
    python prueba.py

Por defecto carga aventura.txt.
"""

from dataclasses import dataclass, field
from pathlib import Path

from parser_aventura import Adventure, parse_file


@dataclass
class GameState:
    section: str = "INICIO"
    inventory: set[str] = field(default_factory=set)
    xp: int = 0


def apply_effects(state: GameState, effects: list[str]) -> None:
    for effect in effects:
        if effect.startswith("+xp"):
            state.xp += int(effect[3:])
        elif effect.startswith("-xp"):
            state.xp -= int(effect[3:])
        elif effect.startswith("+"):
            state.inventory.add(effect[1:])
        elif effect.startswith("-"):
            state.inventory.discard(effect[1:])


def conditions_met(state: GameState, conditions: list[str]) -> bool:
    return all(item in state.inventory for item in conditions)


def show_state(state: GameState) -> None:
    inventory = ", ".join(sorted(state.inventory)) or "(vacío)"
    print(f"Inventario: {inventory}")
    print(f"XP: {state.xp}")


def show_section(adventure: Adventure, state: GameState) -> None:
    section = adventure.sections[state.section]

    print("\n" + "=" * 60)
    print(f"[{section.name}]")

    if section.text:
        print("\n".join(section.text))

    print()
    show_state(state)

    # Saltos automáticos que cumplen sus condiciones.
    for jump in section.conditions:
        if conditions_met(state, jump.conditions):
            print(
                f"\n[Condición cumplida] "
                f"{' + '.join(jump.conditions)} -> {jump.target}"
            )

    if section.options:
        print("\nOpciones:")
        for option in section.options:
            effects = ""
            if option.effects:
                effects = f" [{', '.join(option.effects)}]"
            print(
                f"  {option.number}. {option.text}"
                f" -> {option.target}{effects}"
            )


def run(adventure: Adventure) -> None:
    if "INICIO" not in adventure.sections:
        raise RuntimeError("La aventura debe tener una sección INICIO.")

    state = GameState()

    while True:
        if state.section == "ACABA":
            show_section(adventure, state)
            print("\n*** FIN DE LA AVENTURA ***")
            break

        show_section(adventure, state)
        section = adventure.sections[state.section]

        # Las condiciones tienen prioridad: si se cumplen, se salta
        # automáticamente a la primera condición válida.
        jump = next(
            (
                jump
                for jump in section.conditions
                if conditions_met(state, jump.conditions)
            ),
            None,
        )

        if jump:
            input("\nPulsa ENTER para continuar...")
            state.section = jump.target
            continue

        if not section.options:
            print("\nNo hay más acciones disponibles.")
            break

        choice = input("\nElige una opción: ").strip()

        if not choice.isdigit():
            print("Introduce un número.")
            continue

        number = int(choice)
        option = next(
            (option for option in section.options if option.number == number),
            None,
        )

        if option is None:
            print("Opción no válida.")
            continue

        apply_effects(state, option.effects)
        state.section = option.target


def test_parser(filename: str) -> None:
    print("=== TEST DEL PARSER ===")

    adventure = parse_file(filename)

    print(f"Secciones encontradas: {len(adventure.sections)}")

    for name, section in adventure.sections.items():
        print(f"\n[{name}]")
        print(f"  Texto: {len(section.text)} línea(s)")
        print(f"  Condiciones: {len(section.conditions)}")
        print(f"  Opciones: {len(section.options)}")

        for condition in section.conditions:
            print(
                f"    ?{condition.conditions} -> {condition.target}"
            )

        for option in section.options:
            print(
                f"    {option.number}. {option.text}"
                f" -> {option.target}"
                f" {option.effects}"
            )

    print("\nParser OK.")


if __name__ == "__main__":
    adventure_file = Path(__file__).with_name("aventura.txt")

    try:
        test_parser(str(adventure_file))
        print("\n")
        run(parse_file(str(adventure_file)))
    except Exception as error:
        print(f"\nERROR: {error}")
        raise
