from parser import parse
from manager import DialogueManager


with open(
    "dialogo.txt",
    "r",
    encoding="utf-8"
) as file:

    text = file.read()


dialogue = parse(text)

manager = DialogueManager(dialogue)

# Para probar una condición
manager.inventory.add("lintern")

manager.start()
