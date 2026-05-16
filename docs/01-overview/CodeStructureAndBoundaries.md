# 代码结构与边界

本文用于回答两个问题：

- `scripts/` 里每层各做什么。
- `scenes/` 与 `scripts/ui/*` 的职责边界是什么。

## 顶层目录职责

### `scripts/`

- `autoload/`：全局单例与系统装配。
  - `GameManager.gd`：创建并持有玩家状态容器（player/inventory/spell/lianli/alchemy）与静态配置节点。
- `network/`：纯网络层。
  - `NetworkManager.gd`：HTTP 请求、技术错误过滤、鉴权失效处理。
  - `GameServerAPI.gd`：业务 API 封装（不含 `/api/test/*`）。
  - `ServerConfig.gd`：API 基址持久化与读取。
- `ui/`：界面控制层。
  - `ui/app/`：场景级脚本。
    - `LoginUI.gd`：登录页流程。
    - `GameUI.gd`：主界面薄入口，保留场景状态、公开接口和模块装配点。
    - `GameUIBootstrap.gd`：主场景初始化顺序编排。
    - `GameUIWiring.gd`：主场景按钮/信号接线。
    - `GameUIChrome.gd`：safe area、自适应、顶部/底部 tab、红点和纯壳层样式控制。
    - `GameUISceneRefs.gd`：主场景节点引用绑定，集中维护 `Main.tscn` 的查找路径。
    - `GameUIModuleAssembler.gd`：各业务模块的创建、节点引用注入、初始化和模块级信号连接。
    - `GameUIStateBinder.gd`：玩家/背包/术法/炼丹等共享状态在场景与模块之间的分发。
    - `GameTabNavigator.gd`：主界面一级/二级面板切换协调。
    - `GameDataCoordinator.gd`：全量同步、红点刷新、离线奖励等场景级同步编排。
  - `ui/modules/`：业务模块控制器（修炼/储纳/术法/炼丹/历练/设置等）。
  - `ui/common/`：跨模块 UI 公共组件（日志、背景、进度条、弹窗样式模板）。
    - `PopupStyleTemplate.gd`：统一弹窗面板样式与遮罩创建；带外部点击回调时，遮罩会拦截输入并只触发关闭，不再把点击透传到底层界面。
    - `AreaEntryCard.gd`：地区页与历练页共用的单列区域入口卡模板，统一承载图片占位、标题、副标识、标签托盘、主按钮和锁定原因提示。
    - `LogManager.gd`：统一日志富文本输出；当前除 `系统 / 战斗 / 生产` 外，还支持仅在诊断阶段启用的 `调试` 频道，用于记录客户端性能埋点。
- `core/`：本地状态容器 + 静态配置查询（非服务端真值）。
  - `core/player/PlayerData.gd`：玩家运行态入口。
  - `core/shared/AttributeCalculator.gd`：通用属性计算入口。
  - `core/account/AccountConfig.gd`：账号展示配置（头像等）。
  - `core/*/` 子目录：背包、术法、炼丹、历练、境界等配置与状态容器。
- `utils/`
  - `utils/flow/ActionLockManager.gd`：统一的短时动作锁，避免连点并发。
  - `UIUtils.gd`：少量 UI 辅助函数。

### `scenes/`

- `scenes/app/`
  - `Login.tscn`：登录场景。
  - `Main.tscn`：主游戏场景（容器与节点树）。

> 当前已移除未引用的 `components/devtools` 场景目录，避免“场景资产存在但运行链路未使用”的混淆。

## `scenes` 与 `scripts/ui` 的边界

- `scenes` 负责：
  - 节点树结构
  - 布局与主题
  - 可视控件挂载点
- `scripts/ui` 负责：
  - 事件响应
  - API 调用
  - 状态流转与文案输出

判定规则：

- 只改布局/节点样式：改 `scenes`。
- 只改交互流程/文案/请求：改 `scripts/ui`。
- 需要新增可复用控件逻辑：优先放 `scripts/ui/common`，场景只提供挂载容器。

## 当前模块装配关系

启动链路：

1. `project.godot` 进入 `scenes/app/Login.tscn`。
2. 登录成功后切到 `scenes/app/Main.tscn`。
3. `GameUI.gd` 在 `_ready` 中先通过 `GameUISceneRefs.gd` 绑定场景节点，再委托 `GameUIBootstrap.gd` 完成主场景初始化；`GameUIWiring.gd` / `GameUIChrome.gd` / `GameUIModuleAssembler.gd` / `GameUIStateBinder.gd` / `GameTabNavigator.gd` / `GameDataCoordinator.gd` 分别承接接线、壳层布局、模块装配、状态分发、页面切换、数据同步等场景级总控职责。
4. 模块通过 `GameServerAPI + GameManager` 完成“API 真值同步 + 本地展示态更新”。

补充约定：

- `RegionPanel` 与 `LianliSelectPanel` 不再直接依赖场景里摆死的静态 `Button` 列表，而是由 `DongfuModule.gd` / `LianliModule.gd` 基于 `AreaEntryCard.gd` 动态生成入口卡。
- 地区页当前按分组标题组织为：
  - `云稷城`：`仙务司 / 炼丹坊 / 赌坊`
  - `云稷城南`：`百草山`
- 历练页当前按分组标题组织为：
  - `普通区域`：4 张普通历练区域卡
  - `每日区域`：`破境草洞穴`
  - `特殊区域`：`南麓试练塔`
- 若后续新增“可进入某区域/副本/功能房间”的入口，优先复用 `AreaEntryCard.gd`，不要再回到散落的按钮模板实现。
- `AreaEntryCard.gd` 当前图片区直接承接卡片名称（不再重复显示正文大标题）；副标题如“今日剩余次数 2/3”“当前挑战 第17层”使用正文区左对齐短文本。
- `调试` 日志频道默认只用于性能排查；当前由 `GameUI.perf_debug_enabled = OS.is_debug_build()` 控制，正式 release 构建默认不启用。
- 诊断模式启用时，日志筛选条会额外挂出 `调试` 与 `复制调试` 按钮；同时暂停 30 秒一次的任务/邮箱后台轮询，避免性能排查时混入额外刷新噪声。
- `refresh_all_player_data` 仍保留“全量同步服务端真值”的职责，但 UI 刷新不再一律串行阻塞：当前操作所在页面优先立即刷新，其余模块进入合并后的延后刷新队列，避免储纳/历练/炼丹等高频动作被无关模块重建拖慢。
- “全量同步”先更新底层状态容器，再按 scope 决定重建哪些 UI；隐藏页面不应因为数据同步而重建，但已经打开的可见详情面板必须即时刷新，例如术法详情弹窗会在 `spell_system` 更新后单独刷新内容。
- 高频交互遵循“即时反馈优先，全量同步校准”的顺序：
  - 储纳使用物品成功后，先按接口返回的 `used_count / contents` 本地扣减物品、加入礼包产物、刷新储纳格子和输出日志，再触发 `refresh_all_player_data({"priority_scope": "inventory"})` 做跨系统最终校准。
  - 单纯进入储纳页时，如果需要补一次服务端对齐，只刷新 `inventory` scope，并设置 `defer_other_scopes=false`；不要因为打开储纳页而延后重建术法、炼丹、历练、地区等非当前页面 UI。
  - 物品 `effect` 可能影响术法、丹方、丹炉、玩家属性、任务等多个系统，客户端不在即时反馈阶段模拟这些跨系统状态，统一等待全量同步覆盖。
  - 炼丹和百草山这类生产循环，服务端 report 成功后先恢复下一轮生产计时/流程，再做本地背包、日志、进度等展示更新；展示层不能阻塞下一轮循环。
  - 生产循环只会增加对应生产术法的使用次数；术法缩略卡不展示使用次数，因此不重建整页术法 UI，只在详情弹窗当前打开对应术法时更新使用次数文本。
  - 历练结算会通过 `/game/data` 同步玩家、背包、术法、炼丹、历练等底层模型，但只立即刷新历练 scope；若术法详情弹窗正打开，则单独刷新弹窗，不重建术法缩略卡列表。

## 后续结构优化建议（不影响当前运行）

- 当前已经把“页面切换”“数据同步”“初始化编排”“按钮接线”“壳层布局”“节点引用绑定”“模块装配”“共享状态分发”拆到独立 helper；后续若继续拆分，优先考虑继续收纳剩余公共运行态逻辑，而不是再拆业务模块。
- `core/*System.gd` 继续作为状态容器保留，不建议回流到本地权威计算路径。
