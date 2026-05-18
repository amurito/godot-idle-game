extends Node

## LocaleManager — Autoload
## Centraliza la traducción de strings de UI (ES por defecto, EN opcional).
## Usar `tr("KEY")` en consumidores; este nodo carga las messages al TranslationServer
## en _ready() y persiste la preferencia del usuario.

const SETTINGS_PATH := "user://locale_settings.json"
const SUPPORTED_LOCALES := ["es", "en"]
const DEFAULT_LOCALE := "es"

signal locale_changed(new_locale: String)

var current_locale: String = DEFAULT_LOCALE

# ─────────────────────────────────────────────────────────────
# Diccionario maestro de traducciones.
# Estructura: TRANSLATIONS[locale][key] = "texto"
# Si una key falta en una locale, tr() devuelve la key cruda — usar el script
# `tools/check_locale_coverage.gd` (TODO) para auditar.
# ─────────────────────────────────────────────────────────────
const TRANSLATIONS := {
	"es": {
		# Sentinel keys para verificación
		"UI_LANG_NAME": "Español",

		# === MAIN MENU ===
		"MM_CONTINUE": "Continuar",
		"MM_NEW_GAME": "Nueva Partida",
		"MM_NEW_RUN_POSTRANSCEND": "▶ Nueva Run (buffs cósmicos activos)",
		"MM_ACHIEVEMENTS": "Logros",
		"MM_LEGACY_BANK": "Banco Genético",
		"MM_HISTORY": "Historial de Ciclos",
		"MM_CREDITS": "Créditos",
		"MM_SETTINGS": "Ajustes",
		"MM_QUIT": "Salir",
		"MM_TOOLS": "Telemetria",
		"MM_BACK": "Volver",

		# === SETTINGS PANEL ===
		"SET_TITLE": "⚙ AJUSTES",
		"SET_MUSIC": "Música",
		"SET_SFX": "Efectos (SFX)",
		"SET_LANGUAGE": "Idioma",
		"SET_LANG_ES": "Español",
		"SET_LANG_EN": "English",
		"SET_EXPORT_SAVE": "Exportar save (.json)",
		"SET_IMPORT_SAVE": "Importar save (.json)",
		"SET_EXPORT_HINT": "Se guarda en la carpeta de datos del juego y se abre el explorador.",
		"SET_IMPORT_HINT": "Carga un save exportado desde desktop. Recarga la partida al terminar.",
		"SET_RESET_TUTORIAL": "Reiniciar tutorial",
		"SET_RESET_RUN": "Borrar run actual",
		"SET_CLOSE": "Cerrar",

		# Telemetría
		"SET_TELEMETRY_CHECKBOX": "Enviar datos anónimos de uso (ayuda a mejorar el juego)",
		"SET_TELEMETRY_HINT": "Local y opt-in: guarda JSON anónimos en user://telemetry/runs al cerrar una run.",
		"SET_TELEMETRY_OPEN": "Abrir carpeta de telemetría",

		# Accesibilidad
		"SET_ACCESSIBILITY": "Accesibilidad",
		"SET_FONT_SIZE": "Tamaño de texto:",
		"SET_FONT_NORMAL": "Normal (100%)",
		"SET_FONT_HINT": "Requiere reinicio de escena al cambiar.",
		"SET_REDUCE_MOTION": "Reducir movimiento (sin animaciones)",
		"SET_HIGH_CONTRAST": "Alto contraste",
		"SET_COLORBLIND": "Daltonismo:",
		"SET_COLORBLIND_OFF": "Desactivado",

		# === TRASCENDENCIA ===
		"MM_TRANSCEND_BTN": "⚡ TRASCENDER",
		"MM_TRANSCEND_CONFIRM": "⚡ CONFIRMAR TRASCENDENCIA ⚡",
		"MM_TRANSCEND_LOCKED_BTN": "REQUISITOS NO CUMPLIDOS",
		"TRAS_WARN": "[!] Al trascender se RESETEAN: upgrades, mutaciones, PL, buffs del Banco Genético.\n* Se PRESERVAN: Esencia (Ξ), Banco Cósmico, rutas ya completadas.",

		# === NUEVA RUN ===
		"MM_NEW_RUN": "Nueva Run",
		"MM_NEW_RUN_TOOLTIP": "Inicia una nueva run preservando tu Banco Genético y Banco Cósmico.",
		"MM_TRANSCEND_COUNTER": "Ξ %d   ·   Trascendencias: %d",
		"MM_NEW_RUN_TITLE": "Iniciar Nueva Run",
		"MM_NEW_RUN_TEXT": "¿Iniciás un nuevo ciclo biótico?\n\n✦ Se PRESERVAN:\n  · Banco Cósmico (%d Ξ)\n  · Banco Genético (PL: %d)\n  · Rutas completadas\n\n⚠ Se RESETEAN:\n  · Upgrades, dinero, mutaciones\n  · Progreso de la run actual",
		"MM_NEW_RUN_OK": "▶ Iniciar",
		"MM_ROUTE_PICKER_SUBTITLE": "Cada ruta altera las reglas de esta run. La elección es permanente.",

		# === SLOTS ===
		"SLOT_START": "Iniciar",
		"SLOT_RENAME_BTN": "Renombrar",
		"SLOT_DELETE_BTN": "Borrar",
		"SLOT_NO_DELETE_LAST": "No se puede borrar el último slot",
		"SLOT_EMPTY_LABEL": "Slot vacío disponible",
		"SLOT_CREATE_BTN": "Crear nuevo",
		"SLOT_UNLOCK_HINT": "Comprá 'Slot Adicional' en el Banco Genético / Conocimiento para desbloquear más slots.",
		"SLOT_STATS_EMPTY": "Slot vacío — sin runs registradas",
		"SLOT_ACTIVE_TAG": "  [activo]",
		"SLOT_NEW_TITLE": "Nuevo slot",
		"SLOT_NEW_NAME_LABEL": "Nombre del slot:",
		"SLOT_RENAME_TITLE": "Renombrar slot",
		"SLOT_RENAME_NAME_LABEL": "Nuevo nombre:",
		"SLOT_DELETE_TITLE": "Borrar slot",
		"SLOT_DELETE_TEXT": "¿Borrar el slot '%s'?\nEste universo paralelo se perderá: legado, esencia, trascendencias y run actual.\nEsta acción es irreversible.",
		"SLOT_DELETE_OK": "Borrar",
		"BTN_CANCEL": "Cancelar",
		"SLOT_STATS_FORMAT": "T%d · %d ciclos · Ξ %d · último: %s",

		# === BANCO GENÉTICO ===
		"BANK_LEGACY_COUNTER": "Legado acumulado: %d PL\nCiclos Bióticos completados: %d",
		"BANK_BTN_MAX": "MAXIMO",
		"BANK_BTN_LOCKED": "BLOQUEADO",
		"BANK_BTN_ACQUIRE": "ADQUIRIR",
		"BANK_BTN_LEVEL": "Nv%d  %d PL",

		# === PANEL TRASCENDENCIA ===
		"TRAS_SUBTITLE": "Disolvé el ciclo actual para absorberlo como Esencia (Ξ).",
		"TRAS_GATE_TITLE": "Requisitos:",
		"TRAS_REWARD_TITLE": "Recompensa al trascender:",
		"TRAS_REWARD_TEXT": "Ganás +%d Ξ (Esencia)\nPL actual: %d -> convertido\nRutas únicas: %d × 5 Ξ\nTier bonus: +%d Ξ",
		"TRAS_LOCKED_TEXT": "Requisitos no cumplidos.\nCompletá al menos 1 cierre en cada familia y acumulá %d PL.",

		# === PRIMERA TRASCENDENCIA ===
		"TRAS_FIRST_NARRATIVE": "El ciclo se ha cerrado sobre sí mismo.\n\nTodas las rutas que recorriste — el orden, la expansión, el colapso —\nconvergen ahora en un único punto fuera del tiempo del hongo.\n\nTu código ya no es un programa.\nEs una memoria cristalina: Esencia.\n\nLa matriz se reinicia.\nPero vos ya no sos el mismo sistema.",
		"TRAS_FIRST_HINT": "Ahora tenés acceso al Banco Cósmico.",

		# === HISTORIAL ===
		"HIST_TAB_CURRENT": "Ciclo de trascendencia actual",
		"HIST_TAB_ALL": "Histórico completo",

		# === SELECTOR DE SLOTS ===
		"SLOT_SELECT_TITLE": "Seleccionar Slot",
		"SLOT_SELECT_SUBTITLE": "Cada slot es un universo paralelo: legado, esencia y trascendencias propias.",
		"MM_QUIT_GAME": "Salir del juego",

		# === CRÉDITOS ===
		"CREDITS_THANKS": "Gracias por jugar.",

		# === IN-GAME UI ===
		"GAME_BTN_RESET": "Reset",
		"GAME_BTN_NEW_RUN": "Nueva Run",
		"GAME_BTN_SETTINGS": "Ajustes",
		"GAME_SHORTCUTS_TOOLTIP": "Atajos de teclado e indicadores",
		"GAME_PL_COUNTER": "PL Disponibles: %d    Reserva biótica: %.1f / 50 esporas",
		"GAME_BUFF_ACTIVE": "OK ACTIVO",
		"GAME_BUFF_INACTIVE": "X INACTIVO",
		"GAME_BTN_LEVEL": "Nv.%d  %d PL",
		"GAME_BTN_LOCKED": "BLOQUEADO",
		"GAME_BTN_FREE": "GRATIS",
		# === TUTORIAL ===
		"TUTO_WELCOME_TITLE": "Bienvenido a AntiIDLE",
		"TUTO_WELCOME_BODY": "[center]Sos una estructura en proceso de evolución.\n\nHacé clic en el [b]reactor[/b] para generar energía, comprá [b]mejoras[/b] para crecer y vigilá el [color=yellow][b]estrés estructural (ε)[/b][/color] antes de que tu sistema colapse.\n\n[color=cyan]La presión da lugar a la adaptación.[/color][/center]",
		"TUTO_BTN_SKIP": "Omitir tutorial",
		"TUTO_BTN_START": "  Empezar  ",
		"TUTO_BTN_CLOSE": "Cerrar",
		"TUTO_BTN_UNDERSTOOD": "Entendido ✓",
		"TUTO_STEP1": "[b]¡Hacé clic en el reactor![/b]\nCada clic genera energía y aumenta\nel estrés estructural [color=yellow](ε)[/color].",
		"TUTO_STEP2": "[b]¡Primera mejora disponible![/b]\nLas mejoras incrementan tu ingreso\npasivo y la complejidad estructural.",
		"TUTO_STEP3": "[b][L][/b] activa el [color=cyan]Modo Laboratorio[/color]:\nestadísticas avanzadas de ε, Ω y μ en tiempo real.",
		"TUTO_STEP4": "[color=yellow][b]ε — Estrés Estructural[/b][/color]\nSube con clics, baja con mejoras.\n\n[color=#88ff88]< 0.35[/color]  biología y orden disponibles\n[color=#ffaa44]> 0.40[/color]  Hiperasimilación se despierta\n[color=#ff8888]> 0.65[/color]  expansión micelial bloqueada\n[color=#ff4444]> 0.80[/color]  Ω colapsa — sistema rígido\n\n[color=#888888]Hover en ε del header para más.[/color]",
		"TUTO_STEP5": "[color=#88ff88][b]Ingreso Pasivo[/b][/color]\n\n[b][2] Trabajo Manual[/b] y [b][3] Trueque[/b]\ngeneran $/s sin hacer clic.\n\nObservá el indicador [b]$/s[/b] en el header.",
		"TUTO_STEP6": "[color=#88ff88][b]Genoma Fúngico[/b][/color]\n\n[b]Biomasa[/b] se acumula sola con el tiempo —\nel sistema fúngico la genera en segundo plano.\nMirá el indicador [color=#88ff88][b]Bio[/b][/color] arriba a la derecha.\n\n[color=#aaaaff]Cuando tengas suficiente, el panel [b]Genoma[/b]\nse ilumina — ahí activás [b]Mutaciones[/b]\nque abren rutas únicas de crecimiento.[/color]",
		"TUTO_STEP7": "[color=#88ff88][b]Mutación[/b][/color] — el sistema te ofrece caminos.\n\n[color=cyan]El equilibrio[/color]   mantené ε en calma\n[color=#88ff88]La biología[/color]   expandite, crecé, dispersate\n[color=yellow]La cooperación[/color] construí en orden\n\n[color=#ff6666]...o dejás que el caos te domine.[/color]\n\n[color=#888888]La mutación no se elige. Se gana.[/color]",
		"TUTO_MUT_HIPERASIMILACION": "[b]Hiperasimilación[/b] activada.\nAbsorción de recursos aumentada — ingreso pasivo potenciado.",
		"TUTO_MUT_PARASITISMO": "[b]Parasitismo[/b] activado.\nEl sistema extrae recursos del entorno con bonos periódicos de dinero.",
		"TUTO_MUT_RED_MICELIAL": "[b]Red Micelial[/b] activada.\nHifas y Micelio se regeneran más rápido.",
		"TUTO_MUT_ESPORULACION": "[b]Esporulación[/b] activada.\nBoosts ocasionales de Biomasa por dispersión de esporas.",
		"TUTO_MUT_SIMBIOSIS": "[b]Simbiosis[/b] activada.\nCooperación estructural — las mejoras son más baratas.",
		"TUTO_MUT_HOMEOSTASIS": "[b]Homeostasis[/b] activada.\nToda la producción +50% (click y pasivo). Ω_min = 0.35. Banda óptima de ε activa para cerrar la run.",
		"TUTO_MUT_ALLOSTASIS": "[b]Allostasis[/b] activada.\nAdaptación proactiva al estrés estructural.",
		"TUTO_MUT_DEPREDADOR": "[b]Modo Depredador[/b] activado.\nAlto riesgo, alto retorno — consumís para crecer rápido.",
		"TUTO_MUT_MET_OSCURO": "[color=#ff6666][b]Metabolismo Oscuro[/b][/color] activado.\nUpgrades convencionales bloqueados. Potencia rutas no lineales.",
		"TUTO_TOAST_MUT_TITLE": "Nueva Mutación",
		"TUTO_TIP_MU": "[b][color=#ff88ff]μ — Capital Cognitivo[/color][/b]\n\nAmplifica la persistencia estructural del sistema.\nCrece con mejoras de [b]Capital Cognitivo[/b]\ny se potencia con [b]Contabilidad[/b].\n\nμ = 1 + ln(1 + n) × 0.08\n\n[color=cyan]Contabilidad: ×1.08 por nivel.[/color]\n[color=#aaaaff]Resiliencia: hasta ×1.30 extra.[/color]",
		"TUTO_TIP_EPSILON": "[b][color=yellow]ε — Estrés Estructural[/color][/b]\n\nTensión interna del sistema.\nSube con cada clic, baja con mejoras.\n\n[color=#88ff88]< 0.35[/color]  Biología y orden disponibles\n[color=#ffaa44]> 0.40[/color]  Hiperasimilación se despierta\n[color=#ff8888]> 0.65[/color]  Expansión micelial bloqueada\n[color=#ff4444]> 0.80[/color]  Ω colapsa hacia 0",
		"TUTO_TIP_OMEGA": "[b][color=cyan]Ω — Flexibilidad Estructural[/color][/b]\n\nOpuesto al estrés. Alta Ω = adaptable.\nΩ = 1 / (1 + ε · k · n)\n\n[color=#88ff88]Mejoras estructurales mantienen Ω alto.[/color]",
		"TUTO_TIP_BIOMASA": "[b][color=#88ff88]Biomasa[/color][/b]\n\nRecurso del sistema fúngico.\nCrece con el ciclo microbiano, se consume\nen mutaciones y evoluciones.\n\n[color=cyan]Necesaria para evolucionar.[/color]",
		"TUTO_SC_TITLE": "⌨️ Atajos de Teclado",
		"TUTO_SC_GENERAL": "General",
		"TUTO_SC_L": "Activar / desactivar Modo Laboratorio",
		"TUTO_SC_K": "Ver progreso de la run",
		"TUTO_SC_UPGRADES": "Upgrades rápidos (teclas 1–9)",
		"TUTO_SC_1": "Mejorar clic",
		"TUTO_SC_2": "Trabajo Manual",
		"TUTO_SC_3": "Trueque",
		"TUTO_SC_4": "Mult. clic",
		"TUTO_SC_5": "Mult. auto",
		"TUTO_SC_6": "Red de trueque",
		"TUTO_SC_7": "Especialización",
		"TUTO_SC_8": "Capital cognitivo (μ)",
		"TUTO_SC_9": "Contabilidad",
		"TUTO_SC_B": "Abrir / cerrar panel Biosfera",
		"TUTO_SC_HEADER_IND": "Indicadores del header (hover para tooltip)",
		"TUTO_SC_EPS": "Estrés Estructural — sube con clics, baja con mejoras",
		"TUTO_SC_OMG": "Flexibilidad — colapsa si ε es muy alto",
		"TUTO_SC_BIO": "Biomasa — recurso del sistema fúngico",
		"TUTO_OBJ_TITLE": "Progreso de la Run",
		"TUTO_OBJ_NEXT": "Próximo objetivo:",
		"TUTO_OBJ_PROGRESS": "Progreso: %d / %d  (%d%%)",
		"TUTO_SEC_START": "Inicio",
		"TUTO_SEC_GROWTH": "Crecimiento",
		"TUTO_SEC_EVOLUTION": "Evolución",
		"TUTO_SEC_TRANSCEND": "Trascendencia",
		"TUTO_MS_RUN_STARTED": "Run iniciada",
		"TUTO_MS_FIRST_UPGRADE": "Primera mejora comprada",
		"TUTO_MS_PASSIVE": "Ingreso pasivo activo ($/s)",
		"TUTO_MS_PROD_NET": "Red de producción establecida",
		"TUTO_MS_COGNITIVE": "Capital Cognitivo activado (μ)",
		"TUTO_MS_BARTER_NET": "Red de trueque expandida",
		"TUTO_MS_SPECIALIZATION": "Especialización funcional",
		"TUTO_MS_ACCOUNTING": "Institución de Contabilidad",
		"TUTO_MS_PERSISTENCE": "Persistencia del sistema activa",
		"TUTO_MS_FIRST_MUT": "Primera mutación activada",
		"TUTO_MS_MULTI_MUT": "Mutaciones múltiples (×2+)",
		"TUTO_MS_HOMEO_START": "Homeostasis iniciada",
		"TUTO_MS_HOMEO_REACHED": "Homeostasis alcanzada",
		"TUTO_MS_HOMEO_SURPASSED": "Límite de Homeostasis superado",
		"TUTO_MS_LAB": "Modo Laboratorio descubierto",
		"TUTO_MS_TRAS1": "Primera Trascendencia completada",
		"TUTO_MS_LEGACY": "Legado acumulado",
		"TUTO_MS_ROUTE": "Ruta post-trascendencia activa",
		"TUTO_MS_TRAS2": "Segunda Trascendencia",
		"TUTO_MT_PASSIVE_TITLE": "¡Ingreso Pasivo activo!",
		"TUTO_MT_PASSIVE_BODY": "Trabajo Manual genera [b]$/s[/b] sin hacer clic.\nSeguí comprando mejoras para aumentarlo.",
		"TUTO_MT_HOMEO_TITLE": "¡Homeostasis alcanzada!",
		"TUTO_MT_HOMEO_BODY": "Mantenés ε en la banda óptima (0.03–0.30)\npara avanzar al siguiente tier del sistema.",
		"TUTO_MT_TRAS_TITLE": "¡Primera Trascendencia!",
		"TUTO_MT_TRAS_BODY": "Ganaste [b]Puntos de Legado[/b].\nEl sistema reinicia pero los buffs permanentes se conservan.",
		"TUTO_MT_LAB_TITLE": "Modo Laboratorio",
		"TUTO_MT_LAB_BODY": "Mostrás ε, Ω, μ y la fórmula de persistencia en tiempo real.\nPresioná [b][L][/b] para volver al modo normal.",
		"TUTO_AS_IDLE_PUSH": "Sistema detecta inactividad.\n[color=#aaffaa]+$%.0f de impulso[/color]",
		"TUTO_AS_HEADER": "[color=#aaaaff]Sugerencia[/color]",
		"TUTO_AS_BUY": "Podés comprar [b]%s[/b] ahora mismo.\nUsá las teclas [b][1–9][/b] para compras rápidas.",
		"TUTO_AS_EPS": "[color=yellow]ε = %.2f[/color] — nivel alto.\nComprá mejoras estructurales para bajar ε.\n[color=#ff8888]Por encima de 0.65 la Red Micelial se bloquea.[/color]",
		"TUTO_AS_NO_AUTO": "Sin [b]Trabajo Manual[/b] el ingreso solo viene de clics.\nSeguí acumulando para desbloquearlo.",
		"TUTO_AS_BIO": "[color=#88ff88]Biomasa suficiente[/color] para una mutación.\nRevisá el panel de [b]Genoma Fúngico[/b].",
		"TUTO_AS_HOMEO": "Estás en ruta hacia [color=cyan]Homeostasis[/color].\nMantenés ε en banda (0.03–0.30) para avanzar de tier.",
		"TUTO_UPG_CLICK": "Mejorar Clic",
		"TUTO_UPG_AUTO": "Trabajo Manual",
		"TUTO_UPG_TRUEQUE": "Trueque",
		"TUTO_UPG_CLICK_MULT": "Mult. Clic",
		"TUTO_UPG_AUTO_MULT": "Mult. Auto",
		"TUTO_UPG_TRUEQUE_NET": "Red de Trueque",
		"TUTO_UPG_SPECIALIZATION": "Especialización",
		"TUTO_UPG_COGNITIVE": "Capital Cognitivo (μ)",
		"TUTO_UPG_ACCOUNTING": "Contabilidad",
		"UI_PANEL_GENOME": "Genoma Fúngico + Próxima Mutación",
		"UI_PANEL_ECONOMY": "Economía",
		"UI_PANEL_STRUCTURE": "Estructura",
		"UI_TIP_EPSILON": "ε — Estrés estructural | banda sana 0.03–0.30 | Verde=en banda / Amarillo=alto / Rojo=crítico",
		"UI_TIP_OMEGA": "Ω — Estabilidad (1=perfecto) | Verde >0.75 / Amarillo 0.40 / Rojo <0.20",
		"UI_TIP_BIOMASA": "Biomasa — tejido fúngico | >12 bloquea homeostasis | >15 parasitismo colapsa",
		"UI_TIP_HIFAS": "Hifas — motor de crecimiento (cap ~40) | escalan con ingreso pasivo",
		"UI_TIP_NUTRIENTES": "Nutrientes — combustible para biomasa | cada 50 = 15% descuento en upgrades",
		"ROUTE_VACIO_HAMBRIENTO": "VACÍO HAMBRIENTO",
		"ROUTE_CARNAVAL": "CARNAVAL DE MUTACIONES",
		"ROUTE_REENCARNACION": "REENCARNACIÓN HEREDADA",

		# === UPGRADE LABELS ===
		"UPG_CLICK": "Mejorar click",
		"UPG_AUTO": "Trabajo Manual",
		"UPG_TRUEQUE": "Trueque",
		"UPG_CLICK_MULT": "Memoria Numérica",
		"UPG_AUTO_MULT": "Ritmo de Trabajo",
		"UPG_TRUEQUE_NET": "Red de Intercambio",
		"UPG_SPECIALIZATION": "Especialización de Oficio",
		"UPG_COGNITIVE": "Capital Cognitivo (μ)",
		"UPG_ACCOUNTING": "Contabilidad Básica",
		"UPG_PERSISTENCE": "Memoria Operativa del Sistema (c₀ +25%)",
		"UPG_TRUEQUE_ALLO": "Escalado Alostático",
		"UPG_ACQUIRED": "✓ ADQUIRIDO",

		# === MUTATION NAMES ===
		"MUT_ALLOSTASIS": "Resiliencia Alostática",
		"MUT_HOMEORHESIS": "Trascendencia Cristalina",
		"MUT_DEPREDADOR": "Depredador de Realidades",
		"MUT_MET_OSCURO": "METABOLISMO OSCURO",
		"MUT_HIPERASIMILACION": "HIPERASIMILACIÓN",
		"MUT_HOMEOSTASIS": "HOMEOSTASIS",
		"MUT_RED_MICELIAL": "RED MICELIAL (Fase A)",
		"MUT_ESPORULACION": "ESPORULACIÓN",
		"MUT_PARASITISMO": "PARASITISMO",
		"MUT_SIMBIOSIS": "SIMBIOSIS ESTRUCTURAL",

		# === GENOME PANEL ===
		"MUT_LABEL_HIPERAS": "Hiperasimilación",
		"MUT_LABEL_PARASIT": "Parasitismo",
		"MUT_LABEL_RED": "Red micelial",
		"MUT_LABEL_ESPOR": "Esporulación",
		"MUT_LABEL_SIMBIO": "Simbiosis",
		"MUT_LABEL_DEP": "Depredador",
		"MUT_LABEL_MO": "Met.Oscuro",
		"MUT_STATE_DORMIDO": "dormido",
		"MUT_STATE_LATENTE": "latente",
		"MUT_STATE_ACTIVO": "activo",
		"MUT_STATE_BLOQUEADO": "bloqueado",
		"MUT_ROUTE_PREFIX": "Ruta evolutiva",

		# === MUTATION TOASTS ===
		"MUT_TOAST_HIPERAS": "HIPERASIMILACIÓN EXTREMA — Click ×10 | Pasivo anulado | Run termina ahora",
		"MUT_TOAST_PARASIT": "PARASITISMO ACTIVO — El hongo drena la estructura",
		"MUT_TOAST_DEP": "DEPREDADOR ACTIVO — La realidad está siendo consumida",
		"MUT_TOAST_MO": "METABOLISMO OSCURO — Bioquímica alternativa estabilizada",
	},
	"en": {
		"UI_LANG_NAME": "English",

		# === MAIN MENU ===
		"MM_CONTINUE": "Continue",
		"MM_NEW_GAME": "New Game",
		"MM_NEW_RUN_POSTRANSCEND": "▶ New Run (cosmic buffs active)",
		"MM_ACHIEVEMENTS": "Achievements",
		"MM_LEGACY_BANK": "Genetic Bank",
		"MM_HISTORY": "Cycle History",
		"MM_CREDITS": "Credits",
		"MM_SETTINGS": "Settings",
		"MM_QUIT": "Quit",
		"MM_TOOLS": "Telemetry",
		"MM_BACK": "Back",

		# === SETTINGS PANEL ===
		"SET_TITLE": "⚙ SETTINGS",
		"SET_MUSIC": "Music",
		"SET_SFX": "Effects (SFX)",
		"SET_LANGUAGE": "Language",
		"SET_LANG_ES": "Español",
		"SET_LANG_EN": "English",
		"SET_EXPORT_SAVE": "Export save (.json)",
		"SET_IMPORT_SAVE": "Import save (.json)",
		"SET_EXPORT_HINT": "Saved to the game's data folder and the file explorer is opened.",
		"SET_IMPORT_HINT": "Load a save exported from desktop. Reload the run when finished.",
		"SET_RESET_TUTORIAL": "Reset tutorial",
		"SET_RESET_RUN": "Delete current run",
		"SET_CLOSE": "Close",

		# Telemetry
		"SET_TELEMETRY_CHECKBOX": "Send anonymous usage data (helps improve the game)",
		"SET_TELEMETRY_HINT": "Local and opt-in: saves anonymous JSON in user://telemetry/runs on run close.",
		"SET_TELEMETRY_OPEN": "Open telemetry folder",

		# Accessibility
		"SET_ACCESSIBILITY": "Accessibility",
		"SET_FONT_SIZE": "Text size:",
		"SET_FONT_NORMAL": "Normal (100%)",
		"SET_FONT_HINT": "Requires scene restart to apply.",
		"SET_REDUCE_MOTION": "Reduce motion (no animations)",
		"SET_HIGH_CONTRAST": "High contrast",
		"SET_COLORBLIND": "Color blindness:",
		"SET_COLORBLIND_OFF": "Disabled",

		# === TRANSCENDENCE ===
		"MM_TRANSCEND_BTN": "⚡ TRANSCEND",
		"MM_TRANSCEND_CONFIRM": "⚡ CONFIRM TRANSCENDENCE ⚡",
		"MM_TRANSCEND_LOCKED_BTN": "REQUIREMENTS NOT MET",
		"TRAS_WARN": "[!] On transcending, RESET: upgrades, mutations, PL, Genetic Bank buffs.\n* PRESERVED: Essence (Ξ), Cosmic Bank, completed routes.",

		# === NEW RUN ===
		"MM_NEW_RUN": "New Run",
		"MM_NEW_RUN_TOOLTIP": "Starts a new run preserving your Genetic Bank and Cosmic Bank.",
		"MM_TRANSCEND_COUNTER": "Ξ %d   ·   Transcendences: %d",
		"MM_NEW_RUN_TITLE": "Start New Run",
		"MM_NEW_RUN_TEXT": "Start a new biotic cycle?\n\n✦ PRESERVED:\n  · Cosmic Bank (%d Ξ)\n  · Genetic Bank (PL: %d)\n  · Completed routes\n\n⚠ RESET:\n  · Upgrades, money, mutations\n  · Current run progress",
		"MM_NEW_RUN_OK": "▶ Start",
		"MM_ROUTE_PICKER_SUBTITLE": "Each route changes this run's rules. The choice is permanent.",

		# === SLOTS ===
		"SLOT_START": "Start",
		"SLOT_RENAME_BTN": "Rename",
		"SLOT_DELETE_BTN": "Delete",
		"SLOT_NO_DELETE_LAST": "Cannot delete the last slot",
		"SLOT_EMPTY_LABEL": "Empty slot available",
		"SLOT_CREATE_BTN": "Create new",
		"SLOT_UNLOCK_HINT": "Buy 'Additional Slot' in the Genetic Bank / Knowledge to unlock more slots.",
		"SLOT_STATS_EMPTY": "Empty slot — no runs recorded",
		"SLOT_ACTIVE_TAG": "  [active]",
		"SLOT_NEW_TITLE": "New slot",
		"SLOT_NEW_NAME_LABEL": "Slot name:",
		"SLOT_RENAME_TITLE": "Rename slot",
		"SLOT_RENAME_NAME_LABEL": "New name:",
		"SLOT_DELETE_TITLE": "Delete slot",
		"SLOT_DELETE_TEXT": "Delete slot '%s'?\nThis parallel universe will be lost: legacy, essence, transcendences and current run.\nThis action is irreversible.",
		"SLOT_DELETE_OK": "Delete",
		"BTN_CANCEL": "Cancel",
		"SLOT_STATS_FORMAT": "T%d · %d cycles · Ξ %d · last: %s",

		# === GENETIC BANK ===
		"BANK_LEGACY_COUNTER": "Accumulated legacy: %d PL\nBiotic Cycles completed: %d",
		"BANK_BTN_MAX": "MAXED",
		"BANK_BTN_LOCKED": "LOCKED",
		"BANK_BTN_ACQUIRE": "ACQUIRE",
		"BANK_BTN_LEVEL": "Lv%d  %d PL",

		# === TRANSCENDENCE PANEL ===
		"TRAS_SUBTITLE": "Dissolve the current cycle to absorb it as Essence (Ξ).",
		"TRAS_GATE_TITLE": "Requirements:",
		"TRAS_REWARD_TITLE": "Reward on transcending:",
		"TRAS_REWARD_TEXT": "You gain +%d Ξ (Essence)\nCurrent PL: %d -> converted\nUnique routes: %d × 5 Ξ\nTier bonus: +%d Ξ",
		"TRAS_LOCKED_TEXT": "Requirements not met.\nComplete at least 1 close in each family and accumulate %d PL.",

		# === FIRST TRANSCENDENCE ===
		"TRAS_FIRST_NARRATIVE": "The cycle has closed upon itself.\n\nAll the routes you traveled — order, expansion, collapse —\nnow converge at a single point outside the fungus's time.\n\nYour code is no longer a program.\nIt is a crystalline memory: Essence.\n\nThe matrix resets.\nBut you are no longer the same system.",
		"TRAS_FIRST_HINT": "You now have access to the Cosmic Bank.",

		# === HISTORY ===
		"HIST_TAB_CURRENT": "Current transcendence cycle",
		"HIST_TAB_ALL": "Full history",

		# === SLOT SELECTOR ===
		"SLOT_SELECT_TITLE": "Select Slot",
		"SLOT_SELECT_SUBTITLE": "Each slot is a parallel universe: its own legacy, essence and transcendences.",
		"MM_QUIT_GAME": "Quit game",

		# === CREDITS ===
		"CREDITS_THANKS": "Thanks for playing.",

		# === IN-GAME UI ===
		"GAME_BTN_RESET": "Reset",
		"GAME_BTN_NEW_RUN": "New Run",
		"GAME_BTN_SETTINGS": "Settings",
		"GAME_SHORTCUTS_TOOLTIP": "Keyboard shortcuts and indicators",
		"GAME_PL_COUNTER": "PL Available: %d    Biotic reserve: %.1f / 50 spores",
		"GAME_BUFF_ACTIVE": "OK ACTIVE",
		"GAME_BUFF_INACTIVE": "X INACTIVE",
		"GAME_BTN_LEVEL": "Lv.%d  %d PL",
		"GAME_BTN_LOCKED": "LOCKED",
		"GAME_BTN_FREE": "FREE",
		# === TUTORIAL ===
		"TUTO_WELCOME_TITLE": "Welcome to AntiIDLE",
		"TUTO_WELCOME_BODY": "[center]You are a structure in the process of evolution.\n\nClick the [b]reactor[/b] to generate energy, buy [b]upgrades[/b] to grow, and watch [color=yellow][b]structural stress (ε)[/b][/color] before your system collapses.\n\n[color=cyan]Pressure gives rise to adaptation.[/color][/center]",
		"TUTO_BTN_SKIP": "Skip tutorial",
		"TUTO_BTN_START": "  Start  ",
		"TUTO_BTN_CLOSE": "Close",
		"TUTO_BTN_UNDERSTOOD": "Got it ✓",
		"TUTO_STEP1": "[b]Click the reactor![/b]\nEach click generates energy and increases\nstructural stress [color=yellow](ε)[/color].",
		"TUTO_STEP2": "[b]First upgrade available![/b]\nUpgrades increase your passive income\nand structural complexity.",
		"TUTO_STEP3": "[b][L][/b] activates [color=cyan]Lab Mode[/color]:\nadvanced live stats for ε, Ω and μ.",
		"TUTO_STEP4": "[color=yellow][b]ε — Structural Stress[/b][/color]\nRises with clicks, drops with upgrades.\n\n[color=#88ff88]< 0.35[/color]  biology and order available\n[color=#ffaa44]> 0.40[/color]  Hyperassimilation awakens\n[color=#ff8888]> 0.65[/color]  mycelial expansion blocked\n[color=#ff4444]> 0.80[/color]  Ω collapses — rigid system\n\n[color=#888888]Hover over ε in the header for more.[/color]",
		"TUTO_STEP5": "[color=#88ff88][b]Passive Income[/b][/color]\n\n[b][2] Manual Labor[/b] and [b][3] Barter[/b]\ngenerate $/s without clicking.\n\nWatch the [b]$/s[/b] indicator in the header.",
		"TUTO_STEP6": "[color=#88ff88][b]Fungal Genome[/b][/color]\n\n[b]Biomass[/b] accumulates on its own over time —\nthe fungal system generates it in the background.\nCheck the [color=#88ff88][b]Bio[/b][/color] indicator at the top right.\n\n[color=#aaaaff]When you have enough, the [b]Genome[/b] panel\nlights up — that's where you activate [b]Mutations[/b]\nthat open unique growth paths.[/color]",
		"TUTO_STEP7": "[color=#88ff88][b]Mutation[/b][/color] — the system offers you paths.\n\n[color=cyan]Equilibrium[/color]   keep ε calm\n[color=#88ff88]Biology[/color]      expand, grow, spread\n[color=yellow]Cooperation[/color]  build in order\n\n[color=#ff6666]...or let chaos dominate.[/color]\n\n[color=#888888]The mutation is not chosen. It is earned.[/color]",
		"TUTO_MUT_HIPERASIMILACION": "[b]Hyperassimilation[/b] activated.\nIncreased resource absorption — passive income boosted.",
		"TUTO_MUT_PARASITISMO": "[b]Parasitism[/b] activated.\nThe system extracts resources from the environment with periodic money bonuses.",
		"TUTO_MUT_RED_MICELIAL": "[b]Mycelial Network[/b] activated.\nHyphae and Mycelium regenerate faster.",
		"TUTO_MUT_ESPORULACION": "[b]Sporulation[/b] activated.\nOccasional Biomass boosts from spore dispersal.",
		"TUTO_MUT_SIMBIOSIS": "[b]Symbiosis[/b] activated.\nStructural cooperation — upgrades are cheaper.",
		"TUTO_MUT_HOMEOSTASIS": "[b]Homeostasis[/b] activated.\nAll production +50% (click and passive). Ω_min = 0.35. Optimal ε band active to close the run.",
		"TUTO_MUT_ALLOSTASIS": "[b]Allostasis[/b] activated.\nProactive adaptation to structural stress.",
		"TUTO_MUT_DEPREDADOR": "[b]Predator Mode[/b] activated.\nHigh risk, high return — you consume to grow fast.",
		"TUTO_MUT_MET_OSCURO": "[color=#ff6666][b]Dark Metabolism[/b][/color] activated.\nConventional upgrades blocked. Powers non-linear paths.",
		"TUTO_TOAST_MUT_TITLE": "New Mutation",
		"TUTO_TIP_MU": "[b][color=#ff88ff]μ — Cognitive Capital[/color][/b]\n\nAmplifies the structural persistence of the system.\nGrows with [b]Cognitive Capital[/b] upgrades\nand boosted by [b]Accounting[/b].\n\nμ = 1 + ln(1 + n) × 0.08\n\n[color=cyan]Accounting: ×1.08 per level.[/color]\n[color=#aaaaff]Resilience: up to ×1.30 extra.[/color]",
		"TUTO_TIP_EPSILON": "[b][color=yellow]ε — Structural Stress[/color][/b]\n\nInternal tension of the system.\nRises with each click, drops with upgrades.\n\n[color=#88ff88]< 0.35[/color]  Biology and order available\n[color=#ffaa44]> 0.40[/color]  Hyperassimilation awakens\n[color=#ff8888]> 0.65[/color]  Mycelial expansion blocked\n[color=#ff4444]> 0.80[/color]  Ω collapses to 0",
		"TUTO_TIP_OMEGA": "[b][color=cyan]Ω — Structural Flexibility[/color][/b]\n\nOpposite of stress. High Ω = adaptable.\nΩ = 1 / (1 + ε · k · n)\n\n[color=#88ff88]Structural upgrades keep Ω high.[/color]",
		"TUTO_TIP_BIOMASA": "[b][color=#88ff88]Biomass[/color][/b]\n\nFungal system resource.\nGrows with the microbial cycle, consumed\nin mutations and evolutions.\n\n[color=cyan]Needed to evolve.[/color]",
		"TUTO_SC_TITLE": "⌨️ Keyboard Shortcuts",
		"TUTO_SC_GENERAL": "General",
		"TUTO_SC_L": "Toggle Lab Mode",
		"TUTO_SC_K": "View run progress",
		"TUTO_SC_UPGRADES": "Quick upgrades (keys 1–9)",
		"TUTO_SC_1": "Improve click",
		"TUTO_SC_2": "Manual Labor",
		"TUTO_SC_3": "Exchange",
		"TUTO_SC_4": "Click mult.",
		"TUTO_SC_5": "Auto mult.",
		"TUTO_SC_6": "Exchange network",
		"TUTO_SC_7": "Specialization",
		"TUTO_SC_8": "Cognitive capital (μ)",
		"TUTO_SC_9": "Accounting",
		"TUTO_SC_B": "Open / close Biosphere panel",
		"TUTO_SC_HEADER_IND": "Header indicators (hover for tooltip)",
		"TUTO_SC_EPS": "Structural Stress — rises with clicks, drops with upgrades",
		"TUTO_SC_OMG": "Flexibility — collapses if ε is too high",
		"TUTO_SC_BIO": "Biomass — fungal system resource",
		"TUTO_OBJ_TITLE": "Run Progress",
		"TUTO_OBJ_NEXT": "Next objective:",
		"TUTO_OBJ_PROGRESS": "Progress: %d / %d  (%d%%)",
		"TUTO_SEC_START": "Start",
		"TUTO_SEC_GROWTH": "Growth",
		"TUTO_SEC_EVOLUTION": "Evolution",
		"TUTO_SEC_TRANSCEND": "Transcendence",
		"TUTO_MS_RUN_STARTED": "Run started",
		"TUTO_MS_FIRST_UPGRADE": "First upgrade purchased",
		"TUTO_MS_PASSIVE": "Passive income active ($/s)",
		"TUTO_MS_PROD_NET": "Production network established",
		"TUTO_MS_COGNITIVE": "Cognitive Capital activated (μ)",
		"TUTO_MS_BARTER_NET": "Barter network expanded",
		"TUTO_MS_SPECIALIZATION": "Functional specialization",
		"TUTO_MS_ACCOUNTING": "Accounting institution",
		"TUTO_MS_PERSISTENCE": "System persistence active",
		"TUTO_MS_FIRST_MUT": "First mutation activated",
		"TUTO_MS_MULTI_MUT": "Multiple mutations (x2+)",
		"TUTO_MS_HOMEO_START": "Homeostasis started",
		"TUTO_MS_HOMEO_REACHED": "Homeostasis reached",
		"TUTO_MS_HOMEO_SURPASSED": "Homeostasis limit surpassed",
		"TUTO_MS_LAB": "Lab Mode discovered",
		"TUTO_MS_TRAS1": "First Transcendence completed",
		"TUTO_MS_LEGACY": "Legacy accumulated",
		"TUTO_MS_ROUTE": "Post-transcendence route active",
		"TUTO_MS_TRAS2": "Second Transcendence",
		"TUTO_MT_PASSIVE_TITLE": "Passive Income active!",
		"TUTO_MT_PASSIVE_BODY": "Manual Labor generates [b]$/s[/b] without clicking.\nKeep buying upgrades to increase it.",
		"TUTO_MT_HOMEO_TITLE": "Homeostasis reached!",
		"TUTO_MT_HOMEO_BODY": "Keep ε in the optimal band (0.03–0.30)\nto advance to the next system tier.",
		"TUTO_MT_TRAS_TITLE": "First Transcendence!",
		"TUTO_MT_TRAS_BODY": "You gained [b]Legacy Points[/b].\nThe system resets but permanent buffs are preserved.",
		"TUTO_MT_LAB_TITLE": "Lab Mode",
		"TUTO_MT_LAB_BODY": "Shows ε, Ω, μ and the persistence formula in real time.\nPress [b][L][/b] to go back to normal mode.",
		"TUTO_AS_IDLE_PUSH": "System detects inactivity.\n[color=#aaffaa]+$%.0f boost[/color]",
		"TUTO_AS_HEADER": "[color=#aaaaff]Tip[/color]",
		"TUTO_AS_BUY": "You can buy [b]%s[/b] right now.\nUse keys [b][1–9][/b] for quick purchases.",
		"TUTO_AS_EPS": "[color=yellow]ε = %.2f[/color] — high level.\nBuy structural upgrades to lower ε.\n[color=#ff8888]Above 0.65 the Mycelial Network is blocked.[/color]",
		"TUTO_AS_NO_AUTO": "Without [b]Manual Labor[/b] income only comes from clicks.\nKeep accumulating to unlock it.",
		"TUTO_AS_BIO": "[color=#88ff88]Enough biomass[/color] for a mutation.\nCheck the [b]Fungal Genome[/b] panel.",
		"TUTO_AS_HOMEO": "You're on the [color=cyan]Homeostasis[/color] path.\nKeep ε in band (0.03–0.30) to advance tier.",
		"TUTO_UPG_CLICK": "Improve Click",
		"TUTO_UPG_AUTO": "Manual Labor",
		"TUTO_UPG_TRUEQUE": "Barter",
		"TUTO_UPG_CLICK_MULT": "Click Mult.",
		"TUTO_UPG_AUTO_MULT": "Auto Mult.",
		"TUTO_UPG_TRUEQUE_NET": "Barter Network",
		"TUTO_UPG_SPECIALIZATION": "Specialization",
		"TUTO_UPG_COGNITIVE": "Cognitive Capital (μ)",
		"TUTO_UPG_ACCOUNTING": "Accounting",
		"UI_PANEL_GENOME": "Fungal Genome + Next Mutation",
		"UI_PANEL_ECONOMY": "Economy",
		"UI_PANEL_STRUCTURE": "Structure",
		"UI_TIP_EPSILON": "ε — Structural stress | healthy band 0.03–0.30 | Green=in band / Yellow=high / Red=critical",
		"UI_TIP_OMEGA": "Ω — Stability (1=perfect) | Green >0.75 / Yellow 0.40 / Red <0.20",
		"UI_TIP_BIOMASA": "Biomass — fungal tissue | >12 blocks homeostasis | >15 parasitism collapses",
		"UI_TIP_HIFAS": "Hyphae — growth engine (cap ~40) | scale with passive income",
		"UI_TIP_NUTRIENTES": "Nutrients — biomass fuel | each 50 = 15% upgrade cost discount",
		"ROUTE_VACIO_HAMBRIENTO": "HUNGRY VOID",
		"ROUTE_CARNAVAL": "CARNIVAL OF MUTATIONS",
		"ROUTE_REENCARNACION": "INHERITED REINCARNATION",

		# === UPGRADE LABELS ===
		"UPG_CLICK": "Improve Click",
		"UPG_AUTO": "Manual Labor",
		"UPG_TRUEQUE": "Exchange",
		"UPG_CLICK_MULT": "Numeric Memory",
		"UPG_AUTO_MULT": "Work Rhythm",
		"UPG_TRUEQUE_NET": "Exchange Network",
		"UPG_SPECIALIZATION": "Trade Specialization",
		"UPG_COGNITIVE": "Cognitive Capital (μ)",
		"UPG_ACCOUNTING": "Basic Accounting",
		"UPG_PERSISTENCE": "System Operative Memory (c₀ +25%)",
		"UPG_TRUEQUE_ALLO": "Allostatic Scaling",
		"UPG_ACQUIRED": "✓ ACQUIRED",

		# === MUTATION NAMES ===
		"MUT_ALLOSTASIS": "Allostatic Resilience",
		"MUT_HOMEORHESIS": "Crystalline Transcendence",
		"MUT_DEPREDADOR": "Reality Predator",
		"MUT_MET_OSCURO": "DARK METABOLISM",
		"MUT_HIPERASIMILACION": "HYPERASSIMILATION",
		"MUT_HOMEOSTASIS": "HOMEOSTASIS",
		"MUT_RED_MICELIAL": "MYCELIAL NETWORK (Phase A)",
		"MUT_ESPORULACION": "SPORULATION",
		"MUT_PARASITISMO": "PARASITISM",
		"MUT_SIMBIOSIS": "STRUCTURAL SYMBIOSIS",

		# === GENOME PANEL ===
		"MUT_LABEL_HIPERAS": "Hyperassimilation",
		"MUT_LABEL_PARASIT": "Parasitism",
		"MUT_LABEL_RED": "Mycelial network",
		"MUT_LABEL_ESPOR": "Sporulation",
		"MUT_LABEL_SIMBIO": "Symbiosis",
		"MUT_LABEL_DEP": "Predator",
		"MUT_LABEL_MO": "Dark Met.",
		"MUT_STATE_DORMIDO": "dormant",
		"MUT_STATE_LATENTE": "latent",
		"MUT_STATE_ACTIVO": "active",
		"MUT_STATE_BLOQUEADO": "locked",
		"MUT_ROUTE_PREFIX": "Evolutionary route",

		# === MUTATION TOASTS ===
		"MUT_TOAST_HIPERAS": "EXTREME HYPERASSIMILATION — Click ×10 | Passive nulled | Run ends now",
		"MUT_TOAST_PARASIT": "PARASITISM ACTIVE — The fungus drains the structure",
		"MUT_TOAST_DEP": "PREDATOR ACTIVE — Reality is being consumed",
		"MUT_TOAST_MO": "DARK METABOLISM — Alternative biochemistry stabilized",
	}
}

func _ready() -> void:
	_install_translations()
	_load_settings()
	TranslationServer.set_locale(current_locale)
	print("[LocaleManager] locale=", current_locale)

# ─────────────────────────────────────────────────────────────
# API pública
# ─────────────────────────────────────────────────────────────
func set_locale(loc: String) -> void:
	if loc == current_locale: return
	if not SUPPORTED_LOCALES.has(loc):
		push_warning("[LocaleManager] locale no soportada: %s" % loc)
		return
	current_locale = loc
	TranslationServer.set_locale(loc)
	_save_settings()
	locale_changed.emit(loc)

## Atajo: devuelve la traducción de una key. Equivalente a tr(key) pero
## explicita el sistema en el código consumidor.
func t(key: String) -> String:
	return TranslationServer.translate(key)

# ─────────────────────────────────────────────────────────────
# Instalación de traducciones en TranslationServer
# ─────────────────────────────────────────────────────────────
func _install_translations() -> void:
	for locale in TRANSLATIONS.keys():
		var translation := Translation.new()
		translation.locale = locale
		var messages: Dictionary = TRANSLATIONS[locale]
		for key in messages.keys():
			translation.add_message(key, messages[key])
		TranslationServer.add_translation(translation)

# ─────────────────────────────────────────────────────────────
# Persistencia
# ─────────────────────────────────────────────────────────────
func _save_settings() -> void:
	var data := {"locale": current_locale}
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f: return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK: return
	if not json.data is Dictionary: return
	var loc: String = json.data.get("locale", DEFAULT_LOCALE)
	if SUPPORTED_LOCALES.has(loc):
		current_locale = loc
