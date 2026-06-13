{
    "name": "POSIPV Sync API",
    "version": "18.0.1.0.0",
    "category": "Operations",
    "summary": "Capa HTTP server-wide para la sincronización POSIPV",
    "description": """
POSIPV Sync API
===============

Addon liviano para publicar las rutas HTTP de POSIPV a nivel servidor.
Delega la lógica al servicio `posipv.sync.service` definido por el addon
principal `posipv`.
    """,
    "author": "OpenAI / Codex",
    "license": "LGPL-3",
    "installable": True,
    "application": False,
    "depends": ["base"],
    "data": [],
}
