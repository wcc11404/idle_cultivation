# 百草山采集

## 职责与边界

- 管理“地区 -> 百草山”入口下的采集点列表、开始/停止采集、定时上报与掉落日志。
- 采集收益由服务端结算，客户端只负责倒计时触发 `report` 与展示。
- 不引入体力/疲劳系统。

## 关键状态

- 采集运行态：`_is_gathering`、`_current_point_id`
- 上报节奏：`_current_interval`、`_report_timer`
- 防重入：`_report_in_flight`
- 同步异常提示节流：`_report_time_invalid_prompted`

## API 交互

- `GET /game/herb/points`
- `POST /game/herb/start`
- `POST /game/herb/report`
- `POST /game/herb/stop`

## 功能触发流转

### 1) 进入百草山页

1. 在地区页点击“百草山”按钮。
2. 隐藏地区面板，显示采集面板。
3. 调 `herb/points` 拉取采集点配置与当前采集运行态。
4. 渲染采集点卡片（名称、说明、速度、成功率、掉落预览、开始/停止按钮）。

### 2) 点击开始采集

1. 调 `herb/start(point_id)`。
2. 成功后写入本地采集态并重置本地倒计时。
3. 不同采集点互斥：当前点以外的“开始采集”按钮禁用。
4. 日志输出“开始采集：采集点名”。

### 3) 采集中定时 report

1. `_process` 中按 `_current_interval` 累计到点后触发 `herb/report`。
2. `report` 使用网络层“1 秒延迟 + 1 次重试”策略。
3. 成功：
   - 根据 `drops_gained` 本地更新背包与顶部资源展示。
   - 输出“采集获得：xxx”或“本轮采集无产出/失败”。
4. 失败：
   - `HERB_REPORT_TIME_INVALID` 只提示一次“采集同步异常，请稍后重试”。
   - 其他错误按 reason_code 映射提示。

### 4) 点击停止采集

1. 调 `herb/stop`。
2. 成功后清空本地采集态与计时器。
3. 恢复按钮可用状态并输出“停止采集”。

### 5) 点击返回

1. 触发 `back_to_region_requested`。
2. 回到地区页，不切换底部 tab。

## reason_code 文案策略

- 采集模块仅使用 `reason_code + reason_data` 生成玩家文案。
- 互斥提示：
  - `HERB_START_BLOCKED_BY_CULTIVATION`：正在修炼中，无法开始采集
  - `HERB_START_BLOCKED_BY_ALCHEMY`：正在炼丹中，无法开始采集
  - `HERB_START_BLOCKED_BY_LIANLI`：正在历练中，无法开始采集

## 互斥约束（双向）

- 采集开始会拦截修炼/炼丹/历练中状态。
- 采集中会阻塞：
  - 修炼开始
  - 炼丹开始
  - 历练模拟开始

## 测试覆盖点

- 采集点卡片渲染与按钮状态。
- 修炼中开始采集的 reason_code 文案映射。
- 开始 -> report -> 停止主链路。
- report 成功后结果文案输出。
