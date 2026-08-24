import json
import sys

from dialogue_parser import DialogueParser


STATE_FILE = "player_state.json"


class DialogueGame:

    def __init__(self, nodes):

        self.nodes = nodes
        self.current_node = "START"

        # Estado del jugador
        self.xp = 0
        self.inventory = set()

    # ========================================================
    # CARGAR ESTADO DEL JUGADOR
    # ========================================================

    def load_player_state(self, filename=STATE_FILE):

        try:

            with open(
                filename,
                "r",
                encoding="utf-8"
            ) as file:

                state = json.load(file)

            self.xp = int(
                state.get("xp", 0)
            )

            self.inventory = set(
                state.get("inventory", [])
            )

            print()
            print(
                f"[Estado cargado: {filename}]"
            )

        except FileNotFoundError:

            print()
            print(
                "[No existe estado guardado. "
                "Se inicia jugador nuevo.]"
            )

        except (
            json.JSONDecodeError,
            ValueError,
            TypeError
        ):

            print()
            print(
                "[ERROR: estado no válido. "
                "Se inicia jugador nuevo.]"
            )

            self.xp = 0
            self.inventory = set()

    # ========================================================
    # GUARDAR ESTADO DEL JUGADOR
    # ========================================================

    def save_player_state(self, filename=STATE_FILE):

        state = {
            "xp": self.xp,
            "inventory": sorted(
                self.inventory
            )
        }

        try:

            with open(
                filename,
                "w",
                encoding="utf-8"
            ) as file:

                json.dump(
                    state,
                    file,
                    ensure_ascii=False,
                    indent=4
                )

            print()
            print(
                f"[Estado guardado: {filename}]"
            )

        except OSError as error:

            print()
            print(
                "[ERROR al guardar el estado]"
            )

            print(error)

    # ========================================================
    # EJECUTAR UN EFECTO
    # ========================================================
    #
    # Devuelve True si el estado del jugador ha cambiado.
    #

    def execute_effect(self, effect):

        changed = False

        # ----------------------------------------------------
        # XP+
        # ----------------------------------------------------

        if effect.startswith("xp+"):

            amount = int(
                effect[3:]
            )

            self.xp += amount

            changed = True

            print()
            print(
                f"[XP +{amount}]"
            )

            print(
                f"[XP actual: {self.xp}]"
            )

        # ----------------------------------------------------
        # XP-
        # ----------------------------------------------------

        elif effect.startswith("xp-"):

            amount = int(
                effect[3:]
            )

            old_xp = self.xp

            self.xp = max(
                0,
                self.xp - amount
            )

            changed = (
                self.xp != old_xp
            )

            print()
            print(
                f"[XP -{amount}]"
            )

            print(
                f"[XP actual: {self.xp}]"
            )

        # ----------------------------------------------------
        # AÑADIR OBJETO
        # ----------------------------------------------------

        elif effect.startswith("+"):

            item = effect[1:]

            if item not in self.inventory:

                self.inventory.add(item)

                changed = True

                print()
                print(
                    f"[Objeto obtenido: {item}]"
                )

            else:

                print()
                print(
                    f"[Ya tienes: {item}]"
                )

        # ----------------------------------------------------
        # ELIMINAR OBJETO
        # ----------------------------------------------------

        elif effect.startswith("-"):

            item = effect[1:]

            if item in self.inventory:

                self.inventory.remove(item)

                changed = True

                print()
                print(
                    f"[Objeto eliminado: {item}]"
                )

            else:

                print()
                print(
                    f"[No tienes: {item}]"
                )

        return changed

    # ========================================================
    # EJECUTAR TODOS LOS EFECTOS
    # ========================================================

    def execute_effects(self, effects):

        changed = False

        for effect in effects:

            effect_changed = (
                self.execute_effect(effect)
            )

            if effect_changed:

                changed = True

        # ----------------------------------------------------
        # GUARDADO INMEDIATO
        # ----------------------------------------------------

        if changed:

            self.save_player_state()

    # ========================================================
    # MOSTRAR ESTADO
    # ========================================================

    def show_status(self):

        print()
        print("-" * 60)

        print(
            f"XP: {self.xp}"
        )

        if self.inventory:

            print(
                "Inventario: "
                + ", ".join(
                    sorted(self.inventory)
                )
            )

        else:

            print(
                "Inventario: vacío"
            )

        print("-" * 60)

    # ========================================================
    # PROCESAR CONDICIÓN
    # ========================================================

    def process_condition(self, node):

        condition = node.condition

        item = condition.object_name

        has_item = (
            item in self.inventory
        )

        # ----------------------------------------------------
        # SI TIENE EL OBJETO
        # ----------------------------------------------------

        if has_item:

            print()
            print(
                f"[CONDICIÓN] "
                f"Tienes '{item}'"
            )

            if condition.if_yes:

                print(
                    f"[SI -> "
                    f"{condition.if_yes}]"
                )

                self.current_node = (
                    condition.if_yes
                )

                return True

            return False

        # ----------------------------------------------------
        # NO TIENE EL OBJETO
        # ----------------------------------------------------

        print()
        print(
            f"[CONDICIÓN] "
            f"No tienes '{item}'"
        )

        if condition.if_no:

            print(
                f"[NO -> "
                f"{condition.if_no}]"
            )

            self.current_node = (
                condition.if_no
            )

            return True

        return False

    # ========================================================
    # MOSTRAR NODO
    # ========================================================

    def show_node(self, node):

        print()
        print("=" * 60)
        print(
            f"[{node.name}]"
        )
        print("=" * 60)

        for line in node.lines:

            print(line)

    # ========================================================
    # ELEGIR OPCIÓN
    # ========================================================

    def choose_option(self, node):

        # ----------------------------------------------------
        # NODO SIN OPCIONES
        # ----------------------------------------------------
        #
        # Un nodo sin opciones termina la conversación.
        #

        if not node.options:

            input(
                "\nPulsa ENTER para "
                "terminar la conversación..."
            )

            return "END"

        # ----------------------------------------------------
        # MOSTRAR OPCIONES
        # ----------------------------------------------------

        print()

        for option in node.options:

            print(
                f"{option.number}. "
                f"{option.text}"
            )

        # ----------------------------------------------------
        # ESPERAR ELECCIÓN
        # ----------------------------------------------------

        while True:

            answer = input(
                "\n> "
            ).strip()

            try:

                number = int(answer)

            except ValueError:

                print(
                    "Introduce el número "
                    "de una opción."
                )

                continue

            for option in node.options:

                if option.number == number:

                    return option

            print(
                "Opción no válida."
            )

    # ========================================================
    # EJECUTAR CONVERSACIÓN
    # ========================================================

    def play(self):

        while True:

            # ------------------------------------------------
            # FIN DE LA CONVERSACIÓN
            # ------------------------------------------------

            if self.current_node == "END":

                print()
                print("=" * 60)
                print(
                    "CONVERSACIÓN TERMINADA"
                )
                print("=" * 60)

                self.show_status()

                break

            # ------------------------------------------------
            # COMPROBAR QUE EL NODO EXISTE
            # ------------------------------------------------

            if self.current_node not in self.nodes:

                print()
                print(
                    "ERROR: nodo inexistente:"
                )

                print(
                    self.current_node
                )

                break

            node = self.nodes[
                self.current_node
            ]

            # ------------------------------------------------
            # CONDICIÓN AUTOMÁTICA
            # ------------------------------------------------

            if node.condition:

                changed = (
                    self.process_condition(
                        node
                    )
                )

                if changed:

                    continue

            # ------------------------------------------------
            # MOSTRAR TEXTO
            # ------------------------------------------------

            self.show_node(node)

            # ------------------------------------------------
            # ELEGIR OPCIÓN
            # ------------------------------------------------

            selected = (
                self.choose_option(node)
            )

            # ------------------------------------------------
            # NODO TERMINAL
            # ------------------------------------------------

            if selected == "END":

                self.current_node = "END"

                continue

            # ------------------------------------------------
            # EFECTOS
            # ------------------------------------------------

            if selected.effects:

                self.execute_effects(
                    selected.effects
                )

            # ------------------------------------------------
            # SIGUIENTE NODO
            # ------------------------------------------------

            self.current_node = (
                selected.target
            )


# ============================================================
# PROGRAMA PRINCIPAL
# ============================================================

def main():

    # --------------------------------------------------------
    # COMPROBAR PARÁMETRO
    # --------------------------------------------------------

    if len(sys.argv) != 2:

        print()
        print("Uso:")
        print(
            "python dialogue_game.py <guion.txt>"
        )

        print()
        print("Ejemplo:")
        print(
            "python dialogue_game.py "
            "pueblo_anciano_a1.txt"
        )

        return

    # --------------------------------------------------------
    # NOMBRE DEL GUIÓN
    # --------------------------------------------------------

    filename = sys.argv[1]

    print()
    print("=" * 60)
    print(
        "PRUEBA DEL SISTEMA DE DIÁLOGOS"
    )
    print("=" * 60)

    print()
    print(
        f"Guion: {filename}"
    )

    # --------------------------------------------------------
    # PARSER
    # --------------------------------------------------------

    parser = DialogueParser()

    nodes = parser.parse_file(
        filename
    )

    # --------------------------------------------------------
    # COMPROBAR ERRORES
    # --------------------------------------------------------

    if parser.errors:

        print()
        print(
            "ERRORES EN EL GUIÓN:"
        )

        print()

        for error in parser.errors:

            print(
                "-",
                error
            )

        return

    print()
    print(
        "GUIÓN CORRECTO"
    )

    # --------------------------------------------------------
    # CREAR JUEGO
    # --------------------------------------------------------

    game = DialogueGame(
        nodes
    )

    # --------------------------------------------------------
    # CARGAR ESTADO
    # --------------------------------------------------------

    game.load_player_state()

    game.show_status()

    # --------------------------------------------------------
    # JUGAR
    # --------------------------------------------------------

    print()
    print(
        "Iniciando conversación..."
    )

    game.play()

    # --------------------------------------------------------
    # NO GUARDAMOS AQUÍ
    # --------------------------------------------------------
    #
    # El estado ya se ha guardado en tiempo real
    # cada vez que ha cambiado.
    #

    print()
    print(
        "Programa terminado."
    )


# ============================================================
# EJECUTAR
# ============================================================

if __name__ == "__main__":

    main()
