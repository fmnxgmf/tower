# Language Switch Design

**Goal**
Add a player-facing language setting on the start screen so the game can switch between Chinese and English, persist the chosen language locally, and apply it to all UI text, tower descriptions, level names, and dynamic battle messages.

**Approach**
Introduce a lightweight localization manager as an autoload singleton. It owns the active language, loads/saves the preference from a local config file, and exposes key-based lookup plus formatted text helpers. The main scene becomes a consumer of localization keys instead of embedding final strings. Tower descriptions and level names move from hard-coded per-language values in gameplay scripts to translation keys backed by centralized dictionaries.

**Key Decisions**
- Use a local singleton instead of Godot Translation resources to keep the change small and consistent with the current prototype.
- Put the language selector on the start overlay so players choose before entering gameplay.
- Refresh all text from a single `apply_localized_text()` path in the main scene, and re-run it after language changes.
- Persist the selection to `user://` config so the next launch uses the previous language.

**Affected Files**
- Create `scripts/localization_manager.gd` for dictionaries, lookup helpers, and persistence.
- Modify `project.godot` to autoload the localization manager.
- Modify `scripts/main.gd` to request localized text, build localized tower labels, and react to language changes.
- Modify `scenes/main.tscn` to add a start-screen language selector.
- Modify `scripts/wave_spawner.gd` and `scripts/level_manager.gd` to expose stable keys instead of fixed final-language text.
- Modify tests to cover translated data and saved language preference.

**Testing**
- Add regression checks that verify localized tower info and level names resolve from keys.
- Add a persistence check that saves a selected language and reloads it.
- Run existing Godot headless tests and headless project startup.