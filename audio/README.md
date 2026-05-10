# Audio assets

Drop `.ogg` Vorbis files here with these exact names. The system loads them
lazily — missing files are silently skipped (no errors), so you can ship
partial sets while iterating.

| Filename | Used for |
|---|---|
| `click.ogg` | Click del reactor (atenuado -8 dB en código) |
| `upgrade.ogg` | Compra de upgrade / legacy / cosmic |
| `achievement.ogg` | Logro desbloqueado |
| `transcend.ogg` | Trascendencia confirmada |
| `run_close.ogg` | Cierre de run (cualquier ruta final) |
| `mutation.ogg` | Mutación adoptada |
| `ambient_loop.ogg` | Música de fondo (loop forzado en código) |

Recomendaciones:
- Format: OGG Vorbis (compat web, sin licensing issues).
- SFX cortos (<1 s) para click/upgrade; el resto puede ser un poco más largo.
- Música: 30–120 s, normalizada bajo (~-18 dBFS). El bus aplica volumen del usuario encima.
- CC0 sources: Kenney UI Audio Pack, OpenGameArt, Freesound (filtrar CC0).
