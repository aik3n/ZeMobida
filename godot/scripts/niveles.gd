extends RefCounted


const NIVELES := [
	{"nivel": "a1", "xp": 70},
	{"nivel": "a2", "xp": 120},
	{"nivel": "b1", "xp": 340},
	{"nivel": "b2", "xp": 410},
	{"nivel": "c1", "xp": 740},
	{"nivel": "c2", "xp": 2000}
]


static func nivel_inicial() -> String:
	if NIVELES.is_empty():
		return ""

	return str(
		NIVELES[0]["nivel"]
	)


static func nivel_para_xp(xp: int) -> String:
	if NIVELES.is_empty():
		return ""

	for entrada in NIVELES:
		if xp <= int(entrada["xp"]):
			return str(entrada["nivel"])

	return str(
		NIVELES[-1]["nivel"]
	)


static func tiene_nivel(nivel: String) -> bool:
	return indice_nivel(nivel) != -1


static func indice_nivel(nivel: String) -> int:
	var nivel_buscado := nivel.to_lower()

	for indice in range(NIVELES.size()):
		if str(NIVELES[indice]["nivel"]).to_lower() == nivel_buscado:
			return indice

	return -1


static func xp_limite_inferior(nivel: String) -> int:
	var indice := indice_nivel(nivel)

	if indice == -1:
		return 0

	if indice == 0:
		return 0

	return int(
		NIVELES[indice - 1]["xp"]
	) + 1


static func xp_limite_superior(nivel: String) -> int:
	var indice := indice_nivel(nivel)

	if indice == -1:
		return 0

	return int(
		NIVELES[indice]["xp"]
	)


static func xp_maximo() -> int:
	if NIVELES.is_empty():
		return 0

	return int(
		NIVELES[-1]["xp"]
	)
