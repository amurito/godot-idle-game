# Contribuyendo a IDLE Fungi

Gracias por tu interés en contribuir. Acá está cómo hacerlo.

## 📋 Código de Conducta
Sé respetuoso, constructivo. Todas las contribuciones son bienvenidas.

## 🐛 Reportar Bugs
1. Verifica que el bug no esté reportado ya.
2. Usa el template **Bug Report** en Issues.
3. Incluye pasos claros para reproducir + logs si es posible.

## 💡 Feature Requests
1. Describe el problema que resuelve.
2. Usa el template **Feature Request** en Issues.
3. Incluye contexto: gameplay, balance, contenido, etc.

## 🔨 Desarrollo Local
```bash
git clone https://github.com/user/idleantigravity.git
cd idleantigravity
# Abre con Godot 4.5
```

## 🧪 Tests
```
Project → Run a Specific Scene → tests/TestRunner.tscn
```
Todos los tests deben pasar antes de PR.

## 📝 Commits
- Usa mensajes claros: "fix: bug X", "feat: nueva feature Y", "refactor: Z"
- Pequeños commits lógicos, no megacommits
- Sé descriptivo en el cuerpo si hace falta

## 🔀 Pull Requests
1. Crea una rama con nombre descriptivo: `feature/nombre` o `fix/issue-123`
2. Rebase contra `main` antes de PR
3. Describe cambios claramente en el PR
4. Espera review

## 📚 Arquitectura
- `/docs/roadmaps/roadmap_actual.md` — línea evolutiva del proyecto
- `main.gd` — orquestador de escena (target: <1800 líneas)
- Autoloads: managers independientes en `/`
- Tests: en `/tests/` sin UI, sin escena principal

## 🎨 Estilo de código
- GDScript puro, Godot 4.5
- Comenta lo no obvio
- Usa `assert()` y validaciones
- Nombres de variables en inglés o español, sé consistente

## ❓ Preguntas
Abre una **Discussion** en GitHub, no Issues para preguntas.

---

Gracias por mejorar IDLE Fungi 🍄
