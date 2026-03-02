# 历练系统文档 (LianliSystem)

## 1. 系统概述

历练系统是游戏中的核心战斗系统，采用**ATB（Active Time Battle，主动时间战斗）**机制，实现了回合制与实时制相结合的战斗体验。

**概念定义**：
- **历练 (Lianli)**：玩家进入历练区域进行的一系列战斗，直到主动退出或战败
- **战斗 (Battle)**：单次与敌人的对决，直到一方死亡
- 一次历练可以包含**多次战斗**

### 1.1 核心设计理念
- **ATB机制**：角色通过积累行动条（ATB）来触发行动，速度属性决定ATB积累速度
- **实时与回合结合**：战斗以固定频率（10次/秒）进行tick处理，模拟实时战斗
- **术法驱动**：战斗中的技能释放完全由装备的术法决定，包括主动攻击、被动buff等
- **气血系统**：采用"气血"作为生命值概念，区分当前气血和气血上限
- **连续战斗**：支持连续历练模式，战斗间隔3-5秒自动开始下一场

### 1.2 历练类型

| 类型 | 说明 | 特点 |
|------|------|------|
| **普通区域历练** | 炼气期/筑基期的外围/内围区域 | 可连续战斗，掉落灵石和术法 |
| **特殊区域历练** | 破境草洞穴等BOSS区域 | 单BOSS，通关后结束，特殊掉落 |
| **无尽塔** | 挑战无尽层数 | 51层上限，每5层奖励，无掉落 |

---

## 2. 系统架构

### 2.1 文件位置

```
/scripts/core/LianliSystem.gd          # 核心历练系统
/scripts/core/LianliAreaData.gd        # 历练区域数据
/scripts/core/EndlessTowerData.gd      # 无尽塔数据
/scripts/ui/modules/LianliModule.gd    # 历练UI模块
/scripts/ui/GameUI.gd                  # UI交互（历练相关部分）
```

### 2.2 核心常量定义

```gdscript
const ATB_MAX: float = 100.0              # ATB条最大值（满值100）
const TICK_INTERVAL: float = 0.1          # 每个tick的间隔时间（秒）
const DEFAULT_ENEMY_ATTACK: float = 50.0  # 默认敌人攻击
const PERCENTAGE_BASE: float = 100.0      # 百分比基数
```

> **数值规范**：历练系统所有数值计算使用 `float` 类型，UI显示时调用 `AttributeCalculator` 格式化函数。详见 [属性数值系统规范](../ATTRIBUTE_SYSTEM.md)。

### 2.3 主要数据结构

#### 2.3.1 历练状态
```gdscript
var is_in_lianli: bool = false           # 是否处于历练中（可能包含多场战斗）
var is_in_battle: bool = false           # 是否处于战斗中
var is_waiting: bool = false             # 是否处于连续历练的等待间隔
var lianli_speed: float = 1.0            # 历练倍速（1.0-2.0）

# 无尽塔状态
var is_in_tower: bool = false            # 是否处于无尽塔中
var current_tower_floor: int = 0         # 当前无尽塔层数

# 连续历练设置（由UI同步）
var continuous_lianli: bool = false      # 连续历练模式
```

#### 2.3.2 ATB战斗数据
```gdscript
var player_atb: float = 0.0              # 玩家ATB值（0-100）
var enemy_atb: float = 0.0               # 敌人ATB值（0-100）
var tick_accumulator: float = 0.0        # 时间累积器
```

#### 2.3.3 战斗中的临时buff系统

**数据来源**：战斗Buff作用于**动态最终属性**计算，详见 [属性数值系统规范](../ATTRIBUTE_SYSTEM.md) 第1.3节。

```gdscript
var combat_buffs: Dictionary = {
    "attack_percent": 0.0,   # 攻击加成百分比（小数，如0.25 = 25%）
    "defense_percent": 0.0,  # 防御加成百分比（小数）
    "speed_bonus": 0.0,      # 速度加成固定值（float）
    "health_bonus": 0.0      # 气血加成固定值（float）
}
```

---

## 3. 历练区域配置

### 3.1 普通区域

| 区域ID | 名称 | 境界要求 | 敌人种类 | 特点 |
|--------|------|----------|----------|------|
| `qi_refining_outer` | 炼气期外围森林 | 炼气期 | 野狼、毒蛇、野猪 | 适合新手，掉落1-2灵石 |
| `qi_refining_inner` | 炼气期内围山谷 | 炼气期 | 野狼、毒蛇、野猪、铁背狼王 | 有狼王，掉落术法 |
| `foundation_outer` | 筑基期外围荒原 | 筑基期 | 野狼、毒蛇、野猪 | 掉落3-6灵石 |
| `foundation_inner` | 筑基期内围沼泽 | 筑基期 | 野狼、毒蛇、野猪、铁背狼王 | 有狼王，掉落术法 |

### 3.2 特殊区域（BOSS）

| 区域ID | 名称 | 特点 | 通关奖励 |
|--------|------|------|----------|
| `foundation_herb_cave` | 破境草洞穴 | 单BOSS（破境草看守者），每日次数限制 | 破境草x10，灵石x20 |

### 3.3 无尽塔

- **层数上限**：51层
- **奖励层**：5, 10, 15, 20, 25, 30, 35, 40, 45, 50层
- **奖励内容**：灵石（10-170，随层数递增）
- **敌人**：随机模板（狼、蛇、野猪），等级=层数

---

## 4. 命名规范

### 4.1 变量命名规范

| 后缀 | 含义 | 数据类型 | 示例 |
|------|------|----------|------|
| `_percent` | 百分比加成（小数） | float | 0.25 表示 25% |
| `_bonus` | 固定数值加成 | float/int | 5.0 或 5 |
| `_chance` | 概率（小数） | float | 0.30 表示 30% |
| `_value` | 数值 | float/int | 100.0 |
| `_id` | 标识符 | String | "enemy_001" |
| `_data` | 数据字典 | Dictionary | {...} |

### 4.2 状态变量命名

```gdscript
is_in_lianli      # 是否在历练中
is_in_battle      # 是否在战斗中
is_waiting        # 是否在等待中
is_in_tower       # 是否在无尽塔中
is_elite          # 是否为精英敌人
```

### 4.3 函数命名规范

```gdscript
# 开始/结束动作
start_lianli_in_area()    # 开始历练（进入区域）
start_next_battle()       # 开始下一场战斗
start_battle()            # 开始一场战斗
start_endless_tower()     # 开始无尽塔
end_lianli()              # 结束历练
end_battle()              # 结束战斗

# 处理函数（内部）
_process_atb_tick()       # 处理ATB tick
_execute_player_action()  # 执行玩家行动
_execute_enemy_action()   # 执行敌人行动
_trigger_start_spells()   # 触发开局被动术法
_handle_battle_victory()  # 处理战斗胜利
_handle_battle_defeat()   # 处理战斗失败
_handle_tower_victory()   # 处理无尽塔胜利
```

---

## 5. 主体逻辑

### 5.1 状态机模型

```
┌─────────────────────────────────────────────────────────────┐
│                        空闲状态                              │
│                   (is_in_lianli = false)                    │
└─────────────────────────────────────────────────────────────┘
                              │
           start_lianli_in_area() / start_endless_tower()
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        历练中                                │
│                   (is_in_lianli = true)                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   等待中    │◄──►│   战斗中    │◄──►│   战斗结束  │     │
│  │(is_waiting) │    │(is_in_battle)│    │             │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                    end_lianli() / 战败
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        空闲状态                              │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 历练生命周期

```
进入历练区域
    ↓
start_lianli_in_area(area_id) / start_endless_tower()
    ↓
发送 lianli_started 信号
    ↓
开始第一场战斗 → start_next_battle() / _start_tower_battle()
    ↓
[战斗循环]
    ↓
战斗胜利？
    ├── 是 → 发放奖励 → continuous_lianli？
    │              ├── 是 → 等待3-5秒 → 开始下一场
    │              └── 否 → end_lianli() → 历练结束
    └── 否 → end_lianli() → 历练结束
```

### 5.3 战斗生命周期

```
开始战斗 (start_battle)
    ↓
初始化战斗数据（ATB归零，敌人数据）
    ↓
触发开局被动术法 (_trigger_start_spells)
    ↓
发送 battle_started 信号
    ↓
进入战斗主循环 (_process)
    ↓
ATB积累 → 满值判定 → 行动执行
    ↓
检查战斗结束条件
    ↓
战斗结束 → _handle_battle_victory() / _handle_battle_defeat()
    ↓
恢复气血buff → 发送 battle_ended 信号
```

### 5.4 连续战斗机制

**状态同步流程**：
```
UI复选框 (continuous_checkbox)
    │
    │ on_continuous_toggled(enabled)
    ▼
LianliModule.on_continuous_toggled()
    │
    │ lianli_system.set_continuous_lianli(enabled)
    ▼
LianliSystem.continuous_lianli = enabled
```

**战斗结束时的判断**：
```gdscript
# 在 _handle_battle_victory() 中
if continuous_lianli and is_in_lianli:
    # 进入等待状态，准备下一场战斗
    is_waiting = true
    wait_timer = 0.0
    current_wait_interval = get_wait_interval()
else:
    # 非连续战斗模式，结束历练
    is_in_lianli = false
    end_lianli()
```

**默认勾选状态**：
- 普通区域：默认勾选
- 无尽塔：默认不勾选
- 特殊区域（破境草洞穴）：隐藏复选框

### 5.5 ATB机制详解

#### 5.5.1 ATB增长公式
```gdscript
# 每0.1秒执行一次tick计算（双方都要受倍速影响）
player_atb += player_speed * lianli_speed
enemy_atb += enemy_speed * lianli_speed
```

**说明**：
- **玩家ATB**：增长速度 = 玩家速度 × 历练倍速
- **敌人ATB**：增长速度 = 敌人速度 × 历练倍速
- **倍速效果**：2倍速时，双方ATB增长速度都翻倍，战斗节奏加快

#### 5.5.2 ATB满值判定
```gdscript
# ATB满值为100
if player_atb >= ATB_MAX:
    _execute_player_action()
    player_atb -= ATB_MAX  # 归零并保留溢出
```

**溢出保留机制**：
- 行动后ATB减去100，保留超出部分
- 例如：ATB=110时行动，行动后ATB=10
- 确保速度优势能延续到下一回合

#### 5.5.3 ATB同时满值行动优先级

当玩家和敌人在同一tick达到满值时，按以下优先级判定行动顺序：

```gdscript
if player_ready and enemy_ready:
    # 同时达到满值
    if player_speed > enemy_speed:
        # 玩家速度快，玩家先行动
        _execute_player_action()
        if 敌人仍然存活:
            _execute_enemy_action()
    elif enemy_speed > player_speed:
        # 敌人速度快，敌人先行动
        _execute_enemy_action()
        if 玩家仍然存活:
            _execute_player_action()
    else:
        # 速度相同，玩家优先
        _execute_player_action()
        if 敌人仍然存活:
            _execute_enemy_action()
```

**优先级规则**：
1. **速度快者优先**：速度高的角色先行动
2. **速度相同，玩家优先**：平局时玩家获得先手优势
3. **连续行动检查**：一方行动后，检查对方是否仍然存活才执行对方行动

---

## 6. 伤害机制

### 6.1 基础伤害计算

**数据来源**：使用**动态最终属性**计算，详见 [属性数值系统规范](../ATTRIBUTE_SYSTEM.md) 第1.4节。

```gdscript
func calculate_damage(attack: float, defense: float) -> float
```
**公式**：
```
damage = max(1.0, attack - defense)
```
**说明**：
- 伤害至少为1.0（保底伤害机制）
- 纯减法公式，防御直接抵消攻击
- 返回 `float` 类型，UI显示时使用 `format_damage()` 格式化

**显示规则**：
- 伤害值 ≤ 1000：`format_one_decimal()`（保留一位小数）
- 伤害值 > 1000：`format_integer()`（保留整数）

### 6.2 术法伤害计算
```gdscript
# 触发了攻击术法
var damage_percent = effect.get("damage_percent", 1.0)  # 如1.30表示130%
var attack_buff_percent = combat_buffs.get("attack_percent", 0.0)

# 最终攻击力 = 基础攻击 × (1+攻击buff) × 术法伤害百分比
var final_attack = player_attack * (1.0 + attack_buff_percent) * damage_percent
var damage_to_enemy = calculate_damage(final_attack, enemy_defense)
```

### 6.3 伤害计算流程图
```
玩家攻击
    ↓
获取术法触发结果 (trigger_attack_spell)
    ↓
是否触发术法？
    ├── 是 → 使用术法伤害倍率
    │         ↓
    │      计算: attack × (1 + buff) × damage_percent - defense
    │
    └── 否 → 使用普通攻击
              ↓
           计算: attack × (1 + buff) - defense
    ↓
保底处理: max(1, damage)
    ↓
扣除敌人气血并检查死亡
```

---

## 7. 战斗Buff系统

### 7.1 Buff类型
```gdscript
var combat_buffs: Dictionary = {
    "attack_percent": 0.0,   # 攻击加成百分比（小数，如0.25 = 25%）
    "defense_percent": 0.0,  # 防御加成百分比（小数）
    "speed_bonus": 0.0,      # 速度加成固定值（float）
    "health_bonus": 0.0      # 气血加成固定值（float）
}
```

### 7.2 Buff生效机制

**数据来源**：战斗Buff作用于**动态最终属性**计算，详见 [属性数值系统规范](../ATTRIBUTE_SYSTEM.md) 第1.3节。

**开局触发**：
- 被动术法（PASSIVE类型）在战斗开始时自动触发
- 通过 `_trigger_start_spells()` 函数执行

**Buff应用**（全程float计算）：
```gdscript
# 攻击buff（百分比乘法）
combat_attack = final_attack * (1.0 + combat_buffs.attack_percent)

# 防御buff（百分比乘法）
combat_defense = final_defense * (1.0 + combat_buffs.defense_percent)

# 速度buff（固定值加法）
combat_speed = final_speed + combat_buffs.speed_bonus

# 气血buff（固定值加法）
combat_max_health = final_max_health + combat_buffs.health_bonus
```

**说明**：
- `final_xxx` 是静态最终属性（来自 AttributeCalculator）
- `combat_xxx` 是动态最终属性（用于战斗计算）
- 所有计算使用 `float` 类型，不截断

### 7.3 气血Buff特殊机制

#### 7.3.1 战斗开始时应用
```gdscript
# 基础气血术法效果
var health_percent = effect_data.get("buff_percent", 0.0)
var bonus_health = int(player.max_health * health_percent)

# 同时增加气血上限和当前气血
combat_buffs.health_bonus += bonus_health
player.max_health += bonus_health
player.health += bonus_health
```

#### 7.3.2 战斗结束后恢复
```gdscript
func _restore_health_after_combat():
    if player and combat_buffs.get("health_bonus", 0.0) > 0:
        var health_bonus = int(combat_buffs.health_bonus)
        
        # 减少气血上限
        player.max_health -= health_bonus
        
        # 当前气血调整
        if player.health >= player.max_health:
            player.health = player.max_health
        # 否则保持当前值不变（保留战斗中恢复的气血）
```

**机制说明**：
- 气血buff是**临时性**的，只在当前战斗生效
- 战斗结束后移除上限加成，当前气血可能因此下降
- 如果当前气血低于上限，则保持不变（保留战斗中恢复的部分）

---

## 8. 战斗结束处理

### 8.1 战斗胜利 (_handle_battle_victory)

#### 8.1.1 胜利条件
- 敌人气血降至0或以下
- 在 `_process_atb_tick()` 中检查

#### 8.1.2 胜利处理流程

```
战斗胜利
    ↓
is_in_battle = false
    ↓
恢复气血buff
    ↓
生成战利品
    ↓
发送 battle_ended 信号
    ↓
判断历练类型
    ├── 无尽塔 → _handle_tower_victory()
    │              ├── 更新最高层数
    │              ├── 发放奖励层奖励
    │              ├── 达到51层？ → end_lianli()
    │              └── continuous_lianli？ → 等待下一层 / end_lianli()
    │
    ├── 特殊区域 → 消耗每日次数
    │              ├── continuous_lianli + 剩余次数 > 0？ → 等待下一场
    │              └── 否则 → end_lianli()
    │
    └── 普通区域 → continuous_lianli？
                   ├── 是 → 等待下一场
                   └── 否 → end_lianli()
```

#### 8.1.3 战利品生成规则

**特殊区域掉落**（破境草洞穴）：
```gdscript
if is_single_boss_area(current_area_id):
    loot = [
        {"item_id": "foundation_herb", "amount": 10},  # 破境草
        {"item_id": "spirit_stone", "amount": 20}      # 灵石
    ]
```

**普通敌人掉落**：
- 通过敌人配置中的 `drops` 字段生成
- 支持概率掉落（`chance` 字段）
- 数量范围（`min`, `max`）

**无尽塔奖励**：
- 无战斗掉落
- 每5层通关时发放奖励层奖励

### 8.2 战斗失败 (_handle_battle_defeat)

#### 8.2.1 失败条件
- 玩家气血降至0或以下
- 在 `_process_atb_tick()` 中检查

#### 8.2.2 失败处理流程
```gdscript
func _handle_battle_defeat():
    # 恢复气血buff
    _restore_health_after_combat()
    
    # 根据历练类型输出不同日志
    if is_in_tower:
        log_message.emit("无尽塔挑战结束，最高到达第" + str(current_tower_floor) + "层")
    else:
        log_message.emit("气血不足，历练结束")
    
    # 发送战斗结束信号
    battle_ended.emit(false, [], current_enemy.get("name", ""))
    
    # 统一调用 end_lianli() 清理状态
    end_lianli()
```

#### 8.2.3 失败后果
- 战斗立即结束
- 历练被中断（连续历练停止）
- 无战利品获得
- 气血保持战斗结束时的状态（需手动恢复）

### 8.3 状态清理 (end_lianli)

**统一清理函数**，所有退出历练的场景都调用此函数：

```gdscript
func end_lianli():
    is_in_lianli = false
    is_in_battle = false
    is_waiting = false
    is_in_tower = false
    current_tower_floor = 0
    current_enemy = {}
    tick_accumulator = 0.0
    _restore_health_after_combat()
    _reset_combat_buffs()
    _cached_spell_system = null
    lianli_ended.emit(false)
```

**注意**：`continuous_lianli` 不会被重置，保留用户的勾选状态。

### 8.4 战斗结算流程图
```
战斗进行中
    ↓
攻击/被攻击后检查气血
    ↓
敌人气血 <= 0？
    ├── 是 → _handle_battle_victory()
    │         ↓
    │      恢复气血buff
    │      生成战利品
    │      发放奖励（通过lianli_reward信号）
    │      判断是否继续历练
    │
    └── 否 → 玩家气血 <= 0？
              ├── 是 → _handle_battle_defeat()
              │         ↓
              │      恢复气血buff
              │      发送失败信号
              │      end_lianli()
              │
              └── 否 → 继续战斗
```

---

## 9. 无尽塔系统

### 9.1 基本规则

- **层数上限**：51层（MAX_FLOOR）
- **起始层数**：玩家最高通关层数 + 1（不超过51层）
- **敌人生成**：随机模板（狼、蛇、野猪），等级 = 当前层数
- **奖励机制**：每5层发放灵石奖励

### 9.2 奖励层配置

| 层数 | 奖励 |
|------|------|
| 5 | 10灵石 |
| 10 | 15灵石 |
| 15 | 20灵石 |
| 20 | 30灵石 |
| 25 | 40灵石 |
| 30 | 55灵石 |
| 35 | 75灵石 |
| 40 | 100灵石 |
| 45 | 130灵石 |
| 50 | 170灵石 |

### 9.3 无尽塔流程

```
进入无尽塔
    ↓
start_endless_tower()
    ↓
生成第N层敌人（等级=N）
    ↓
开始战斗
    ↓
战斗胜利
    ↓
检查是否是奖励层 → 发放奖励
    ↓
检查是否达到51层 → end_lianli()
    ↓
continuous_lianli？
    ├── 是 → 等待下一层
    └── 否 → end_lianli()
```

### 9.4 关键函数

```gdscript
start_endless_tower() -> bool           # 开始无尽塔挑战
_start_tower_battle() -> bool           # 开始无尽塔的一场战斗
_handle_tower_victory()                 # 处理无尽塔战斗胜利
continue_tower_next_floor() -> bool     # 继续下一层（手动）
start_wait_for_next_battle() -> bool    # 开始等待下一场
exit_tower()                            # 退出无尽塔
get_current_tower_floor() -> int        # 获取当前层数
is_in_endless_tower() -> bool           # 检查是否在无尽塔中
get_current_enemy_drops() -> Dictionary # 获取当前敌人掉落
```

---

## 10. 与其他系统的联动

### 10.1 与术法系统的联动

#### 10.1.1 开局被动触发
```gdscript
func _trigger_start_spells()
```
- 获取所有已装备的被动术法（PASSIVE类型）
- 执行每个被动术法的效果（添加buff）
- 发送战斗日志信号

#### 10.1.2 玩家攻击时触发主动术法
```gdscript
GameManager.spell_system.trigger_attack_spell()
```
- 返回触发结果（是否触发、术法ID、伤害倍率等）
- 用于计算术法伤害

### 10.2 与修炼系统的联动

#### 10.2.1 属性读取
```gdscript
player.health
player.max_health
player.attack
player.defense
player.speed
```

#### 10.2.2 气血修改
```gdscript
player.health = new_health
player.max_health = new_max_health
```

### 10.3 与物品系统的联动

#### 10.3.1 战斗奖励发放
```gdscript
# 通过信号通知物品系统
signal lianli_reward(item_id: String, amount: int, source: String)

# 在 _handle_battle_victory 中
lianli_reward.emit(item_id, amount, "lianli")   # 普通历练
lianli_reward.emit(item_id, amount, "tower")    # 无尽塔奖励
```

**重要**：历练系统只负责发出信号，不直接操作物品系统！

### 10.4 与UI系统的联动

#### 10.4.1 信号定义

> **数值类型**：所有血量、伤害数值均使用 `float` 类型，详见 [属性数值系统规范](../ATTRIBUTE_SYSTEM.md) 第4.2节。

```gdscript
# 历练相关信号
signal lianli_started(area_id: String)                                    # 历练开始（进入区域）
signal lianli_ended(victory: bool)                                        # 历练结束
signal lianli_waiting(time_remaining: float)                              # 连续历练等待

# 战斗相关信号
signal battle_started(enemy_name: String, is_elite: bool, enemy_max_health: float, enemy_level: int, player_max_health: float)  # 战斗开始
signal battle_action_executed(is_player: bool, damage: float, is_spell: bool, spell_name: String)  # 行动执行
signal battle_updated(player_atb: float, enemy_atb: float, player_health: float, enemy_health: float, player_max_health: float, enemy_max_health: float)  # 状态更新
signal battle_ended(victory: bool, loot: Array, enemy_name: String)       # 战斗结束

# 其他信号
signal lianli_reward(item_id: String, amount: int, source: String)
signal log_message(message: String)  # 历练日志信号
```

**UI显示规则**：
- 血条显示：`format_integer()`（保留整数）
- 伤害显示：`format_damage()`（≤1000保留一位小数，>1000保留整数）

#### 10.4.2 信号触发时机
- `lianli_started`: 进入历练区域时
- `battle_started`: 单场战斗开始时
- `battle_action_executed`: 每次行动后（玩家或敌人）
- `battle_updated`: 每次行动后（用于UI刷新）
- `battle_ended`: 单场战斗结束时
- `lianli_ended`: 历练完全结束时
- `lianli_waiting`: 连续历练等待期间（每帧更新）
- `log_message`: 发生重要事件时

#### 10.4.3 UI层职责

**LianliModule 负责**：
- 显示战斗场景（血条、ATB条、敌人信息）
- 同步连续战斗复选框状态到 LianliSystem
- 处理继续战斗按钮
- 接收 `lianli_reward` 信号，调用 `inventory.add_item()`
- 更新储纳UI显示

**注意**：UI层不直接控制历练逻辑，只通过信号与LianliSystem通信！

---

## 11. 关键函数索引

### 11.1 公共接口

| 函数名 | 参数 | 返回值 | 说明 |
|--------|------|--------|------|
| `start_lianli_in_area` | `area_id: String` | `bool` | 开始历练（进入区域）|
| `start_next_battle` | 无 | `bool` | 开始下一场战斗 |
| `start_battle` | `enemy_data_dict: Dictionary` | `bool` | 开始一场战斗 |
| `start_endless_tower` | 无 | `bool` | 开始无尽塔挑战 |
| `end_lianli` | 无 | `void` | 结束历练（完全退出）|
| `end_battle` | `victory: bool` | `void` | 结束当前战斗 |
| `set_lianli_speed` | `speed: float` | `void` | 设置历练倍速（1.0-2.0）|
| `set_continuous_lianli` | `enabled: bool` | `void` | 设置连续历练模式 |
| `get_current_tower_floor` | 无 | `int` | 获取当前无尽塔层数 |
| `is_in_endless_tower` | 无 | `bool` | 检查是否在无尽塔中 |
| `get_current_enemy_drops` | 无 | `Dictionary` | 获取当前敌人掉落配置 |
| `start_wait_for_next_battle` | 无 | `bool` | 开始等待下一场战斗 |
| `continue_tower_next_floor` | 无 | `bool` | 继续无尽塔下一层 |
| `exit_tower` | 无 | `void` | 退出无尽塔 |
| `get_spell_system` | 无 | `Node` | 获取术法系统（带缓存）|

### 11.2 内部函数

| 函数名 | 说明 |
|--------|------|
| `_process_atb_tick` | 处理单次ATB tick，增长ATB并判定行动 |
| `_execute_player_action` | 执行玩家行动（普通攻击或术法）|
| `_execute_enemy_action` | 执行敌人行动（普通攻击）|
| `_trigger_start_spells` | 触发开局被动术法 |
| `_handle_battle_victory` | 处理战斗胜利及奖励发放 |
| `_handle_battle_defeat` | 处理战斗失败 |
| `_handle_tower_victory` | 处理无尽塔战斗胜利 |
| `_restore_health_after_combat` | 战斗后恢复气血buff |
| `_start_tower_battle` | 开始无尽塔的一场战斗 |
| `_reset_combat_buffs` | 重置战斗buff |

---

## 12. 扩展指南

### 12.1 添加新的Buff类型

1. 在 `combat_buffs` 中添加新字段
2. 在 `_trigger_start_spells` 中应用新buff
3. 在 `_restore_health_after_combat` 中处理新buff的清理
4. 在被动术法效果中配置新buff

### 12.2 修改伤害公式

编辑 `calculate_damage` 函数：
```gdscript
func calculate_damage(attack: float, defense: float) -> int:
    # 自定义伤害公式
    var damage = attack * attack / (attack + defense)
    return max(1, int(damage))
```

### 12.3 添加敌人技能

扩展 `_execute_enemy_action`：
```gdscript
func _execute_enemy_action():
    # 敌人技能判定
    if should_use_skill():
        execute_enemy_skill()
    else:
        # 原有普通攻击逻辑
```

### 12.4 添加新的历练区域

在 `LianliAreaData.gd` 中添加：
```gdscript
"new_area_id": {
    "name": "新区域名称",
    "description": "区域描述",
    "enemies": [
        {
            "template": "enemy_template",
            "min_level": 1, "max_level": 10, "weight": 50,
            "drops": {
                "spirit_stone": {"min": 1, "max": 5, "chance": 1.0},
                "item_id": {"min": 1, "max": 1, "chance": 0.1}
            }
        }
    ]
}
```

---

## 13. 注意事项

1. **ATB溢出处理**：行动后ATB减去ATB_MAX（100），保留溢出部分，确保速度优势能延续到下一回合
2. **保底伤害**：所有伤害计算最终都经过 `max(1, ...)` 处理，确保攻击不会完全无效
3. **气血buff同步**：气血加成同时影响当前气血和气血上限，避免加成后当前气血比例下降
4. **战斗后恢复**：buff带来的气血加成在战斗结束后移除，当前气血可能因此下降
5. **倍速影响**：历练倍速影响双方ATB增长速度，加快整体战斗节奏
6. **同时满值判定**：速度相同情况下玩家优先，给予玩家先手优势
7. **历练vs战斗**：注意区分历练（可能多场战斗）和单场战斗的概念
8. **物品掉落提示**：历练系统通过 `lianli_reward` 信号通知物品掉落，**不负责在富文本框中提示物品获取**。物品进入储纳后，由储纳系统（Inventory）负责显示获取提示。
9. **连续战斗状态**：连续战斗状态由UI层同步到LianliSystem，在战斗结束时根据 `continuous_lianli` 决定是否继续历练。
10. **无尽塔上限**：无尽塔最高51层，达到后自动结束挑战
11. **特殊区域**：破境草洞穴为单BOSS区域，有每日次数限制，通关后消耗次数
12. **状态清理**：所有退出历练的场景都调用 `end_lianli()` 统一清理状态

---

## 14. 版本历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| 1.0 | 2026-02-21 | 初始文档 |
| 1.1 | 2026-02-21 | 区分历练与战斗概念、更新命名规范、ATB机制优化 |
| 1.2 | 2026-02-23 | 重构连续战斗机制、添加无尽塔系统、添加特殊区域说明 |
| 1.3 | 2026-03-01 | 重构状态管理：统一 `end_lianli()` 清理逻辑、删除废弃变量 `tower_continuous`、合并 `_handle_tower_defeat()`、更新连续战斗同步机制 |
