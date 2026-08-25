def parse(text):
    dialogue = {}
    section = "START"

    dialogue[section] = {
        "text": [],
        "conditions": [],
        "choices": []
    }

    for line in text.splitlines():
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        # [SECCION]
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip()

            dialogue[section] = {
                "text": [],
                "conditions": [],
                "choices": []
            }
            continue

        # 1:Texto ->SECCION, acciones
        if len(line) >= 2 and line[0].isdigit() and line[1] == ":":
            left, right = line.split("->", 1)

            number, text = left.split(":", 1)

            parts = [x.strip() for x in right.split(",")]

            dialogue[section]["choices"].append({
                "id": int(number),
                "text": text.strip(),
                "target": parts[0],
                "actions": parts[1:]
            })
            continue

        # objeto: ->SECCION
        if ":" in line and "->" in line:
            item, target = line.split("->", 1)

            dialogue[section]["conditions"].append({
                "item": item.replace(":", "").strip(),
                "target": target.strip()
            })
            continue

        # Texto del PNJ
        dialogue[section]["text"].append(line)

    return dialogue
