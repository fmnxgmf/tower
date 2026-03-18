extends Node

signal language_changed(language: String)

const SAVE_PATH := "user://settings.cfg"
const SAVE_SECTION := "localization"
const SAVE_KEY := "language"
const DEFAULT_LANGUAGE := "zh"
const SUPPORTED_LANGUAGES := ["zh", "en"]
const LANGUAGE_LABELS := {
    "zh": "中文",
    "en": "English"
}
const STRINGS := {
    "zh": {
        "ui.game_title": "塔防游戏",
        "ui.gold": "金币: %d",
        "ui.health": "生命: %d",
        "ui.wave": "波次: %d/%d",
        "ui.level": "关卡: %s",
        "ui.start_wave": "开始波次",
        "ui.pause": "暂停",
        "ui.resume": "继续",
        "ui.start_game": "开始游戏",
        "ui.next_level": "下一关",
        "ui.restart": "重新开始",
        "ui.pause_title": "战局暂停",
        "ui.language": "语言",
        "level.grassland_gate": "草原关隘",
        "level.iron_crossroads": "铁壁岔路",
        "tower.basic.name": "基础塔",
        "tower.slow.name": "霜缚塔",
        "tower.aoe.name": "爆裂塔",
        "tower.sniper.name": "猎隼塔",
        "tower.basic.info": "均衡的单体输出防御塔。",
        "tower.slow.info": "攻击会附加减速，让敌军步伐迟缓。",
        "tower.aoe.info": "释放小范围爆裂打击，压制成群敌军。",
        "tower.sniper.info": "超远距离精准狙杀，单发伤害极高。",
        "status.start_prompt": "点燃战旗，准备守住关隘。",
        "status.build_defense": "为 %s 布下第一道防线。",
        "status.gold_shortage": "%s 金币不足。",
        "status.invalid_placement": "此地若筑塔，会堵死军道。",
        "status.tower_built": "%s 已就位。",
        "status.wave_started": "第 %d 波敌军已逼近。",
        "status.wave_cleared": "第 %d 波已被击退。",
        "status.win": "守关告捷！",
        "status.lose": "关隘失守！",
        "warning.unknown_enemy": "未知敌军类型: %s"
    },
    "en": {
        "ui.game_title": "Tower Defense",
        "ui.gold": "Gold: %d",
        "ui.health": "Health: %d",
        "ui.wave": "Wave: %d/%d",
        "ui.level": "Level: %s",
        "ui.start_wave": "Start Wave",
        "ui.pause": "Pause",
        "ui.resume": "Resume",
        "ui.start_game": "Start Game",
        "ui.next_level": "Next Level",
        "ui.restart": "Restart",
        "ui.pause_title": "Paused",
        "ui.language": "Language",
        "level.grassland_gate": "Grassland Gate",
        "level.iron_crossroads": "Iron Crossroads",
        "tower.basic.name": "Basic Tower",
        "tower.slow.name": "Frost Tower",
        "tower.aoe.name": "Blast Tower",
        "tower.sniper.name": "Falcon Tower",
        "tower.basic.info": "A balanced tower focused on single-target damage.",
        "tower.slow.info": "Its attacks slow enemies and disrupt their advance.",
        "tower.aoe.info": "Unleashes a compact blast that punishes clustered enemies.",
        "tower.sniper.info": "An elite long-range tower with devastating single shots.",
        "status.start_prompt": "Raise the banner and prepare to hold the pass.",
        "status.build_defense": "Build your first line of defense at %s.",
        "status.gold_shortage": "%s costs more gold than you have.",
        "status.invalid_placement": "Building there would seal the path.",
        "status.tower_built": "%s is in position.",
        "status.wave_started": "Wave %d is advancing.",
        "status.wave_cleared": "Wave %d has been repelled.",
        "status.win": "Victory at the gate!",
        "status.lose": "The gate has fallen!",
        "warning.unknown_enemy": "Unknown enemy type: %s"
    }
}

var current_language: String = DEFAULT_LANGUAGE

func _ready() -> void:
    load_language()

func load_language() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) == OK:
        set_language(String(config.get_value(SAVE_SECTION, SAVE_KEY, DEFAULT_LANGUAGE)), false)
    else:
        current_language = DEFAULT_LANGUAGE

func save_language() -> void:
    var config := ConfigFile.new()
    config.set_value(SAVE_SECTION, SAVE_KEY, current_language)
    config.save(SAVE_PATH)

func set_language(language: String, persist: bool = true) -> void:
    var normalized: String = language if language in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
    if current_language == normalized:
        if persist:
            save_language()
        return
    current_language = normalized
    if persist:
        save_language()
    language_changed.emit(current_language)

func get_language() -> String:
    return current_language

func get_supported_languages() -> Array[String]:
    var languages: Array[String] = []
    for language in SUPPORTED_LANGUAGES:
        languages.append(String(language))
    return languages

func get_language_label(language: String) -> String:
    return String(LANGUAGE_LABELS.get(language, language))

func text(key: String) -> String:
    var lang_table: Dictionary = STRINGS.get(current_language, STRINGS[DEFAULT_LANGUAGE])
    if lang_table.has(key):
        return String(lang_table[key])
    var fallback_table: Dictionary = STRINGS[DEFAULT_LANGUAGE]
    return String(fallback_table.get(key, key))

func textf(key: String, args: Array = []) -> String:
    return text(key) % args