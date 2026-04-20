# 登录与初始化

## 职责与边界

- 负责注册、登录、自动登录、刷新 token、进入主场景。
- 只负责“账号与会话入口”，不在登录页维护业务真值状态。
- 登录成功后将服务端返回数据写入 `GameManager` 各系统节点。

## 关键状态与文件

- token：`user://auth_token.dat`
- 服务端地址：`user://server_config.dat`
- 账号输入缓存：`user://account_info.dat`
- 登录成功后目标场景：`res://scenes/app/Main.tscn`

## API 交互

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`

## 功能触发流转

### 1) 打开登录页（`_ready`）

1. 创建 `GameServerAPI`。
2. 绑定按钮事件（登录/注册/服务器地址确认）。
3. 读取并显示当前 API 基址。
4. 执行自动登录检查 `check_auto_login()`。

### 2) 自动登录检查（`check_auto_login`）

1. 读取本地 token（若存在）。
2. 读取本地账号缓存并回填输入框。
3. 若存在 token，调用 `POST /auth/refresh`：
   - 成功：保存新 token，尝试回填账号名，提示“请点击登录按钮继续”。
   - 失败：清 token，提示“请重新登录”。
4. 若不存在 token：提示“请登录账号”。

### 3) 点击登录（`_on_login_pressed`）

1. 校验用户名/密码非空。
2. 调用 `POST /auth/login`。
3. 成功：
   - 保存 token。
   - 保存账号缓存。
   - 更新 `GameManager.account_info`。
   - 将 `result.data` 分发到 `player/inventory/spell/lianli/alchemy`。
   - 切换主场景。
4. 失败：
   - 优先按 reason_code 映射中文提示。
   - 技术异常仅提示通用失败，不显示底层细节。

### 4) 点击注册（`_on_register_pressed`）

1. 先做客户端基础格式校验（长度、字符等）。
2. 调用 `POST /auth/register`。
3. 成功提示“注册成功，请登录”。
4. 失败按 reason_code 映射文案。

### 5) 登录成功后的数据应用（`_apply_game_data`）

1. 读取 `GameManager` 各核心节点引用。
2. 根据 `data` 的各分段，分别调用 `apply_save_data`。
3. 不在登录页做二次推导或本地重算，后续由主界面持续同步。
4. 修炼态以服务端 `player.is_cultivating` 为准：若服务端返回未修炼，主界面会同步清理本地修炼累计运行态，避免残留乐观更新。

## reason_code 文案策略

- 登录/注册业务失败：模块内映射中文提示。
- 技术失败：通过网络层过滤后返回通用提示。
- 不依赖服务端 `message/reason` 作为业务文案来源。

## 失败处理与回退

- refresh 失败：清理 token 并回到显式登录状态。
- login 失败：不切场景，不修改游戏内运行态。
- register 失败：保留输入内容，便于用户修正重试。

## 测试覆盖点

- 用户名未注册/密码错误映射。
- 自动登录 refresh 成功与失败链路。
- 登录成功后数据应用与场景切换。

## 典型触发链路（函数级）

以“点击登录”为例：

1. `LoginUI._on_login_pressed` 做输入校验并发起 `api.login`。
2. `NetworkManager.request` 发送请求，技术错误在网络层被拦截。
3. 返回成功后 `LoginUI._on_login_pressed` 调 `_save_auth_token/_save_account_info`。
4. `LoginUI._apply_game_data` 将 `data.player/inventory/spell_system/lianli_system/alchemy_system` 写入 `GameManager`。
5. `LoginUI._enter_game_scene` 切换到 `res://scenes/app/Main.tscn`。
6. `GameUI._ready` 初始化各模块并触发首轮 `load_game_data + claim_offline_reward`。
