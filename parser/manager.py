class DialogueManager:

    def __init__(self, dialogue):
        self.dialogue = dialogue
        self.section = "START"

        self.inventory = set()
        self.xp = 0

    def start(self):
        self.section = "START"
        self.run()

    def run(self):

        while True:

            data = self.dialogue[self.section]

            # -------------------------
            # Condiciones
            # -------------------------

            jumped = False

            for condition in data["conditions"]:

                if condition["item"] in self.inventory:
                    self.section = condition["target"]
                    jumped = True
                    break

            if jumped:
                continue

            # -------------------------
            # Texto del PNJ
            # -------------------------

            for text in data["text"]:
                print()
                print("PNJ:", text)

            # -------------------------
            # Fin
            # -------------------------

            if not data["choices"]:
                print()
                print("Conversación terminada.")
                return

            # -------------------------
            # Opciones
            # -------------------------

            print()

            for choice in data["choices"]:
                print(
                    f"{choice['id']}. "
                    f"{choice['text']}"
                )

            # -------------------------
            # Elección
            # -------------------------

            try:
                number = int(input("> "))
            except ValueError:
                print("Opción inválida.")
                continue

            choice = self.get_choice(
                data["choices"],
                number
            )

            if choice is None:
                print("Opción inválida.")
                continue

            # -------------------------
            # Acciones
            # -------------------------

            self.execute_actions(
                choice["actions"]
            )

            # -------------------------
            # Salto
            # -------------------------

            self.section = choice["target"]

    def get_choice(self, choices, number):

        for choice in choices:

            if choice["id"] == number:
                return choice

        return None

    def execute_actions(self, actions):

        for action in actions:

            # XP
            if action.startswith("xp+"):

                amount = int(action[3:])

                self.xp += amount

                print(
                    f"[XP +{amount}]"
                )

            # Añadir objeto
            elif action.startswith("+"):

                item = action[1:]

                self.inventory.add(item)

                print(
                    f"[Objeto obtenido: {item}]"
                )

            # Quitar objeto
            elif action.startswith("-"):

                item = action[1:]

                self.inventory.discard(item)

                print(
                    f"[Objeto perdido: {item}]"
                )
