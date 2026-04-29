# 仙务司任务

## 职责与边界

- 管理“地区 -> 云稷城 -> 仙务司”入口下的任务展示、分页切换与领奖交互。
- 客户端只负责展示和请求，不做任务进度真值推进。
- 任务进度、可领奖判定、发奖全部由服务端权威控制。

## 关键状态

- 当前页签：`_active_tab`（`daily` / `newbie`）
- 任务缓存：`_daily_tasks`、`_newbie_tasks`
- 列表容器：`task_list`（滚动可用，滚动轴隐藏）
- 红点摘要：可领奖数量由 `TaskModule` 计算后，通过 `task_state_changed(claimable_count)` 上报给 `GameUI` 的统一红点聚合器。

## API 交互

- `GET /game/task/list`
- `POST /game/task/claim`

## 功能触发流转

### 1) 进入仙务司

1. 在地区页点击“仙务司”按钮。
2. 显示任务面板并默认进入每日任务页。
3. 请求 `task/list` 拉全量任务。
4. 按“未领取在上、已领取在下；组内按 sort_order”排序后渲染卡片。

### 2) 切换每日/新手任务

1. 点击页签按钮切换 `_active_tab`。
2. 只重绘当前页签任务，不重算本地进度。
3. 按钮状态：
   - 未完成：灰色不可点
   - 已完成未领取：绿色可点
   - 已领取：灰色不可点（文案“已领取”）

### 3) 点击领取

1. 调 `task/claim(task_id)`。
2. 成功后：
   - 输出奖励日志文案；
   - 重新请求 `task/list`，以服务端状态重绘；
   - 刷新顶部货币（灵石/仙晶）。
   - 重新计算可领奖数量；若已无可领奖任务，`仙务司` 与 `地区 Tab` 红点应立即熄灭。

## 红点规则（一）

- 真值来源：`GET /game/task/list`
- 点亮条件：存在至少一个任务满足 `completed = true && claimed = false`
- 显示位置：
  - `地区 -> 仙务司` 按钮：大号数字红点，显示 `task_claimable_count`
  - 主 `地区 Tab`：小红点透传，不显示数字
- 聚合边界：
  - `TaskModule` 只负责上报摘要状态，不直接操作任何红点节点
  - `GameUI` 负责统一渲染入口按钮和 Tab 红点
- 数字显示约定：
  - `1-99` 显示实际数量
  - `>99` 显示 `99+`
- 轮询失败：
  - 保持上一次成功状态，不主动清空红点

## reason_code 文案策略

- `TASK_CLAIM_SUCCEEDED`：领取成功（带奖励清单）。
- `TASK_CLAIM_NOT_COMPLETED`：任务尚未完成。
- `TASK_CLAIM_ALREADY_CLAIMED`：该任务奖励已领取。
- `TASK_CLAIM_TASK_NOT_FOUND`：任务不存在。

## 顶部货币展示约定

- TopBar 货币节点统一为 `CurrencyContainer`（原 `SpiritStoneContainer` 已收口）。
- 同时显示灵石和仙晶，两个数值都随 `update_ui()` 刷新。

## 测试覆盖点

- `tests_gut/unit/ui/TestTaskModuleApi.gd`
  - 任务渲染、领奖刷新、已领取下沉排序、红点即时刷新。
- `tests_gut/integration/TestModuleApiSmoke.gd`
  - 地区入口进入仙务司 + 新手任务领奖主链路 + 地区红点熄灭校验。
