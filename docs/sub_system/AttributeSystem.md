# 属性数值系统规范

**文档版本**: 1.0  
**创建日期**: 2026-02-24  
**适用范围**: Godot 4.6 + GDScript

---

## 1. 属性层级体系

### 1.1 基础属性 (Base Attributes)

存储位置: `PlayerData.gd`

| 属性名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| `health` | `float` | 当前气血 | 0 ≤ health ≤ final_max_health |
| `spirit_energy` | `float` | 当前灵气 | 0 ≤ spirit_energy ≤ final_max_spirit |
| `base_max_health` | `float` | 基础气血上限 | 随境界提升而变化 |
| `base_max_spirit` | `float` | 基础灵气上限 | 随境界提升而变化 |
| `base_attack` | `float` | 基础攻击 | 随境界提升而变化 |
| `base_defense` | `float` | 基础防御 | 随境界提升而变化 |
| `base_speed` | `float` | 基础速度 | 随境界提升而变化 |
| `base_spirit_gain` | `float` | 基础灵气获取速度 | 随境界提升而变化 |

**注意**: 
- `health` 和 `spirit_energy` 的上限是**静态最终属性**的计算值，不是基础属性
- 所有基础属性都应该是 `float` 类型

---

### 1.2 静态最终属性 (Static Final Attributes)

计算位置: `AttributeCalculator.gd`

**计算方式**: 基础属性 + 术法属性加成

| 属性名 | 计算函数 | 返回类型 | 说明 |
|--------|---------|---------|------|
| `final_max_health` | `calculate_final_max_health()` | `float` | 最终气血上限 |
| `final_max_spirit` | `calculate_final_max_spirit()` | `float` | 最终灵气上限 |
| `final_attack` | `calculate_final_attack()` | `float` | 最终攻击 |
| `final_defense` | `calculate_final_defense()` | `float` | 最终防御 |
| `final_speed` | `calculate_final_speed()` | `float` | 最终速度 |
| `final_spirit_gain` | `calculate_final_spirit_gain()` | `float` | 最终灵气获取速度 |

**使用场景**:
- 内视页面属性展示
- 修炼系统（灵气增长、气血恢复）
- 非战斗状态下的所有计算

---

### 1.3 战斗Buff属性 (Combat Buffs)

存储位置: `LianliSystem.gd` 中的 `combat_buffs` 字典

| Buff类型 | 类型 | 说明 |
|---------|------|------|
| `attack_percent` | `float` | 攻击加成百分比（如 0.25 = 25%） |
| `defense_percent` | `float` | 防御加成百分比 |
| `speed_bonus` | `float` | 速度加成固定值 |
| `health_bonus` | `float` | 气血加成固定值 |

---

### 1.4 动态最终属性 (Combat Final Attributes)

计算位置: `AttributeCalculator.gd`

**计算方式**: 静态最终属性 + 战斗Buff

| 属性名 | 计算函数 | 返回类型 |
|--------|---------|---------|
| `combat_max_health` | `calculate_combat_max_health()` | `float` |
| `combat_attack` | `calculate_combat_attack()` | `float` |
| `combat_defense` | `calculate_combat_defense()` | `float` |
| `combat_speed` | `calculate_combat_speed()` | `float` |

**使用场景**:
- 战斗系统中的伤害计算
- 战斗场景UI显示

---

### 1.5 伤害计算

**公式**: 
```gdscript
damage = max(1.0, combat_attack - combat_defense)
```

**说明**:
- 输入: 动态最终属性（`float`）
- 输出: 伤害值（`float`）
- 最小伤害: 1.0

---

## 2. UI显示规则

### 2.1 通用格式化函数

所有系统内部计算使用 `float`，UI显示时统一调用格式化函数。

#### 基础格式化函数

```gdscript
# 保留两位小数，去除尾0
# 1.50 -> "1.5", 2.00 -> "2", 1.05 -> "1.05"
static func format_default(value: float) -> String

# 百分比显示：乘100，保留两位小数，去除尾0，加%
# 0.15 -> "15%", 0.005 -> "0.5%"
static func format_percent(value: float) -> String

# 保留一位小数，去除尾0
# 50.5 -> "50.5", 50.0 -> "50"
static func format_one_decimal(value: float) -> String

# 保留整数
# 255.7 -> "256"
static func format_integer(value: float) -> String
```

---

### 2.2 内视页面显示规则

**数据来源**: 静态最终属性

| 属性 | 显示规则 | 调用函数 |
|------|---------|---------|
| 攻击/防御 | ≤1000保留一位小数，>1000保留整数 | 自定义逻辑 |
| 速度/灵气获取 | 保留两位小数，去尾0 | `format_default()` |
| 气血/灵气 | 保留整数 | `format_integer()` |
| 气血上限/灵气上限 | 保留整数 | `format_integer()` |

**攻击/防御的自定义逻辑实现**:
```gdscript
func format_attack_defense(value: float) -> String:
    if value <= 1000:
        return format_one_decimal(value)
    else:
        return format_integer(value)
```

---

### 2.3 战斗场景显示规则

**数据来源**: 动态最终属性

| 元素 | 显示规则 | 调用函数 |
|------|---------|---------|
| 玩家/敌人血条（当前气血） | 保留整数 | `format_integer()` |
| 玩家/敌人血条（气血上限） | 保留整数 | `format_integer()` |
| 富文本框-伤害值 | ≤1000保留一位小数，>1000保留整数 | 自定义逻辑 |
| 富文本框-Buff百分比 | 百分比显示 | `format_percent()` |
| 富文本框-Buff固定值 | 保留两位小数，去尾0 | `format_default()` |

**伤害值的自定义逻辑实现**:
```gdscript
func format_damage(value: float) -> String:
    if value <= 1000:
        return format_one_decimal(value)
    else:
        return format_integer(value)
```

---

### 2.4 术法系统UI显示规则

**数据来源**: `SpellData.gd` 中的术法配置

#### 2.4.1 术法列表面板显示

| 元素 | 显示规则 | 调用函数 |
|------|---------|---------|
| 术法属性加成（攻击/防御/速度等） | 保留两位小数，去尾0 | `format_default()` |
| 装备数量/上限 | 保留整数 | `format_integer()` |

#### 2.4.2 术法详情面板显示

**效果数值显示规则**:

| 效果类型 | 显示规则 | 示例 |
|---------|---------|------|
| 百分比效果（damage_percent, buff_percent, heal_percent等） | 百分比显示 | 1.10 → "110%", 0.15 → "15%", 0.002 → "0.2%" |
| 概率效果（trigger_chance） | 百分比显示 | 0.30 → "30%" |

**术法描述占位符替换规则**:
```gdscript
# 在 ui_utils.gd 中的 format_spell_description 函数
# {damage_percent} -> format_percent(damage_percent)  -> "110%"
# {buff_percent} -> format_percent(buff_percent)      -> "15%"
# {trigger_chance} -> format_percent(trigger_chance)  -> "30%"
# {heal_percent} -> format_percent(heal_percent)      -> "0.2%"
```

**注意**: 
- `heal_percent` 表示恢复最大气血的百分比（如 0.002 = 0.2%）
- 所有百分比数值在显示时都使用 `format_percent()` 函数

**实现位置**: `scripts/utils/ui_utils.gd`

---

## 3. 境界系统配置

### 3.1 速度属性配置

速度属性配置在大境界的最外层，所有大境界的速度统一为 **5**。

```gdscript
"炼气期": {
    "max_level": 10,
    "levels": { ... },
    "speed": 5,  # 所有炼气期层数共享此速度
    "spirit_gain_speed": 1
}
```

**说明**:
- 炼气期一层到十层，速度都是 5
- 筑基期一层到十层，速度也都是 5
- 所有境界的速度都是 5（后续可根据需要调整）

---

## 4. 系统使用规范

### 4.1 计算系统使用原则

1. **所有系统内部计算使用 `float`**
2. **UI显示时才调用格式化函数转换为字符串**
3. **不要在计算过程中使用 `int()` 截断**

### 4.2 各系统使用属性层级

| 系统 | 使用属性层级 | 说明 |
|------|-------------|------|
| 修炼系统 | 静态最终属性 | 灵气增长、气血恢复 |
| 内视页面 | 静态最终属性 | 属性展示 |
| 战斗系统 | 动态最终属性 | 伤害计算、战斗逻辑 |
| 战斗UI | 动态最终属性 | 血条、伤害显示 |

---

## 5. 文件修改清单

### 5.1 需要修改的文件

1. **PlayerData.gd**
   - 所有属性改为 `float`
   - `health` 上限检查使用 `final_max_health`
   - `spirit_energy` 上限检查使用 `final_max_spirit`

2. **AttributeCalculator.gd**
   - 所有计算函数返回 `float`
   - 添加通用格式化函数

3. **LianliSystem.gd**
   - 伤害计算全程 `float`
   - 信号参数改为 `float`
   - 战斗Buff使用 `float`

4. **CultivationSystem.gd**
   - 气血恢复使用 `float`

5. **RealmSystem.gd**
   - ✅ 已添加速度属性

6. **各UI模块**
   - 内视页面使用静态最终属性 + 对应显示规则
   - 战斗页面使用动态最终属性 + 对应显示规则

---

## 6. 存档系统规范

### 6.1 存档数值格式

**所有属性相关的数值，存档时保留4位小数，去除尾0**。

#### 存档格式化函数

```gdscript
# 保留4位小数，去除尾0
# 50.5000 -> "50.5", 100.0000 -> "100", 0.0020 -> "0.002"
static func format_for_save(value: float) -> String:
    var formatted = "%.4f" % value
    # 去除尾0
    while formatted.find(".") != -1 and formatted.ends_with("0"):
        formatted = formatted.substr(0, formatted.length() - 1)
    # 去除末尾的小数点
    if formatted.ends_with("."):
        formatted = formatted.substr(0, formatted.length() - 1)
    return formatted
```

### 6.2 存档数据结构

```json
{
    "player": {
        "health": "500",                    # 保留4位小数，去尾0
        "spirit_energy": "0",
        "base_max_health": "500",
        "base_max_spirit": "100",
        "base_attack": "50",
        "base_defense": "25",
        "base_speed": "10",
        "base_spirit_gain": "1",
        "realm": "炼气期",
        "realm_level": 1,
        "level": 1
    },
    "inventory": { ... },
    "task_system": { ... },
    "offline_reward": { ... },
    "timestamp": 1234567890,
    "version": "1.2"
}
```

### 6.3 需要修改的文件

1. **SaveManager.gd**
   - 保存时调用 `format_for_save()` 格式化数值
   - 加载时将数值转换为 `float`

2. **PlayerData.gd**
   - `get_save_data()` - 保存时格式化数值
   - `apply_save_data()` - 加载时转换为 float

---

## 7. 完整修改清单（汇总）

### P0 - 核心属性系统

| 文件 | 修改内容 |
|------|---------|
| PlayerData.gd | 属性改为 float，health上限使用 final_max_health |
| AttributeCalculator.gd | 计算函数返回 float，添加格式化函数 |
| LianliSystem.gd | 伤害计算 float，信号参数 float，战斗Buff float |
| CultivationSystem.gd | 气血恢复使用 float |

### P1 - UI显示系统

| 文件 | 修改内容 |
|------|---------|
| GameUI.gd / 各Module | 使用格式化函数显示属性 |
| SpellModule.gd | 术法属性使用 format_default() |
| ui_utils.gd | 更新 format_spell_description() |

### P2 - 存档系统

| 文件 | 修改内容 |
|------|---------|
| SaveManager.gd | 保存时保留4位小数，加载时转 float |
| PlayerData.gd | get_save_data() / apply_save_data() |

### P3 - 其他

| 文件 | 修改内容 |
|------|---------|
| RealmSystem.gd | ✅ 已添加速度属性 |
| SpellData.gd | 可能需要调整数值精度 |

---

**文档版本**: 1.1  
**更新日期**: 2026-02-24
