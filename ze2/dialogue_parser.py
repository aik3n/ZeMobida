import re
import sys
from dataclasses import dataclass, field


# ============================================================
# ESTRUCTURAS DE DATOS
# ============================================================

@dataclass
class Option:
    number: int
    text: str
    target: str
    effects: list[str] = field(default_factory=list)


@dataclass
class Condition:
    object_name: str
    if_yes: str | None = None
    if_no: str | None = None


@dataclass
class Node:
    name: str
    lines: list[str] = field(default_factory=list)
    options: list[Option] = field(default_factory=list)
    condition: Condition | None = None


# ============================================================
# PARSER
# ============================================================

class DialogueParser:

    OPTION_RE = re.compile(
        r"^(\d+)\.\s+(.+?)\s*->\s*(END|[a-z0-9_]+)"
        r"(?:\s*\|\s*(.+))?$"
    )

    CONDITION_RE = re.compile(
        r"^\?([a-z0-9_]+)"
        r"(?:\s*\|\s*SI->([a-z0-9_]+))?"
        r"(?:\s*\|\s*NO->([a-z0-9_]+))?$"
    )

    NODE_RE = re.compile(
        r"^\[(START|END|[a-z0-9_]+)\]$"
    )

    EFFECT_RE = re.compile(
        r"^(xp[+-]\d+|[+-][a-z0-9_]+)$"
    )

    def __init__(self):
        self.nodes = {}
        self.errors = []

    # ========================================================
    # CARGAR ARCHIVO
    # ========================================================

    def parse_file(self, filename):

        self.nodes = {}
        self.errors = []

        current_node = None

        try:

            with open(
                filename,
                "r",
                encoding="utf-8"
            ) as file:

                lines = file.readlines()

        except FileNotFoundError:

            self.errors.append(
                f"No existe el archivo: {filename}"
            )

            return None

        # ----------------------------------------------------
        # LEER LÍNEAS
        # ----------------------------------------------------

        for line_number, raw_line in enumerate(
            lines,
            start=1
        ):

            line = raw_line.strip()

            if not line:
                continue

            if line.startswith("#"):
                continue

            # ------------------------------------------------
            # NUEVO NODO
            # ------------------------------------------------

            node_match = self.NODE_RE.match(line)

            if node_match:

                node_name = node_match.group(1)

                if node_name in self.nodes:

                    self.errors.append(
                        f"Línea {line_number}: "
                        f"nodo duplicado [{node_name}]"
                    )

                current_node = Node(node_name)

                self.nodes[node_name] = current_node

                continue

            # ------------------------------------------------
            # FUERA DE UN NODO
            # ------------------------------------------------

            if current_node is None:

                self.errors.append(
                    f"Línea {line_number}: "
                    f"contenido fuera de un nodo"
                )

                continue

            # ------------------------------------------------
            # END NO DEBE TENER CONTENIDO
            # ------------------------------------------------

            if current_node.name == "END":

                self.errors.append(
                    f"Línea {line_number}: "
                    f"no puede haber contenido dentro de [END]"
                )

                continue

            # ------------------------------------------------
            # CONDICIÓN
            # ------------------------------------------------

            if line.startswith("?"):

                condition = self.parse_condition(
                    line,
                    line_number
                )

                if condition:

                    if current_node.condition is not None:

                        self.errors.append(
                            f"Línea {line_number}: "
                            f"el nodo "
                            f"[{current_node.name}] "
                            f"ya tiene una condición"
                        )

                    current_node.condition = condition

                continue

            # ------------------------------------------------
            # OPCIÓN
            # ------------------------------------------------

            if re.match(r"^\d+\.", line):

                option = self.parse_option(
                    line,
                    line_number
                )

                if option:

                    current_node.options.append(
                        option
                    )

                continue

            # ------------------------------------------------
            # TEXTO
            # ------------------------------------------------

            current_node.lines.append(line)

        self.validate()

        if self.errors:
            return None

        return self.nodes

    # ========================================================
    # PARSEAR OPCIÓN
    # ========================================================

    def parse_option(self, line, line_number):

        match = self.OPTION_RE.match(line)

        if not match:

            self.errors.append(
                f"Línea {line_number}: "
                f"opción incorrecta: {line}"
            )

            return None

        number = int(match.group(1))
        text = match.group(2).strip()
        target = match.group(3)
        effects_text = match.group(4)

        effects = []

        if effects_text:

            for effect in effects_text.split(","):

                effect = effect.strip()

                if not self.EFFECT_RE.match(effect):

                    self.errors.append(
                        f"Línea {line_number}: "
                        f"efecto incorrecto: "
                        f"{effect}"
                    )

                else:

                    effects.append(effect)

        return Option(
            number=number,
            text=text,
            target=target,
            effects=effects
        )

    # ========================================================
    # PARSEAR CONDICIÓN
    # ========================================================

    def parse_condition(self, line, line_number):

        match = self.CONDITION_RE.match(line)

        if not match:

            self.errors.append(
                f"Línea {line_number}: "
                f"condición incorrecta: {line}"
            )

            return None

        object_name = match.group(1)
        if_yes = match.group(2)
        if_no = match.group(3)

        if if_yes is None and if_no is None:

            self.errors.append(
                f"Línea {line_number}: "
                f"la condición debe tener "
                f"SI, NO o ambas ramas"
            )

            return None

        return Condition(
            object_name=object_name,
            if_yes=if_yes,
            if_no=if_no
        )

    # ========================================================
    # VALIDACIÓN
    # ========================================================

    def validate(self):

        if "START" not in self.nodes:

            self.errors.append(
                "Falta el nodo [START]"
            )

        if "END" not in self.nodes:

            self.errors.append(
                "Falta el nodo [END]"
            )

        for node in self.nodes.values():

            # -----------------------------------------------
            # DESTINOS DE OPCIONES
            # -----------------------------------------------

            for option in node.options:

                if option.target not in self.nodes:

                    self.errors.append(
                        f"El nodo [{node.name}] "
                        f"apunta a un nodo inexistente: "
                        f"[{option.target}]"
                    )

            # -----------------------------------------------
            # DESTINOS DE CONDICIONES
            # -----------------------------------------------

            if node.condition:

                condition = node.condition

                if condition.if_yes:

                    if condition.if_yes not in self.nodes:

                        self.errors.append(
                            f"El nodo [{node.name}] "
                            f"apunta a un nodo inexistente: "
                            f"[{condition.if_yes}]"
                        )

                if condition.if_no:

                    if condition.if_no not in self.nodes:

                        self.errors.append(
                            f"El nodo [{node.name}] "
                            f"apunta a un nodo inexistente: "
                            f"[{condition.if_no}]"
                        )


# ============================================================
# MOSTRAR GUIÓN
# ============================================================

def print_dialogue(nodes):

    for node in nodes.values():

        print()
        print("=" * 60)
        print(f"[{node.name}]")
        print("=" * 60)

        if node.condition:

            condition = node.condition

            print(
                f"CONDICIÓN: ?{condition.object_name}"
            )

            print(
                f"  SI -> {condition.if_yes or '-'}"
            )

            print(
                f"  NO -> {condition.if_no or '-'}"
            )

        for line in node.lines:

            print(f"TEXTO: {line}")

        for option in node.options:

            print(
                f"OPCIÓN {option.number}: "
                f"{option.text}"
            )

            print(
                f"  -> {option.target}"
            )

            if option.effects:

                print(
                    f"  EFECTOS: "
                    f"{', '.join(option.effects)}"
                )


# ============================================================
# PROGRAMA PRINCIPAL
# ============================================================

def main():

    if len(sys.argv) != 2:

        print()
        print("Uso:")
        print("python dialogue_parser.py <guion.txt>")
        print()
        print("Ejemplo:")
        print(
            "python dialogue_parser.py "
            "pueblo_anciano_a1.txt"
        )

        return

    filename = sys.argv[1]

    print()
    print("=" * 60)
    print("PARSER DE DIÁLOGOS")
    print("=" * 60)

    print()
    print(f"Analizando: {filename}")

    parser = DialogueParser()

    nodes = parser.parse_file(filename)

    if parser.errors:

        print()
        print("ERRORES EN EL GUIÓN:")
        print()

        for error in parser.errors:

            print("-", error)

        return

    print()
    print("GUIÓN CORRECTO")

    print_dialogue(nodes)


if __name__ == "__main__":
    main()
