# 技术规格文档

## 1. 项目结构

```
tower_defense/
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── towers/
│   │   ├── tower_base.tscn
│   │   ├── basic_tower.tscn
│   │   ├── slow_tower.tscn
│   │   ├── aoe_tower.tscn
│   │   └── sniper_tower.tscn
│   ├── enemies/
│   │   ├── enemy_base.tscn
│   │   ├── fast_enemy.tscn
│   │   ├── tank_enemy.tscn
│   │   ├── flying_enemy.tscn
│   │   └── regen_enemy.tscn
│   └── projectile.tscn
├── scripts/
│   ├── game_manager.gd
│   ├── pathfinding.gd
│   ├── tower_base.gd
│   ├── enemy_base.gd
│   ├── projectile.gd
│   └── wave_spawner.gd
└── assets/
    └── placeholder/
```

## 2. 核心类设计

### GameManager (Singleton)
```gdscript
extends Node

var gold: int = 500
var health: int = 20
var current_wave: int = 0
var game_state: String = "PLAYING"  # PLAYING, PAUSED, WIN, LOSE

signal gold_changed(new_gold)
signal health_changed(new_health)
signal wave_changed(new_wave)
signal game_over(won: bool)
```

### Pathfinding
```gdscript
class_name Pathfinding

const GRID_SIZE = Vector2i(20, 15)
const CELL_SIZE = 32

func find_path(start: Vector2i, end: Vector2i, is_flying: bool) -> Array[Vector2i]
func is_path_valid(blocked_cells: Array[Vector2i]) -> bool
```

### TowerBase
```gdscript
extends Node2D

@export var damage: float = 10.0
@export var attack_range: float = 100.0
@export var attack_speed: float = 1.0
@export var cost: int = 100

var targets: Array[Enemy] = []
var attack_timer: float = 0.0

func _process(delta): pass
func find_targets(): pass
func attack_target(target: Enemy): pass
```

### EnemyBase
```gdscript
extends CharacterBody2D

@export var max_health: float = 100.0
@export var move_speed: float = 100.0
@export var gold_reward: int = 10
@export var is_flying: bool = false

var current_health: float
var path: Array[Vector2i] = []
var path_index: int = 0
var slow_modifier: float = 1.0

func take_damage(amount: float): pass
func move_along_path(delta: float): pass
func die(): pass
```

## 3. 数据配置

### 防御塔配置
| 类型 | 伤害 | 射程 | 攻速 | 成本 | 特殊效果 |
|------|------|------|------|------|----------|
| 基础炮塔 | 15 | 100 | 1.0 | 100 | 无 |
| 减速塔 | 5 | 80 | 0.5 | 150 | 减速50% |
| 范围塔 | 8 | 90 | 1.5 | 200 | AOE半径50 |
| 狙击塔 | 50 | 200 | 3.0 | 250 | 无 |

### 敌人配置
| 类型 | 血量 | 速度 | 奖励 | 特殊能力 |
|------|------|------|------|----------|
| 快速 | 50 | 150 | 10 | 无 |
| 坦克 | 300 | 50 | 30 | 无 |
| 飞行 | 80 | 100 | 20 | 飞行 |
| 再生 | 150 | 80 | 25 | 回血5/秒 |

## 4. 波次设计

### 第1关波次表
```
波次1: 5x快速
波次2: 8x快速
波次3: 3x坦克
波次4: 10x快速 + 2x坦克
波次5: 5x飞行
波次6: 12x快速 + 3x坦克
波次7: 8x飞行 + 2x再生
波次8: 15x快速 + 5x坦克
波次9: 10x飞行 + 5x再生
波次10: 20x快速 + 8x坦克 + 5x飞行 + 3x再生
```

## 5. A* 寻路算法

### 伪代码
```
function find_path(start, goal, is_flying):
    open_set = [start]
    came_from = {}
    g_score = {start: 0}
    f_score = {start: heuristic(start, goal)}

    while open_set not empty:
        current = node in open_set with lowest f_score

        if current == goal:
            return reconstruct_path(came_from, current)

        open_set.remove(current)

        for neighbor in get_neighbors(current, is_flying):
            tentative_g = g_score[current] + 1

            if tentative_g < g_score[neighbor]:
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic(neighbor, goal)

                if neighbor not in open_set:
                    open_set.add(neighbor)

    return []  # No path found
```

### 邻居获取规则
- 地面单位：只能移动到空格子（不能穿过塔）
- 飞行单位：可以移动到任何格子（包括有塔的格子）

## 6. UI 布局

```
┌─────────────────────────────────────┐
│ 金币: 500  生命: 20  波次: 1/10     │
├─────────────────────────────────────┤
│                                     │
│         游戏地图区域                 │
│         (640x480)                   │
│                                     │
├─────────────────────────────────────┤
│ [基础塔] [减速塔] [范围塔] [狙击塔] │
│  $100     $150     $200     $250    │
└─────────────────────────────────────┘
```

## 7. 性能优化

- 使用对象池管理敌人和子弹
- 限制每帧寻路计算次数
- 使用 Area2D 进行范围检测
- 敌人超出屏幕时暂停更新
