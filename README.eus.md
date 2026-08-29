# ZeMobida

> Abentura eta erabakietan oinarritutako jokoa, non elkarrizketek ondorioak dituzten.

**Egoera:** prototipoa / garapen aktiboa  
**Motorra:** Godot 4.7  
**Renderizatzea:** GL Compatibility  
**Lizentzia:** GNU GPLv3  
**Ikuskatutako berrikuspena:** `12ea5386c03d53dd51dae26fd172775e281544f8`

ZeMobida Godotekin garatutako kode irekiko bideo-jokoa da. Esplorazioa, PNJak, elkarrizketa adarkatuak, inbentarioa, XP eta jokalariaren erabakiak dira oinarriak.

Beharrezkoa da Godot **4.7**. Proiektu nagusia `res://escenas/Game.tscn` da.

Dokumentazio nagusia:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/DECISIONS.md`](docs/DECISIONS.md)
- [`docs/DIALOGUE_FORMAT.md`](docs/DIALOGUE_FORMAT.md)
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)
- [`docs/AUDIT.md`](docs/AUDIT.md)

Hasierako ikuskapeneko hainbat puntu dagoeneko konpondu dira: elkarrizketen sinkronizazio inkrementala, aldi baterako multzoaren balidazioa, cache-rako fallback-a, persistentzia bateratua, mapa-hautaketa dinamikoa eta gidoiak `aik3n/ZeMobida_guiones` biltegi bereizian mantentzea. Release baten aurretik berrikusteko geratzen dira `main` erreferentzia mutagarria, elkarrizketa-ziklo automatikoen detekzioa, banaketa-metadata eta test/CI automatizatuak.

GNU GPL v3.0.
