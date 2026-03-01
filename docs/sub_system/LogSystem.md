# 日志系统规范文档

## 1. 概述

日志系统负责统一管理游戏中的所有消息输出，分为**系统消息**和**战斗消息**两种类型。

## 2. 日志类型

### 2.1 系统消息 (SYSTEM)
- **标签**: `[系统]`
- **用途**: 游戏状态、操作结果、系统提示
- **示例**: 突破成功、获得物品、存档成功

### 2.2 战斗消息 (BATTLE)
- **标签**: `[战斗]`
- **用途**: 战斗过程、伤害数值、历练结果
- **示例**: 造成伤害、通关层数、战斗胜利

## 3. 日志规范

### 3.1 格式规范

```
[HH:MM:SS][类型] 消息内容
```

**示例:**
```
[21:37:13][系统] 开始修炼，灵气积累中...
[21:37:15][战斗] 战斗开始，使用基础防御，防御提升15%
```

### 3.2 内容规范

| 场景 | 类型 | 格式示例 |
|------|------|----------|
| 开始修炼 | SYSTEM | `开始修炼，灵气积累中...` |
| 停止修炼 | SYSTEM | `停止修炼` |
| 突破成功 | SYSTEM | `升至第X层！气血值已恢复满！` |
| 突破失败 | SYSTEM | `突破失败：原因` |
| 气血不足 | SYSTEM | `气血不足，无法进入区域名` |
| 战斗开始 | BATTLE | `战斗开始，使用术法名，效果描述` |
| 造成伤害 | BATTLE | `对敌人造成了X点伤害` |
| 通关层数 | BATTLE | `通关第X层` |
| 获得物品 | SYSTEM | `获得物品: 物品名 x数量` |

### 3.3 高亮规则

**颜色代码对照表:**

| 颜色名称 | 十六进制代码 | 用途 |
|---------|-------------|------|
| 深金色 | `#B8860B` | 灵石、离线总计时间 |
| 柔和青色 | `#5F9EA0` | 灵气 |
| 柔和绿色 | `#6B8E23` | 成功 |
| 柔和红色 | `#CD5C5C` | 失败、造成了、点伤害 |

**系统消息高亮:**
- `灵石` → `#B8860B` (深金色)
- `灵气` → `#5F9EA0` (柔和青色)
- `成功` → `#6B8E23` (柔和绿色)
- `失败` → `#CD5C5C` (柔和红色)
- `离线总计时间` → `#B8860B` (深金色)

**战斗消息高亮:**
- `造成了` → `#CD5C5C` (柔和红色)
- `点伤害` → `#CD5C5C` (柔和红色)
- `成功` → `#6B8E23` (柔和绿色)
- `失败` → `#CD5C5C` (柔和红色)

**注意:** 
- 战斗消息中只高亮 `"成功"` 和 `"失败"` 关键字，`"历练"` 和 `"通关"` 不高亮
- 灵石和灵气的高亮包含其后的数字（如 `"灵石 100"` 整体高亮）

## 4. 日志机制

### 4.1 核心类

```
LogManager (单例)
├── add_system_log(message)  # 添加系统消息
├── add_battle_log(message)  # 添加战斗消息
├── clear_logs()             # 清空日志
└── log_added signal         # 日志添加信号
```

### 4.2 输出流程

```
系统调用
    ↓
LogManager.add_xxx_log()
    ↓
添加时间戳和类型标签
    ↓
应用BBCode高亮
    ↓
更新RichTextLabel显示
    ↓
发射log_added信号
```

### 4.3 最大条数

- **限制**: 500条
- **超出处理**: 移除最早的日志

## 5. 系统与日志的交互

### 5.1 系统消息输出方

| 系统/模块 | 输出方式 | 典型日志 |
|-----------|----------|----------|
| **CultivationSystem** | `log_message`信号 → CultivationModule | `停止修炼` |
| **CultivationModule** | `log_message`信号 → GameUI | `开始修炼...`、`突破成功/失败` |
| **LianliModule** | `log_message`信号 → GameUI | `已退出历练区域` |
| **ChunaModule** | `log_message`信号 → GameUI | `获得物品`、`使用物品` |
| **SpellModule** | `log_message`信号 → GameUI | `装备术法`、`术法升级成功` |
| **SettingsModule** | `log_message`信号 → GameUI | `存档成功`、`读档成功` |
| **AlchemyModule** | `log_message`信号 → GameUI | `开始炼制`、`炼制完成` |
| **GameUI** | 直接调用`log_manager.add_system_log()` | `欢迎消息`、`离线奖励` |

### 5.2 战斗消息输出方

| 系统/模块 | 输出方式 | 典型日志 |
|-----------|----------|----------|
| **LianliSystem** | `log_message`信号 → LianliModule | `战斗开始...`、`造成伤害`、`挑战第X层成功` |
| **LianliModule** | 判断类型后调用`add_system_log()`或`add_battle_log()` | 转发LianliSystem的日志 |

### 5.3 类型判断逻辑

**LianliModule.on_lianli_action_log()** 根据关键词判断类型:

```gdscript
var system_keywords = ["气血不足", "无法进入"]
if 消息包含关键词:
    调用 add_system_log()
else:
    调用 add_battle_log()
```

## 6. 最佳实践

### 6.1 添加日志的原则

1. **明确类型**: 必须明确是系统消息还是战斗消息
2. **简洁清晰**: 日志内容要简洁，避免冗余
3. **统一格式**: 遵循内容规范，保持格式一致
4. **避免重复**: 同一事件不要多处输出

### 6.2 不同模块的输出方式

**核心系统 (如 CultivationSystem, LianliSystem):**
- 通过信号输出日志
- 由对应的 Module 接收并转发

**UI模块 (如 CultivationModule, LianliModule):**
- 通过 `log_message` 信号输出
- 由 GameUI 接收并调用 LogManager

**独立模块 (如 ChunaModule, SpellModule):**
- 直接调用 `game_ui.log_manager.add_system_log()`

### 6.3 禁止的做法

❌ **不要**使用已废弃的 `add_log()` 函数
❌ **不要**在核心系统中直接操作 UI
❌ **不要**重复输出同一事件

## 7. 扩展指南

### 7.1 添加新的日志类型

如需添加新类型（如 CHAT、NOTICE）:

1. 在 `LogManager.LogType` 枚举中添加
2. 添加对应的 `add_xxx_log()` 方法
3. 更新 `_get_type_tag()` 方法
4. 更新文档

### 7.2 添加新的高亮规则

在 `LogManager._format_message()` 中添加:

```gdscript
result = result.replace("关键词", "[color=颜色]关键词[/color]")
```

## 8. 相关文件

- `scripts/ui/LogManager.gd` - 日志管理器核心
- `scripts/ui/GameUI.gd` - 日志显示和转发
- `scripts/ui/modules/*Module.gd` - 各模块日志输出
- `scripts/core/*System.gd` - 核心系统日志信号
