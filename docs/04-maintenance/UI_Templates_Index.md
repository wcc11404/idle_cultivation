# UI 模板索引

本文记录客户端当前可复用的 UI 模板与使用约束，作为内视页面及后续模块 UI 改造的统一基线。

## 模板清单

### 1) `BottomTabBarStyleTemplate`

- 路径：`scripts/ui/common/BottomTabBarStyleTemplate.gd`
- 用途：统一主底部 Tab、日志筛选、任务页切换这类“线型 Tab”的样式、字号、分割线位置与选中态颜色。
- 核心约束：
  - 按钮宽度自动均分，`separation=0`。
  - 选中态仍由 `disabled=true` 驱动（当前项目约定）。
  - `line_position` 支持 `top/bottom`，用于不同线型 Tab 复用。

### 2) `TopTabBarStyleTemplate`

- 路径：`scripts/ui/common/TopTabBarStyleTemplate.gd`
- 用途：统一页内上方分段切换栏，例如“修炼/术法”以及后续“弟子/日常/宝库”这类金色选中块样式。
- 核心约束：
  - 选中态仍由 `disabled=true` 驱动（当前项目约定）。
  - 按钮宽度自动均分，适合 2~4 个同级页内子栏位。
  - 默认视觉为“浅底板 + 金色选中块 + 深棕未选中文字”。
  - 结构上使用“外层壳 + Slot + 内层按钮”模式，保证选中块比外层壳小一圈，不直接让按钮贴满父 `HBoxContainer`。
- 当前应用：
  - 内视页：`修炼 / 术法`
  - 仙务司：`每日任务 / 新手任务`
  - 日志区：`全部 / 系统 / 战斗 / 生产`

### 3) `DisplayPanelTemplate`

- 路径：`scripts/ui/common/DisplayPanelTemplate.gd`
- 用途：统一“展示面板”的标题行（左强调线 + 标题 + 分割线）与内容对齐规则。
- 核心约束：
  - 内容左侧对齐基线：`DEFAULT_CONTENT_LEFT_INSET = 12`
  - 标题下方留白：`DEFAULT_HEADER_BOTTOM_GAP = 8`
  - 后续新增内容必须遵循“标题首字左侧对齐 + 固定留白”。
- 当前应用：
  - 修炼页属性面板
  - 修炼页突破面板

### 4) `SpellThumbnailTemplate`

- 路径：`scripts/ui/common/SpellThumbnailTemplate.gd`
- 用途：统一术法缩略卡样式。
- 当前默认：
  - 卡片底色：优化后的米金底，边框按 `rarity` 轻微染色。
  - 已装备术法使用更明显的金色边框，并在左上角显示 `已装备` 徽章。
  - 顶部细色条承接稀有度颜色，右上角星级以 `★N` 徽章展示；无星不占大块空间。
  - 五行信息保持 `图标 + 金木水火土无`，放在轻浅底托中。
  - 正式术法页使用四列缩略卡网格，避免五列布局压缩卡片内容。
- 使用约束：
  - 术法详情入口统一为点击整张缩略卡；不再新增 `查看` 按钮。
  - 五行底托、元素图标、元素文字必须 `mouse_filter=IGNORE`，不能拦截整卡点击。
  - 非生产术法底部只保留 `EquipButton`，由 `SpellModule` 控制 `装备 / 卸下 / 禁用` 状态。
  - 生产术法不显示底部按钮，但仍可点击整卡查看详情。
  - 缩略卡内的 `EquipButton` 不接入按压缩放反馈，避免装备/卸下后和卡片刷新叠加造成布局抖动错觉。
  - 已装备态只改变边框颜色，不改变边框宽度。
  - `StatusLabel / EquipButton / MetaRow` 等关键节点名需保持，避免破坏测试和模块引用。

### 5) `PopupStyleTemplate`

- 路径：`scripts/ui/common/PopupStyleTemplate.gd`
- 用途：统一弹窗面板样式、装饰壳层与遮罩视觉（外部暗化）。
- 当前默认：
  - 正式弹窗使用装饰模板：最小尺寸 `500 x 350`，内容自适应扩展。
  - 弹窗底板：米金色不透明底，浅金标题分割线，淡金云纹覆盖层，四角金色角饰骑在边框外侧。
  - 云纹使用 `STRETCH_KEEP_ASPECT_COVERED`，避免术法详情这类高弹窗把纹样纵向拉伸变形。
  - 装饰层全部不接收鼠标输入，前景内容拦截输入，确保点击弹窗内部不会关闭，点击暗区才关闭。
  - 全屏遮罩暗化，正式弹窗当前统一使用较深暗度以突出前景。
  - 当传入外部点击回调时，遮罩层会拦截输入，并且只在点击弹窗外暗区时触发关闭；不能再把点击透传到底层界面
- 当前应用：
  - 术法详情弹窗 `SpellDetailPopup`
  - 顶部账号编辑弹窗 `ProfileEditPopup`（昵称/头像）
  - 邮件详情/确认弹窗 `MailModule`
  - 储纳丢弃确认/批量使用弹窗 `ChunaModule`
  - 调试预览场景 `PopupDecorDemo` / `InteractionP0Demo`
- 使用约束：
  - 新增正式弹窗必须优先走 `build_decorated_popup()`，不要再手写裸 `Panel` 小弹窗。
  - 不再按 `compact / normal / tall` 做固定三档；统一依赖最小尺寸 + 内容自适应。
  - 底部按钮区需要保留足够下边距，避免和角饰重叠。
  - 分割线颜色统一使用模板标题分割线口径，不要混入灰色分割线。

### 6) `AreaEntryCard`

- 路径：`scripts/ui/common/AreaEntryCard.gd`
- 用途：统一地区页、历练页这类“进入某区域/副本/功能房间”的大卡入口。
- 当前默认：
  - 顶部图片区 + 左上名称签 + 右上大字占位
  - 正文区不再重复主标题；图片签承担卡片名称
  - 正文区副标题左对齐，用于显示 `今日剩余次数 x/y`、`当前挑战 第N层` 这类短状态
  - 标签托盘 + 主动作按钮 + 可选锁定原因
  - 卡片宽度按单列大卡适配移动端纵向界面
- 当前应用：
  - 地区页：`仙务司 / 炼丹坊 / 赌坊 / 百草山`
  - 历练页：普通区域、`破境草洞穴`、`南麓试练塔`
- 使用约束：
  - 业务模块只负责组装 `title / title_suffix / description / tags / button_text / disabled / disabled_reason`
  - 图片区左上名称签应显示面向玩家的 `name`，不要写 `图片占位`，也不要为特殊区域引入 `tower_name` 这类只服务 UI 的字段名。
  - 不要回退到在 `Main.tscn` 里摆死静态入口按钮
  - 若同类入口需要分组标题（如 `云稷城 / 云稷城南`、`普通区域 / 每日区域 / 特殊区域`），应由业务模块在卡片列表外层组织，不塞进模板内部

### 7) `ActionButtonTemplate`

- 路径：`scripts/ui/common/ActionButtonTemplate.gd`
- 用途：统一四类关键行为按钮配色与交互态（normal/hover/pressed/disabled），避免各模块重复写色值。
- 预设清单：
  - `PRESET_CULTIVATION_YELLOW`：开始/停止修炼黄按钮
  - `PRESET_BREAKTHROUGH_RED`：突破红按钮
  - `PRESET_ALCHEMY_GREEN`：开始炼制绿按钮
  - `PRESET_PROFILE_BLUE`：变更昵称蓝按钮
  - `PRESET_LIGHT_NEUTRAL`：淡白按钮（返回/整理/FPS 默认）
  - `PRESET_LIGHT_NEUTRAL_SELECTED`：淡白按钮选中态（FPS 当前档位）
  - `PRESET_SPELL_VIEW_BROWN`：术法详情弹窗 `+`/`x10` 等棕色辅助按钮
- 使用约束：
  - 业务侧只允许改按钮文字与尺寸（`custom_minimum_size` / `font_size`）。
  - 颜色、边框、圆角、状态色统一由模板提供，不在业务模块内手写。
- 当前应用：
  - 内视修炼按钮（黄）与突破按钮（红）
  - 炼丹房开始炼制（绿）、停止（红）、返回（淡白）
  - 账号编辑弹窗变更昵称/变更头像按钮（蓝）
  - 储纳：使用（黄）、丢弃（红）、扩容（黄）、整理（淡白）
  - 术法缩略卡：装备/卸下（黄/红，详情入口为整卡点击）
  - 术法详情弹窗：升级（黄）、关闭（红）、`+`/`x10`（棕色）
  - 设置：FPS 档位按钮（淡白 + 选中态）、排行榜返回（淡白）

### 8) 动态红点约定

- 路径：`scripts/ui/common/NotificationBadgeState.gd` + `GameUI` 运行时挂载
- 用途：统一管理入口按钮 / Tab 的提醒标记
- 当前一期接入：
  - `地区 Tab`
  - `设置 Tab`
  - `仙务司` 按钮
  - `邮箱` 按钮
- 当前视觉约定：
  - 一级入口（Tab）：小红点，不显示数字
  - 二级入口（按钮）：大号数字红点，尺寸约为一级红点 3 倍，数字显示在红点内部
  - 数字封顶：`99+`
- 使用约束：
  - 模块只允许上报摘要状态，不直接操作红点节点
  - 红点节点运行时动态创建，不直接改 `Main.tscn`
- 只有二级入口允许显示数字；一级入口仍保持纯红点

## 性能诊断日志（DEBUG ONLY）

- 主入口：`GameUI.gd` / `GameDataCoordinator.gd` / `NetworkManager.gd`
- 日志承载：`LogManager.gd` 的 `调试` 频道
- 用途：在手机等不方便看控制台的环境里，把关键链路耗时直接打印到富文本日志区域
- 当前埋点范围：
  - 网络请求耗时（`NetworkManager.request`）
  - 全量同步耗时（`refresh_all_player_data` / `load_game`）
  - 背包格子重建耗时
  - 术法列表重建耗时
  - 日志富文本重绘耗时（超阈值时）
- 启用规则：
  - 当前由 `GameUI.perf_debug_enabled = OS.is_debug_build()` 控制
  - 正式 release 构建默认不启用
  - 自动化测试环境会显式关闭，避免污染断言日志
- 使用约束：
  - 仅用于阶段性性能排查，不作为正式玩家可见功能
  - 诊断模式启用时，会额外暂停 30 秒一次的任务/邮箱后台轮询，降低干扰
  - 调试页签旁会提供 `复制调试` 按钮，直接把当前 `调试` 频道最后 100 条纯文本复制到系统剪贴板
  - 排查完成后，优先关闭或移除具体埋点，再进入正式上线包

### 手感延迟排查方法

- 核心目标：让“玩家点击后服务端已返回，但 UI 过一会儿才动”的问题能在手机上直接定位。
- 推荐观察顺序：
  - 先看网络请求耗时，例如 `network POST /game/inventory/use 168ms`。
  - 再看数据同步耗时，例如 `refresh_all_player_data load_game / total`。
  - 最后看当前操作之后触发了哪些 UI rebuild，例如 `inventory_grid rebuild`、`spell_ui rebuild`。
- 判断口径：
  - 一次进入某页面，原则上只应触发该页面必要请求和必要 UI rebuild。
  - 如果一次点击触发多次相同 API，例如多条 `GET /game/spell/list`，优先排查按钮信号是否被多个模块重复连接、页面 show 函数是否重复调用。
  - 如果一次 API 返回后出现多次相同 UI rebuild，例如连续两条 `spell_ui rebuild`，优先排查“数据刷新函数”和“外层 show/操作完成函数”是否都调用了重建。
  - 当前页面以外的 UI 重建通常应延后、合并，或完全跳过；例如进入储纳页不应顺手重建术法页。
- 优化原则：
  - 高频动作先做当前页面即时反馈，再做全量同步校准。
  - 能更新局部文本时，不重建整页卡片。
  - 生产循环和战斗回放不得被无关 UI rebuild 阻塞。
  - 新增埋点时优先输出“动作名 + 耗时 + 关键数量”，避免无信息量的汇总噪声。

## 当前调试型 UI 工具

### `ResolutionPreview`

- 场景：`scenes/debug/ResolutionPreview.tscn`
- 脚本：`scripts/ui/debug/ResolutionPreview.gd`
- 用途：人工预览长屏 / 异形屏下的登录页与后续主界面布局
- 当前预设：
  - `1080×1920`
  - `1080×2400`
  - `1125×2436`
- 约束：
  - 只作为人工验收工具，不参与正式业务流程
  - 只有从该调试场景进入时才允许改窗口 / 预览分辨率
  - 正常从登录页或项目主入口启动时，不应触发改窗口逻辑

## 使用规则

- 新增同类 UI 时优先复用现有模板，不重复造样式。
- 如果模块必须自定义样式，先保留模板基线，再局部覆盖，不要破坏模板默认契约。
- 涉及模板参数或默认视觉变更时，必须同步更新本文与对应模块文档（`docs/02-modules/*`）。
- 涉及安全区、长屏、异形屏或弹窗尺寸策略变更时，必须同步更新测试文档中的人工验收说明。

## 关联文档

- [修炼与突破](../02-modules/02-cultivation-breakthrough.md)
- [术法](../02-modules/04-spell.md)
- [文档更新规则](./DocUpdateRules.md)
