# 修仙挂机游戏 - 完整测试计划

## 📊 当前测试状态

### 已有测试文件

| 文件 | 类型 | 状态 |
|------|------|------|
| test_player_data.gd | 单元 | ✅ 已有 |
| test_inventory.gd | 单元 | ✅ 已有 |
| test_cultivation_system.gd | 单元 | ✅ 已有 |
| test_lianli_system.gd | 单元 | ✅ 已有 |
| test_realm_system.gd | 单元 | ✅ 已有 |
| test_save_manager.gd | 单元 | ✅ 已有 |
| test_enemy_data.gd | 单元 | ✅ 已有 |
| test_item_data.gd | 单元 | ✅ 已有 |
| test_lianli_area_data.gd | 单元 | ✅ 已有 |
| test_offline_reward.gd | 单元 | ✅ 已有 |
| test_log_manager.gd | 单元 | ✅ 已有 |
| test_alchemy_system.gd | 单元 | ✅ 已有 |
| test_all_systems.gd | 集成 | ✅ 已有 |
| test_lianli_flow.gd | GUT | ✅ 已有 |
| test_ui_automation.gd | GUT | ✅ 已有 |

### 待补充测试

| 系统 | 优先级 | 状态 |
|------|--------|------|
| AttributeCalculator | 🔴 高 | ❌ 缺失 |
| SpellSystem | 🔴 高 | ❌ 缺失 |
| SpellData | 🟡 中 | ❌ 缺失 |
| AccountSystem | 🟡 中 | ❌ 缺失 |
| EndlessTowerData | 🟡 中 | ❌ 缺失 |
| AlchemyRecipeData | 🟢 低 | ❌ 缺失 |

---

## 🏗️ 测试目录结构

```
tests/
├── unit/                      # 单元测试
│   ├── core/                  # 核心系统
│   │   ├── test_player_data.gd
│   │   ├── test_attribute_calculator.gd    # 新增
│   │   ├── test_save_manager.gd
│   │   └── test_offline_reward.gd
│   ├── combat/                # 战斗系统
│   │   ├── test_lianli_system.gd
│   │   ├── test_enemy_data.gd
│   │   ├── test_lianli_area_data.gd
│   │   └── test_endless_tower_data.gd     # 新增
│   ├── inventory/             # 库存系统
│   │   ├── test_inventory.gd
│   │   └── test_item_data.gd
│   ├── cultivation/           # 修炼系统
│   │   ├── test_cultivation_system.gd
│   │   └── test_realm_system.gd
│   ├── spell/                 # 术法系统
│   │   ├── test_spell_system.gd           # 新增
│   │   └── test_spell_data.gd             # 新增
│   ├── alchemy/               # 炼丹系统
│   │   ├── test_alchemy_system.gd
│   │   └── test_alchemy_recipe_data.gd    # 新增
│   └── account/               # 账号系统
│       └── test_account_system.gd         # 新增
│
├── integration/               # 集成测试
│   ├── test_all_systems.gd
│   ├── test_combat_loot_flow.gd           # 新增
│   ├── test_cultivation_breakthrough.gd   # 新增
│   ├── test_alchemy_craft_flow.gd         # 新增
│   └── test_save_load_integrity.gd        # 新增
│
├── ui/                        # UI自动化测试
│   ├── test_new_player_flow.gd            # 新增
│   ├── test_combat_flow.gd                # 新增
│   ├── test_alchemy_flow.gd               # 新增
│   └── test_settings_flow.gd              # 新增
│
├── regression/                # 回归测试
│   └── test_bug_fixes.gd                  # 新增
│
├── gut/                       # GUT测试
│   ├── test_lianli_flow.gd
│   └── test_ui_automation.gd
│
├── fixtures/                  # 测试数据
│   └── test_data_factory.gd               # 新增
│
└── utils/                     # 测试工具
    └── test_helper.gd
```

---

## 📋 详细测试用例清单

### 一、单元测试

#### 1. PlayerData 测试 (test_player_data.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_initial_values | 初始属性值正确 | 🔴 |
| test_health_bounds | 气血范围 [0, max_health] | 🔴 |
| test_spirit_energy_bounds | 灵气范围 [0, max_spirit] | 🔴 |
| test_take_damage | 受伤逻辑正确 | 🔴 |
| test_heal | 治疗逻辑正确 | 🔴 |
| test_add_spirit_energy | 灵气增加正确 | 🔴 |
| test_realm_level_up | 境界等级提升 | 🔴 |
| test_realm_breakthrough | 境界突破 | 🔴 |
| test_get_final_attack | 最终攻击力计算 | 🟡 |
| test_get_final_defense | 最终防御力计算 | 🟡 |
| test_get_final_speed | 最终速度计算 | 🟡 |
| test_apply_realm_stats | 境界属性加成 | 🔴 |
| test_daily_dungeon_count | 每日副本次数 | 🟡 |

#### 2. AttributeCalculator 测试 (test_attribute_calculator.gd) - 新增

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_calculate_damage_basic | 基础伤害计算 | 🔴 |
| test_calculate_damage_with_defense | 有防御的伤害计算 | 🔴 |
| test_calculate_damage_with_percent | 百分比伤害 | 🔴 |
| test_calculate_damage_minimum | 最小伤害为1 | 🔴 |
| test_calculate_combat_attack | 战斗攻击力计算 | 🔴 |
| test_calculate_combat_defense | 战斗防御力计算 | 🔴 |
| test_calculate_combat_speed | 战斗速度计算 | 🔴 |
| test_format_damage | 伤害格式化 | 🟡 |
| test_format_integer | 整数格式化 | 🟢 |

#### 3. Inventory 测试 (test_inventory.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_add_item | 添加物品 | 🔴 |
| test_remove_item | 移除物品 | 🔴 |
| test_remove_item_insufficient | 物品不足时移除失败 | 🔴 |
| test_get_item_count | 获取物品数量 | 🔴 |
| test_has_item | 检查物品是否存在 | 🔴 |
| test_clear | 清空背包 | 🟡 |
| test_get_item_list | 获取物品列表 | 🟡 |
| test_capacity | 容量检查 | 🟡 |
| test_item_stacking | 物品叠加 | 🟡 |

#### 4. LianliSystem 测试 (test_lianli_system.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_start_lianli_in_area | 开始历练 | 🔴 |
| test_start_battle | 开始战斗 | 🔴 |
| test_end_lianli | 结束历练 | 🔴 |
| test_battle_victory | 战斗胜利 | 🔴 |
| test_battle_defeat | 战斗失败 | 🔴 |
| test_continuous_lianli | 连续历练 | 🟡 |
| test_lianli_speed | 历练速度 | 🟡 |
| test_wait_for_next_battle | 等待下一场 | 🟡 |
| test_atb_system | ATB行动条系统 | 🔴 |
| test_player_action | 玩家行动 | 🔴 |
| test_enemy_action | 敌人行动 | 🔴 |
| test_combat_buffs | 战斗增益 | 🟡 |
| test_spell_trigger | 术法触发 | 🟡 |

#### 5. CultivationSystem 测试 (test_cultivation_system.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_start_cultivation | 开始修炼 | 🔴 |
| test_stop_cultivation | 停止修炼 | 🔴 |
| test_cultivation_gain | 修炼获得灵气 | 🔴 |
| test_cultivation_speed | 修炼速度 | 🟡 |
| test_cultivation_max_spirit | 灵气达到上限 | 🔴 |

#### 6. RealmSystem 测试 (test_realm_system.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_get_realm_display_name | 境界显示名称 | 🔴 |
| test_get_level_info | 境界等级信息 | 🔴 |
| test_can_breakthrough | 是否可以突破 | 🔴 |
| test_get_next_realm | 下一境界 | 🟡 |
| test_get_all_realms | 所有境界列表 | 🟢 |

#### 7. SpellSystem 测试 (test_spell_system.gd) - 新增

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_equip_spell | 装备术法 | 🔴 |
| test_unequip_spell | 卸下术法 | 🔴 |
| test_trigger_attack_spell | 触发攻击术法 | 🔴 |
| test_trigger_passive_spell | 触发被动术法 | 🔴 |
| test_spell_cooldown | 术法冷却 | 🟡 |
| test_spell_use_count | 术法使用次数 | 🟡 |
| test_get_equipped_spells | 获取已装备术法 | 🟡 |

#### 8. AlchemySystem 测试 (test_alchemy_system.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_start_craft | 开始炼制 | 🔴 |
| test_stop_craft | 停止炼制 | 🔴 |
| test_craft_complete | 炼制完成 | 🔴 |
| test_craft_success_rate | 炼制成功率 | 🟡 |
| test_craft_time | 炼制时间 | 🟡 |
| test_check_materials | 检查材料 | 🔴 |

#### 9. SaveManager 测试 (test_save_manager.gd)

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_save_game | 保存游戏 | 🔴 |
| test_load_game | 加载游戏 | 🔴 |
| test_save_encryption | 存档加密 | 🟡 |
| test_has_save | 检查存档存在 | 🔴 |
| test_delete_save | 删除存档 | 🟡 |

#### 10. AccountSystem 测试 (test_account_system.gd) - 新增

| 测试用例 | 描述 | 优先级 |
|----------|------|--------|
| test_create_account | 创建账号 | 🔴 |
| test_login | 登录 | 🔴 |
| test_logout | 登出 | 🔴 |
| test_get_current_account | 获取当前账号 | 🔴 |
| test_update_nickname | 更新昵称 | 🟡 |
| test_update_avatar | 更新头像 | 🟡 |

---

### 二、集成测试

#### 1. 战斗掉落流程 (test_combat_loot_flow.gd) - 新增

| 测试用例 | 描述 |
|----------|------|
| test_battle_gives_spirit_stone | 战斗获得灵石 |
| test_battle_gives_materials | 战斗获得材料 |
| test_elite_battle_better_loot | 精英敌人更好掉落 |
| test_loot_added_to_inventory | 掉落物进入背包 |

#### 2. 修炼突破流程 (test_cultivation_breakthrough.gd) - 新增

| 测试用例 | 描述 |
|----------|------|
| test_cultivation_to_breakthrough | 修炼到突破 |
| test_breakthrough_consumes_spirit | 突破消耗灵气 |
| test_breakthrough_increases_stats | 突破增加属性 |
| test_breakthrough_changes_realm | 突破改变境界 |

#### 3. 炼丹流程 (test_alchemy_craft_flow.gd) - 新增

| 测试用例 | 描述 |
|----------|------|
| test_craft_consumes_materials | 炼丹消耗材料 |
| test_craft_gives_pill | 炼丹获得丹药 |
| test_craft_failure_no_pill | 炼丹失败无丹药 |
| test_craft_with_success_boost | 成功率加成 |

#### 4. 存档完整性 (test_save_load_integrity.gd) - 新增

| 测试用例 | 描述 |
|----------|------|
| test_save_preserves_player_data | 存档保存玩家数据 |
| test_save_preserves_inventory | 存档保存背包 |
| test_save_preserves_realm | 存档保存境界 |
| test_save_preserves_spells | 存档保存术法 |
| test_full_save_load_cycle | 完整存档读档循环 |

---

### 三、UI自动化测试

#### 1. 新玩家流程 (test_new_player_flow.gd) - 新增

```
创建角色 → 领取新手礼包 → 查看背包 → 开始修炼
```

| 测试用例 | 描述 |
|----------|------|
| test_new_player_has_starting_items | 新玩家有初始物品 |
| test_claim_starter_pack | 领取新手礼包 |
| test_first_cultivation | 第一次修炼 |
| test_first_battle | 第一次战斗 |

#### 2. 战斗流程 (test_combat_flow.gd) - 新增

```
点击历练 → 选择区域 → 战斗 → 获得奖励
```

| 测试用例 | 描述 |
|----------|------|
| test_enter_lianli_tab | 进入历练tab |
| test_select_normal_area | 选择普通区域 |
| test_select_special_area | 选择特殊区域 |
| test_battle_rounds | 战斗回合 |
| test_exit_battle | 退出战斗 |

#### 3. 炼丹流程 (test_alchemy_flow.gd) - 新增

```
进入洞府 → 进入炼丹房 → 选择丹方 → 炼制 → 获得丹药
```

| 测试用例 | 描述 |
|----------|------|
| test_enter_alchemy_room | 进入炼丹房 |
| test_select_recipe | 选择丹方 |
| test_start_craft | 开始炼制 |
| test_craft_complete | 炼制完成 |

#### 4. 设置流程 (test_settings_flow.gd) - 新增

```
进入设置 → 保存游戏 → 加载游戏 → 验证
```

| 测试用例 | 描述 |
|----------|------|
| test_save_button | 保存按钮 |
| test_load_button | 加载按钮 |
| test_save_success_message | 保存成功提示 |

---

### 四、回归测试 (test_bug_fixes.gd) - 新增

| 测试用例 | 描述 |
|----------|------|
| test_bug_XXX | 针对特定bug的回归测试 |

---

## 📊 测试覆盖率目标

### 系统覆盖率

| 系统 | 当前覆盖率 | 目标覆盖率 | 优先级 |
|------|-----------|-----------|--------|
| PlayerData | ~60% | 90% | 🔴 |
| AttributeCalculator | 0% | 95% | 🔴 |
| LianliSystem | ~50% | 85% | 🔴 |
| Inventory | ~70% | 90% | 🔴 |
| CultivationSystem | ~60% | 85% | 🔴 |
| RealmSystem | ~50% | 80% | 🟡 |
| SpellSystem | 0% | 80% | 🔴 |
| AlchemySystem | ~40% | 80% | 🟡 |
| SaveManager | ~50% | 90% | 🔴 |
| AccountSystem | 0% | 70% | 🟢 |

### 测试类型分布

| 测试类型 | 当前数量 | 目标数量 | 占比 |
|----------|---------|---------|------|
| 单元测试 | ~50 | 100+ | 60% |
| 集成测试 | ~10 | 30+ | 20% |
| UI测试 | ~5 | 20+ | 15% |
| 回归测试 | 0 | 按需 | 5% |

---

## 📅 实施计划

### 第一阶段：核心系统测试 (优先级最高)

**时间：1-2周**

| 任务 | 预计时间 |
|------|---------|
| 创建 AttributeCalculator 测试 | 2小时 |
| 完善 PlayerData 测试 | 2小时 |
| 完善 LianliSystem 测试 | 3小时 |
| 完善 Inventory 测试 | 2小时 |
| 创建 SpellSystem 测试 | 3小时 |

### 第二阶段：集成测试

**时间：1周**

| 任务 | 预计时间 |
|------|---------|
| 创建战斗掉落流程测试 | 2小时 |
| 创建修炼突破流程测试 | 2小时 |
| 创建存档完整性测试 | 2小时 |
| 创建炼丹流程测试 | 2小时 |

### 第三阶段：UI自动化测试

**时间：1周**

| 任务 | 预计时间 |
|------|---------|
| 创建新玩家流程测试 | 3小时 |
| 创建战斗流程测试 | 3小时 |
| 创建炼丹流程测试 | 2小时 |
| 创建设置流程测试 | 1小时 |

### 第四阶段：持续维护

**时间：持续**

- 每次新增功能时添加对应测试
- 每次修复bug时添加回归测试
- 定期运行完整测试套件
- 监控测试覆盖率

---

## 🛠️ 测试运行命令

```bash
# 运行所有 GUT 测试
godot --headless --script res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -ginclude_subdirs -gexit

# 运行特定测试文件
godot --headless --script res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -gtest=test_lianli_flow.gd -gexit

# 运行原有测试
godot --headless --script res://tests/run_all_tests.gd

# 导入资源后运行
godot --headless --import && godot --headless --script res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -ginclude_subdirs -gexit
```

---

## 📝 测试规范

### 命名规范

```gdscript
# 单元测试：test_<功能>_<场景>_<预期>
func test_take_damage_reduces_health():
    pass

# 集成测试：test_<流程>_<验证点>
func test_battle_flow_gives_loot():
    pass

# UI测试：test_<页面>_<操作>
func test_lianli_tab_enter_battle():
    pass
```

### 测试结构

```gdscript
extends GutTest

var system: Node

func before_all():
    # 一次性初始化
    pass

func before_each():
    # 每个测试前初始化
    system = create_system()

func after_each():
    # 每个测试后清理
    if system:
        system.queue_free()

func after_all():
    # 最终清理
    pass

func test_something():
    # Arrange
    var expected = 10
    
    # Act
    var actual = system.calculate()
    
    # Assert
    assert_eq(actual, expected, "计算结果应正确")
```

---

## ✅ 验收标准

1. **单元测试覆盖率** ≥ 80%
2. **核心系统覆盖率** ≥ 90%
3. **所有测试通过率** = 100%
4. **关键流程UI测试** = 100%
5. **无跳过的测试**（pending除外）
6. **测试运行时间** < 60秒

---

*文档版本: 1.0*
*创建日期: 2026-03-03*
*最后更新: 2026-03-03*
