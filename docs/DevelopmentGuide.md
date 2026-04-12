# Godot 4.6 开发流程指南

本文档记录项目开发的核心流程、规范和测试方法，确保开发过程标准化、可验证。

---

## 一、开发流程

### 1.1 设计阶段

#### 概念设计
- 确定核心玩法（修仙挂机）
- 定义世界观（境界划分、升级规则）
- 明确目标用户（挂机游戏爱好者）

#### 需求文档
- 功能列表：玩家属性、境界系统、修炼系统、战斗系统
- 数据结构：玩家数据格式、境界数据格式
- 验收标准：功能完成度、BUG修复率

#### 原型设计
- 纸面原型：UI布局、界面跳转流程
- 玩法原型：Godot快速实现核心玩法demo

### 1.2 开发阶段

#### 架构设计
- 模块划分：PlayerData、RealmSystem、CultivationSystem
- 接口设计：模块间交互协议
- 数据结构：玩家数据、境界数据、战斗数据

#### 代码开发
- 核心系统实现：PlayerData.gd、RealmSystem.gd、CultivationSystem.gd
- UI实现：MainUI.gd、BagUI.gd、SkillUI.gd
- 资源整合：临时占位符资源

#### 测试迭代
- 单元测试：单个函数/类测试
- 集成测试：模块间交互测试
- 用户测试：内部玩家试玩反馈

---

## 二、代码规范

### 2.1 继承选择
- 需要2D渲染 → `extends Node2D`
- 需要3D渲染 → `extends Node3D`
- 仅逻辑处理 → `extends Node`（推荐）

### 2.2 数组操作
- 头部删除 → `array.remove_at(0)`
- 尾部删除 → `array.pop_back()`
- 头部添加 → `array.push_front(value)`
- 尾部添加 → `array.push_back(value)`

### 2.3 类定义
- 不要对autoload使用`class_name`
- 如需跨脚本访问，使用autoload或`load()`

### 2.4 Node属性访问
```gdscript
# 正确方式（直接访问）
var attack = player.attack
player.health = 100

# 错误方式（对Node使用get）
var attack = player.get("attack", 100)  # 这是Dictionary的方法！
```

### 2.5 存档系统规范
所有需要持久化数据的系统必须实现以下两个方法：

```gdscript
# 获取存档数据
func get_save_data() -> Dictionary:
	return {
		"key1": value1,
		"key2": value2
	}

# 应用存档数据
func apply_save_data(data: Dictionary):
	if data.has("key1"):
		key1 = data["key1"]
	if data.has("key2"):
		key2 = data["key2"]
```

需要存档的系统包括：
- PlayerData
- OfflineReward
- Inventory

### 2.6 信号命名规范
使用过去式动词短语命名信号：
- 完成事件：xxx_completed（save_completed, load_completed）
- 更新事件：xxx_updated（task_updated, item_updated）
- 状态变化：xxx_changed（realm_changed, level_changed）
- 开始/停止：xxx_started, xxx_stopped（cultivation_started）

### 2.7 系统初始化规范
在 GameManager 中初始化系统的标准模式：

```gdscript
func init_systems():
	system_name = load("res://scripts/core/SystemName.gd").new()
	system_name.name = "SystemName"
	add_child(system_name)
```

为所有系统提供统一的访问器方法：
```gdscript
func get_system_name():
	return system_name
```

---

## 三、测试规范

### 3.1 测试框架

项目使用 **GUT (Godot Unit Testing)** 框架进行测试，这是Godot官方推荐的测试框架。

### 3.2 测试目录结构
```
tests_gut/
├── support/                     # API 测试基座与测试账号辅助
├── fixtures/                    # 通用断言/日志/背包辅助
├── unit/
│   ├── ui/                      # UI 模块 API 集成测试
│   ├── core/                    # 纯工具与基础能力测试
│   └── data/                    # 静态配置与数据测试
└── integration/
    └── test_module_api_smoke.gd # 轻量跨模块 smoke
```

### 3.3 测试框架使用原则

#### 原则1：按系统组织测试
- 模块 API 集成测试优先放在 `tests_gut/unit/ui/`
- 纯工具与静态配置测试继续保留在 `core/`、`data/`
- 明显过时的本地权威测试应迁移或删除，避免同一功能维护两套真值

#### 原则2：使用GUT框架
- 所有测试继承自 `GutTest`
- 使用GUT提供的断言方法
- 遵循GUT的测试命名规范

#### 原则3：测试方法命名规范
- 测试函数以 `test_` 开头
- 清晰描述测试场景
- 避免与变量名冲突

### 3.4 测试阶段要求

#### 新功能开发流程
1. **功能实现**：完成新功能的代码编写
2. **测试用例编写**：
   - UI/业务链路优先在 `tests_gut/unit/ui/` 下新增真实 API 驱动测试
   - 跨模块串联场景在 `tests_gut/integration/` 下补 smoke
   - 只有纯工具类逻辑才直接放到 `tests_gut/unit/core/`
3. **测试执行**：使用GUT运行测试验证功能正确性
4. **动静态检查**：执行静态检查和动态检查
5. **测试完善**：修复测试中发现的问题，确保测试覆盖所有场景

### 3.5 测试执行流程

#### 3.5.1 使用GUT运行测试

**通过Godot编辑器运行**：
1. 安装GUT插件（通过AssetLib）
2. 打开GUT面板（Project > Tools > GUT）
3. 选择测试目录和配置
4. 点击"Run Tests"按钮

**通过命令行运行**：
```bash
# 运行完整客户端测试套件
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/godot ./run_tests.sh

# 直接调用 GUT
HOME="$(pwd)/.godot_test_home" \
"/Applications/Godot.app/Contents/MacOS/godot" \
  --headless \
  --path . \
  --script res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests_gut \
  -ginclude_subdirs \
  -gexit
```

运行前需要保证本地服务端已启动，并提供：

- `http://127.0.0.1:8444/api`
- 固定测试账号 `test / test123`
- `/api/test/*` 测试接口

#### 3.5.2 编写新测试用例

**模块 API 测试模板**（`tests_gut/unit/ui/test_yourmodule_api.gd`）：

```gdscript
extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")

var harness: ModuleHarness = null

func before_each():
	harness = ModuleHarness.new()
	add_child(harness)
	await harness.bootstrap()

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
	await get_tree().process_frame

func test_module_action():
	var module = harness.game_ui.your_module
	harness.clear_logs()

	await module.some_button_handler()

	assert_true(harness.last_log().contains("期望文案"), "应输出客户端翻译后的提示")
```

### 3.6 测试覆盖率要求

**单元测试覆盖率**：
- 高频改动模块优先
- 用户可见文案、状态同步、互斥逻辑必须覆盖
- 允许分期补全，不要求一轮达到 100%

**集成测试覆盖率**：
- 系统间交互：至少90%
- 完整游戏流程：100%

### 3.7 测试结果分析

**测试通过标准**：
- 所有测试用例通过
- 无语法错误
- 无运行时错误
- 功能符合预期

**测试失败处理**：
1. 分析失败原因
2. 修复代码或测试用例
3. 重新运行测试
4. 记录修复过程

**测试报告**：
- GUT会自动生成测试报告
- 查看控制台输出的测试结果
- 确保所有测试通过
- 检查测试覆盖率
- 记录测试结果

---

## 四、常用命令

### 4.1 测试命令

#### 4.1.1 自动化测试命令

使用项目根目录下的统一入口 `run_tests.sh` 执行：

```bash
# 运行完整客户端 GUT 套件
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/godot ./run_tests.sh
```

兼容入口 `tests_gut/run_gut_tests.sh` 会转发到同一脚本；`windows_test.sh` 已移除，不再保留第二套入口。

#### 4.1.2 手动测试命令

**运行所有测试**：
```bash
HOME="$(pwd)/.godot_test_home" \
"/Applications/Godot.app/Contents/MacOS/godot" \
  --headless \
  --path . \
  --script res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests_gut \
  -ginclude_subdirs \
  -gexit
```

#### 4.1.3 开发辅助命令

**打开Godot编辑器**：
```bash
# 打开Godot编辑器
open -a Godot

# 打开指定项目
open -a Godot --args --path "/Users/hsams/Documents/idle_cultivation_project/idle_cultivation_client"
```

**查看Godot版本**：
```bash
"/Applications/Godot.app/Contents/MacOS/godot" --version
```

**查看命令行帮助**：
```bash
"/Applications/Godot.app/Contents/MacOS/godot" --help
```

### 4.2 调试技巧
- 在代码中添加 `print("debug: ", variable)`
- 使用 Godot 的Debugger面板查看变量值
- 使用断点调试功能

---

## 五、文档记录

### 5.1 架构文档
- 记录模块划分和接口设计
- 描述数据结构和交互协议

### 5.2 开发指南
- 记录开发流程和规范
- 描述测试方法和验收标准

### 5.3 数值设计
- 记录境界数据和升级规则
- 描述战斗数值和平衡调整

---

## 六、核心系统说明

### 6.1 核心系统列表
- **PlayerData**: 玩家数据管理
- **AccountSystem**: 账号系统
- **RealmSystem**: 境界系统
- **CultivationSystem**: 修炼系统
- **LianliSystem**: 历练系统（包含战斗功能）
- **Inventory**: 储纳系统
- **ItemData**: 物品数据
- **SpellSystem**: 术法系统
- **SpellData**: 术法数据
- **AlchemySystem**: 炼丹系统
- **AlchemyRecipeData**: 丹方数据
- **LianliAreaData**: 历练区域数据
- **EnemyData**: 敌人数据
- **EndlessTowerData**: 无尽塔数据
- **OfflineReward**: 离线收益
- **SaveManager**: 存档管理
- **GameManager**: 游戏管理器（autoload）
- **LogManager**: 日志管理

---

**文档版本**：3.0
**创建日期**：2026-02-16
**更新日期**：2026-03-14
**适用范围**：Godot 4.6 + GDScript开发
