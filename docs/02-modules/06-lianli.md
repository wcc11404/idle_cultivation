# 历练

## 职责与边界

- 管理历练区域进入、战斗时间轴播放、结算上报、继续连战和退出。
- 战斗逻辑由服务端模拟，客户端只做播放与状态机控制。

## 关键状态

- 本地运行态写入 `lianli_system`：
  - `is_in_lianli`
  - `is_in_battle`
  - `is_waiting`
  - `current_area_id`
- 回放状态：
  - `_battle_timeline`、`_timeline_cursor`、`_timeline_elapsed`
  - `_is_timeline_running`、`_finish_in_flight`
- 展示状态：
  - `_simulated_player_health_after`
  - `_simulated_player_max_health`

## API 交互

- `POST /game/lianli/simulate`
- `POST /game/lianli/finish`
- `GET /game/dungeon/foundation_herb_cave`
- `GET /game/tower/highest_floor`

## 功能触发流转

### 1) 进入历练页

1. 展示历练主面板。
2. 拉取副本次数与塔层信息，更新按钮文案。
3. 根据本地运行态判断：
   - 若已在历练中，直接回到战斗面板。
   - 否则显示区域选择面板。

### 2) 点击某历练区域

1. 先做本地拦截（例如气血不足）。
2. 再做模式互斥检查（修炼中/炼丹中不可进）。
3. 调 `lianli/simulate(area_id)`。
4. 成功：写入本地历练态，切到战斗面板，启动时间轴播放。
5. 失败：按 reason_code 输出阻断文案。

### 3) 时间轴播放（战斗中）

1. `_process` 按速度倍率推进 elapsed。
2. 到达事件时间点时应用事件：
   - 更新敌我血条
   - 更新术法相关展示
   - 输出战斗日志
3. 时间轴结束后进入结算流程（finish）。

### 4) 结算（finish）

1. 调 `lianli/finish(speed, index?)`。
2. 成功：
   - 根据返回判断是否已完整结算。
   - 进入等待下一场或允许继续/退出。
3. 失败：
   - 输出归一化提示。
   - 强制收敛退出战斗态，回到可恢复页面。

### 5) 连战与退出

1. 连战开启时，等待计时后自动请求下一次 `simulate`。
2. 点击退出时中断时间轴并清理本地历练态。

## reason_code 文案策略

- `LIANLI_SIMULATE_*`：入场阻断与次数限制提示。
- `LIANLI_FINISH_*`：结算状态与同步异常提示。
- 不依赖服务端 message 文本。

## 失败处理与回退

- finish 失败必须收敛，避免卡在“战斗中”状态。
- 返回历练页时优先依据本地历练态恢复正确子页面。

## 测试覆盖点

- 切页返回后定位正确。
- finish 失败收敛。
- 本地气血拦截 + 服务端阻断提示。

## 典型触发链路（函数级）

以“进入某区域历练并完成一场结算”为例：

1. `LianliModule.on_lianli_area_pressed(area_id)` 做本地血量与模式互斥检查。
2. 调 `api.lianli_simulate` 成功后写入 `lianli_system.is_in_lianli/current_area_id/is_in_battle`。
3. `LianliModule._start_timeline_playback` 启动时间轴，`_process` 按帧推进事件并更新血条/日志。
4. 时间轴结束后触发 `api.lianli_finish`。
5. finish 成功则更新结算态并决定“继续连战/退出”；失败则强制收敛并回区域选择页。
6. 切到其他 tab 再返回时，`on_tab_open` 依据 `lianli_system` 直接定位战斗页或选择页。
