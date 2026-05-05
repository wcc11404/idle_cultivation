# 术法

## 职责与边界

- 展示术法分类列表、术法缩略卡、术法详情弹窗。
- 处理装备、卸下、升级、充灵、升星请求，并将 `reason_code` 翻译成中文提示。
- 将服务端返回的术法配置 `spells_config` 同步到客户端本地 `SpellData`，保证详情、排序、按钮状态、战斗日志使用同一份真值配置。
- 客户端只保留静态最终属性计算与展示，不负责战斗真值伤害结算。

## 本轮重要变更总览

### 1. 术法系统结构升级

- 术法分类固定为：`breathing / active / opening / production`。
- 每个术法新增：
  - `rarity`
  - `element`
  - `max_star`
  - `stars`
- `effect` 从单个对象升级为 `List[Dictionary]`。
- 每条效果统一使用 `effect_type` 字段。
- 删除旧术法：`thunder_strike`（雷击术）。
- 新增一批吐纳、主动、开局术法；客户端与服务端 `spells.json` 保持同步。

### 2. 等级、星级与属性加成口径

- 当前采用两套属性语义：
  - 乘法类：`attack / defense / health / max_spirit / spirit_gain / penetration / crit_damage`
  - 加法类：`speed / hit / dodge / crit / anti_crit`
- 术法详情弹窗中的属性加成展示规则：
  - 乘法类显示为：`x 1.12`
  - 加法类显示为：`+ 0.2` 或 `+ 12.5%`
- 星级配置口径：
  - `0星` 为初始态
  - `1~5星` 为升星后加成
- 升级与升星带来的加成会在客户端本地汇总后，参与静态属性展示。

### 3. 术法缩略卡 UI 重做

- 术法列表改为一行 `5` 个卡片，自动换行。
- 列表区域只允许纵向滚动，不允许横向滚动。
- 卡片固定高度，星级行始终保留占位，避免有星与无星时高度跳动。
- 卡片展示内容：
  - 星级
  - 名字
  - 五行属性图标/文字
  - 当前等级或未获取状态
  - `查看`、`装备/卸下` 按钮
- 稀有度通过术法名称颜色体现，直接复用物品品质颜色规则。
- 排序规则：
  - 稀有度：`凡 -> 黄 -> 玄 -> 地 -> 天`
  - 同稀有度内：`无 -> 金 -> 木 -> 水 -> 火 -> 土`
- 整张卡片可点击打开详情弹窗。
- 点击详情与拖拽判定分离，避免点击行为覆盖拖拽。

### 4. 术法详情弹窗重做

- 新增展示：
  - 五行属性
  - 稀有度（凡阶 / 黄阶 / 玄阶 / 地阶 / 天阶）
  - 星级
  - 当前等级
  - 术法效果
  - 属性加成
  - 升级条件
  - 升星条件
- 升星条件显示规则：
  - 未获取术法：`同名术法解锁道具 - / -`
  - 已获取术法：
    - `同名术法解锁道具 x / y`
    - `空白玉简 x / y`（需要时显示）
- `x` 来自当前储纳真实数量统计，不再写死。
- 升星成功后会先刷新储纳，再刷新术法列表和详情弹窗，保证材料扣减即时可见。

### 5. 术法效果文案动态化

- 主动类术法效果不再依赖固定旧文案，统一按 `effect` 动态生成：
  - `战斗中有概率造成{damage_text}伤害`
  - `并恢复造成伤害的{drain_text}气血`
  - `并使敌方行动条减少{turn_gauge_text}`
- 开局类术法效果也改成动态生成，不再硬信固定 description。
- 开局类 `description` 统一改成占位符形式，例如：
  - `开局攻击增加{attack_text}，命中增加{hit_text}`
  - `开局暴击增加{crit_text}，爆伤增加{crit_damage_text}`
- 详情弹窗对开局术法会遍历全部 `undispellable_buff` 效果，双属性术法不会再只显示第一条。

### 6. 开局术法数值口径统一

- `防御 / 穿透 / 攻击 / 爆伤`：按绝对百分比增长。
- `命中 / 闪避 / 暴击 / 抗暴`：统一按 `buff_percent` 配置，不再与 `buff_value` 混用。
- `速度` 继续使用数值型 `buff_value`。
- 双属性开局术法每级增长按绝对值增加，例如：
  - `12.5% -> 13.75%`
  - 不是乘法放大。
- `千机锁灵章`、`锐金破妄诀`、`炎心梵世诀`、`厚土承天诀` 等双属性开局术法都按新规则重算了 `levels[*].effect`。

### 7. 战斗日志客户端展示修正

- 历练战斗日志统一遍历服务端返回的 `info.effects[]`。
- 开局术法日志不再只取第一条 buff。
- 例如：
  - `玩家使用千机锁灵章，攻击提升12.5%，命中提升12.5%`
- 不再使用临时的 group 包装结构，单 buff 和双 buff 统一走遍历逻辑。

### 8. 属性面板展示修正

- 内视属性面板中的以下字段不再显示固定假值：
  - 穿透
  - 命中
  - 闪避
  - 暴击
  - 爆伤
  - 抗暴
- 现在直接读取客户端本地静态最终属性：
  - `player.static_penetration`
  - `player.static_hit`
  - `player.static_dodge`
  - `player.static_crit`
  - `player.static_crit_damage`
  - `player.static_anti_crit`

### 9. 解锁道具与测试礼包调整

- 所有术法解锁道具描述统一为：
  - `使用后可解锁xx，或可用于对应术法的升星`
- 测试礼包中：
  - 所有术法解锁道具统一补到 `15`
  - `blank_jade_slip`（空白玉简）统一补到 `99`
- 储纳容量提升到 `60`。

## 关键状态

- 当前查看术法：`current_viewing_spell`
- 当前倍数策略：`current_multiplier_index`
- 卡片池与信号状态：`_card_pool`、`_signals_connected`
- 点击/拖拽状态：`_touch_states`

## API 交互

- `GET /game/spell/list`
- `POST /game/spell/equip`
- `POST /game/spell/unequip`
- `POST /game/spell/upgrade`
- `POST /game/spell/charge`
- `POST /game/spell/star_up`

## 功能触发流转

### 1) 打开术法页

1. 显示术法面板。
2. 读取本地 `spell_system` 构建四类术法列表。
3. 调用 `spell/list`，将服务端返回的：
   - `player_spells`
   - `equipped_spells`
   - `spells_config`
   同步回本地。
4. 使用远端 `spells_config` 覆盖本地 `SpellData`，保证详情与服务端真值一致。

### 2) 点击术法卡片

1. 记录 `current_viewing_spell`。
2. 整卡点击可直接打开详情。
3. 拖拽距离超过阈值则不触发详情，避免覆盖拖拽行为。

### 3) 点击装备 / 卸下

1. 调用 `spell/equip` 或 `spell/unequip`。
2. 成功后刷新术法列表与详情。
3. `卸下` 按钮使用红色视觉强调。

### 4) 点击升级 / 充灵 / 升星

1. 升级：依赖使用次数与充灵量。
2. 充灵：消耗玩家灵气，为当前等级升级条件充能。
3. 升星：依赖同名术法解锁道具与空白玉简。
4. 升星成功后刷新储纳、术法列表、详情弹窗。

## reason_code 文案策略

- 所有业务提示在模块内本地映射，不直接透传服务端 message。
- 典型升星提示：
  - `术法【xxx】升星成功，达到n星`
  - `升星失败，缺少同名术法解锁道具x个`
  - `升星失败，缺少空白玉简x个`

## 关键函数位置

### UI 模块
- `scripts/ui/modules/SpellModule.gd`
  - 术法列表、排序、卡片点击、装备/卸下/升级/充灵/升星
- `scripts/ui/modules/SpellDetailPopup.gd`
  - 术法详情展示、术法效果动态文案、升级/升星条件
- `scripts/ui/modules/LianliModule.gd`
  - 历练日志中文案渲染，尤其是主动术法与开局术法的 effect 遍历
- `scripts/ui/modules/CultivationModule.gd`
  - 属性面板中的静态最终属性显示

### 本地核心数据
- `scripts/core/spell/SpellData.gd`
  - 术法配置加载与远端配置覆盖
- `scripts/core/spell/SpellSystem.gd`
  - 玩家术法存档、属性加成汇总、详情数据快照
- `scripts/core/player/PlayerData.gd`
  - 静态最终属性写回
- `scripts/core/shared/AttributeCalculator.gd`
  - 客户端静态最终属性计算

## 测试覆盖点

- `TestSpellModuleApi.gd`
  - 术法详情弹窗、升星条件、主动术法文案
- `TestLianliModuleApi.gd`
  - 历练日志、开局术法日志、主动术法展示
- `TestAttributeCalculator.gd`
  - 客户端静态属性计算

## 维护注意事项

- 术法详情显示与历练日志都应优先以 `effect` 为真值，不要再把固定 description 当唯一来源。
- 开局术法的双属性效果必须遍历 `effects[]`，不能只取第一条。
- 修改 `spells.json` 后，如果客户端表现不对，优先检查：
  - 服务端 `spell/list` 返回的 `spells_config`
  - 客户端 `SpellData.apply_remote_config(...)` 是否已生效
- 当前客户端只负责展示与静态最终属性计算；战斗真值结算以服务端为准。
