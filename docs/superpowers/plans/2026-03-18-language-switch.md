# Language Switch Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a saved language selector on the start screen that switches all game text between Chinese and English.

**Architecture:** Add an autoloaded localization manager that stores the current language, resolves string keys, and saves the preference. Convert gameplay/UI scripts to request localized text by key and refresh visible labels when the language changes.

**Tech Stack:** Godot 4.6 GDScript, Godot scenes, headless script-based tests

---

## Chunk 1: Localization Foundation

### Task 1: Add localization manager

**Files:**
- Create: `scripts/localization_manager.gd`
- Modify: `project.godot`
- Test: `tests/test_edge_cases.gd`

- [ ] **Step 1: Write the failing persistence test**
- [ ] **Step 2: Run `Godot --headless --script res://tests/run_tests.gd` and verify it fails for missing localization manager behavior**
- [ ] **Step 3: Implement minimal `LocalizationManager` dictionaries, save/load helpers, and lookup methods**
- [ ] **Step 4: Add autoload entry in `project.godot`**
- [ ] **Step 5: Re-run the failing test and confirm it passes**

## Chunk 2: UI Wiring

### Task 2: Add start-screen language selector and text refresh flow

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`
- Test: `tests/test_core_logic.gd`

- [ ] **Step 1: Write the failing UI test for language-aware labels**
- [ ] **Step 2: Run tests and verify the new assertions fail**
- [ ] **Step 3: Add the selector UI to the start overlay and connect it in `main.gd`**
- [ ] **Step 4: Replace embedded UI strings with localization keys and a centralized refresh function**
- [ ] **Step 5: Re-run tests and confirm they pass**

## Chunk 3: Gameplay Data Localization

### Task 3: Localize tower and level metadata

**Files:**
- Modify: `scripts/wave_spawner.gd`
- Modify: `scripts/level_manager.gd`
- Modify: `scripts/main.gd`
- Test: `tests/test_core_logic.gd`

- [ ] **Step 1: Write failing assertions for localized level names and tower descriptions**
- [ ] **Step 2: Run tests and verify the assertions fail**
- [ ] **Step 3: Replace fixed final strings with translation keys in metadata**
- [ ] **Step 4: Resolve those keys in the main scene when building labels and descriptions**
- [ ] **Step 5: Re-run tests and confirm they pass**

## Chunk 4: Verification

### Task 4: Full regression run

**Files:**
- Test: `tests/run_tests.gd`

- [ ] **Step 1: Run `D:\google\godot\Godot_v4.6.1-stable_win64_console.exe --headless --path F:\hubpro\tower --script res://tests/run_tests.gd`**
- [ ] **Step 2: Run `D:\google\godot\Godot_v4.6.1-stable_win64_console.exe --headless --path F:\hubpro\tower --quit-after 10`**
- [ ] **Step 3: Review git diff for unrelated Godot-generated noise and keep it out of commits**