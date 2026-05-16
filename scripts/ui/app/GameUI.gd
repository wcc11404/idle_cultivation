extends Control

# 预加载模块
const ALCHEMY_MODULE_SCRIPT = preload("res://scripts/ui/modules/AlchemyModule.gd")
const SETTINGS_MODULE_SCRIPT = preload("res://scripts/ui/modules/SettingsModule.gd")
const DONGFU_MODULE_SCRIPT = preload("res://scripts/ui/modules/DongfuModule.gd")
const CHUNA_MODULE_SCRIPT = preload("res://scripts/ui/modules/ChunaModule.gd")
const SPELL_MODULE_SCRIPT = preload("res://scripts/ui/modules/SpellModule.gd")
const NEISHI_MODULE_SCRIPT = preload("res://scripts/ui/modules/NeishiModule.gd")
const CULTIVATION_MODULE_SCRIPT = preload("res://scripts/ui/modules/CultivationModule.gd")
const LIANLI_MODULE_SCRIPT = preload("res://scripts/ui/modules/LianliModule.gd")
const HERB_GATHER_MODULE_SCRIPT = preload("res://scripts/ui/modules/HerbGatherModule.gd")
const TASK_MODULE_SCRIPT = preload("res://scripts/ui/modules/TaskModule.gd")
const MAIL_MODULE_SCRIPT = preload("res://scripts/ui/modules/MailModule.gd")
const PROFILE_EDIT_POPUP_SCRIPT = preload("res://scripts/ui/modules/ProfileEditPopup.gd")
const GAME_DATA_COORDINATOR_SCRIPT = preload("res://scripts/ui/app/GameDataCoordinator.gd")
const GAME_TAB_NAVIGATOR_SCRIPT = preload("res://scripts/ui/app/GameTabNavigator.gd")
const GAME_UI_BOOTSTRAP_SCRIPT = preload("res://scripts/ui/app/GameUIBootstrap.gd")
const GAME_UI_WIRING_SCRIPT = preload("res://scripts/ui/app/GameUIWiring.gd")
const GAME_UI_CHROME_SCRIPT = preload("res://scripts/ui/app/GameUIChrome.gd")
const GAME_UI_MODULE_ASSEMBLER_SCRIPT = preload("res://scripts/ui/app/GameUIModuleAssembler.gd")
const GAME_UI_STATE_BINDER_SCRIPT = preload("res://scripts/ui/app/GameUIStateBinder.gd")
const GAME_UI_SCENE_REFS_SCRIPT = preload("res://scripts/ui/app/GameUISceneRefs.gd")
const ACCOUNT_CONFIG_SCRIPT = preload("res://scripts/core/account/AccountConfig.gd")
const UI_FEEDBACK_MANAGER = preload("res://scripts/ui/common/UIFeedbackManager.gd")

var player: Node = null
var inventory: Node = null
var spell_system: Node = null
var api: Node = null
var _silent_item_added_log_depth: int = 0

# 炼丹系统引用
var alchemy_system: Node = null
var recipe_data: Node = null
var alchemy_module = null

# 设置模块
var settings_module = null
var profile_edit_popup: ProfileEditPopup = null

# 地区模块
var region_module = null
var herb_gather_module = null
var task_module = null
var mail_module = null
var notification_badge_state = null
var _notification_badges: Dictionary = {}

# 储纳模块
var chuna_module = null

# 术法模块
var spell_module = null

# 内视模块（新增）
var neishi_module = null

# 修炼突破模块（新增）
var cultivation_module = null
var cultivation_system = null

# 历练模块（新增）
var lianli_module = null
var lianli_system = null

# 境界背景素材配置
const REALM_FRAME_TEXTURES = {
	"炼气期": "res://assets/realm_frames/realm_frame_qi_refining.png",
	"筑基期": "res://assets/realm_frames/realm_frame_foundation.png",
	"金丹期": "res://assets/realm_frames/realm_frame_golden_core.png",
	"元婴期": "res://assets/realm_frames/realm_frame_nascent_soul.png",
	"化神期": "res://assets/realm_frames/realm_frame_spirit_separation.png",
	"炼虚期": "res://assets/realm_frames/realm_frame_void_refining.png",
	"合体期": "res://assets/realm_frames/realm_frame_body_integration.png",
	"大乘期": "res://assets/realm_frames/realm_frame_mahayana.png",
	"渡劫期": "res://assets/realm_frames/realm_frame_tribulation.png"
}

var player_name_label_top: Label = null
var avatar_texture: TextureRect = null
var top_player_info: HBoxContainer = null
var top_bar_background: TextureRect = null
var _top_player_info_readability_panel: Panel = null
var _currency_readability_panel: Panel = null
var safe_top: Control = null
var safe_top_fill: ColorRect = null
var content_frame: Control = null
var safe_bottom: Control = null
var safe_bottom_fill: ColorRect = null
var realm_label: Label = null
var spirit_stone_label: Label = null
var spirit_stone_icon: TextureRect = null
var spirit_stone_delta_label: Label = null
var immortal_crystal_label: Label = null
var immortal_crystal_icon: TextureRect = null
var immortal_crystal_delta_label: Label = null
var _last_spirit_stone_count: int = -1
var _last_immortal_crystal_count: int = -1
var _currency_feedback_initialized: bool = false

var status_label: Label = null
var health_bar: ProgressBar = null
var health_value: Label = null

# 灵气条
var spirit_bar: ProgressBar = null
var spirit_value: Label = null

# 属性标签
var attack_value_label: Label = null
var defense_value_label: Label = null
var speed_value_label: Label = null
var penetration_value_label: Label = null
var hit_value_label: Label = null
var dodge_value_label: Label = null
var crit_value_label: Label = null
var crit_damage_value_label: Label = null
var anti_crit_value_label: Label = null
var spirit_gain_value_label: Label = null
var health_regen_value_label: Label = null

# 修炼小人素材
var cultivation_figure: TextureRect = null
var cultivation_figure_particles: TextureRect = null
var cultivation_visual: Control = null
var cultivation_container: Control = null
var status_area_panel: Control = null
var breakthrough_panel_container: Control = null

var log_text: RichTextLabel = null
var log_filter_tab_shell: PanelContainer = null
var log_filter_tab_bar: HBoxContainer = null
var log_filter_all_button: Button = null
var log_filter_system_button: Button = null
var log_filter_battle_button: Button = null
var log_filter_production_button: Button = null
var log_filter_debug_button: Button = null
var log_copy_debug_button: Button = null
var cultivate_button: Button = null
var breakthrough_button: Button = null
var bottom_bar: HBoxContainer = null
var breakthrough_material_name_label_1: Label = null
var breakthrough_material_name_label_2: Label = null
var breakthrough_material_name_label_3: Label = null
var breakthrough_material_label_1: Label = null
var breakthrough_material_label_2: Label = null
var breakthrough_material_label_3: Label = null

var tab_neishi: Button = null
var tab_chuna: Button = null
var tab_region: Button = null
var tab_lianli: Button = null
var tab_settings: Button = null
var tab_bar: HBoxContainer = null
var neishi_tab_shell: PanelContainer = null
var neishi_tab_bar: HBoxContainer = null
var bottom_spacer: Control = null
var status_header_row: HBoxContainer = null
var breakthrough_header_row: HBoxContainer = null
var status_header_bottom_spacer: Control = null
var status_health_left_pad: Control = null
var status_spirit_left_pad: Control = null
var status_separator_margin: MarginContainer = null
var breakthrough_header_bottom_spacer: Control = null
var breakthrough_materials_margin: MarginContainer = null

var neishi_panel: Control = null
var chuna_panel: Control = null
var region_panel: Control = null
var region_list_host: VBoxContainer = null
var herb_gather_panel: Control = null
var task_panel: Control = null
var lianli_panel: Control = null
var settings_panel: Control = null
var settings_scroll: ScrollContainer = null

# 内室子Tab
var cultivation_tab: Button = null
var spell_tab: Button = null

var cultivation_panel: Control = null
var spell_panel: Control = null
var save_button: Button = null
var fps_30_button: Button = null
var fps_60_button: Button = null
var fps_120_button: Button = null
var fps_144_button: Button = null
var fps_unlimited_button: Button = null
var fps_limit_option_button: OptionButton = null
var music_mute_button: Button = null
var music_volume_slider: HSlider = null
var music_volume_value_label: Label = null
var redeem_code_input: LineEdit = null
var redeem_confirm_button: Button = null
var mailbox_button: Button = null
var mall_button: Button = null
var rank_button: Button = null
var guide_button: Button = null
var logout_button: Button = null
var rank_panel: Control = null
var rank_scroll: ScrollContainer = null
var rank_list: VBoxContainer = null
var back_button: Button = null

var lianli_select_panel: Control = null
var lianli_select_list_host: VBoxContainer = null
var lianli_scene_panel: Control = null

var inventory_grid: GridContainer = null
var capacity_label: Label = null
var expand_button: Button = null
var sort_button: Button = null
var item_detail_panel: Panel = null
# 查看按钮（可选）
var view_button: Button = null
var use_button: Button = null
var batch_use_button: Button = null
var discard_button: Button = null

var lianli_area_1_button: Button = null
var lianli_area_2_button: Button = null
var lianli_area_3_button: Button = null
var lianli_area_4_button: Button = null
var lianli_area_5_button: Button = null
var lianli_area_6_button: Button = null
var endless_tower_button: Button = null

# 炼丹房UI节点
var alchemy_workshop_button: Button = null
var herb_mountain_button: Button = null
var xianwu_office_button: Button = null
var herb_gather_back_button: Button = null
var herb_gather_point_list: VBoxContainer = null
var task_back_button: Button = null
var task_tab_shell: PanelContainer = null
var task_tab_bar: HBoxContainer = null
var task_daily_tab_button: Button = null
var task_newbie_tab_button: Button = null
var task_scroll: ScrollContainer = null
var task_list: VBoxContainer = null
var alchemy_room_panel: Control = null
var recipe_list_container: VBoxContainer = null
var recipe_name_label: Label = null
var success_rate_label: Label = null
var craft_time_label: Label = null
var materials_container: VBoxContainer = null
var craft_button: Button = null
var stop_button: Button = null
var craft_progress_bar: ProgressBar = null
var craft_count_label: Label = null
var count_1_button: Button = null
var count_10_button: Button = null
var count_100_button: Button = null
var count_max_button: Button = null
var count_plus_10_button: Button = null
var count_final_max_button: Button = null
var alchemy_info_label: Label = null
var furnace_info_label: Label = null
var alchemy_back_button: Button = null

# 区域按钮列表
var lianli_area_buttons: Array = []
var lianli_area_ids: Array = []

var player_name_label: Label = null
var player_health_bar_lianli: ProgressBar = null
var player_health_value_lianli: Label = null
var enemy_name_label: Label = null
var enemy_health_bar: ProgressBar = null
var enemy_health_value: Label = null
var lianli_status_label: Label = null

# BattleInfo UI控件
var area_name_label: Label = null
var reward_info_label: Label = null

# BattleButtonContainer UI控件
var continuous_checkbox: CheckBox = null
var continue_button: Button = null
var lianli_speed_button: Button = null
var exit_lianli_button: Button = null

var log_manager: LogManager = null

const GRID_COLS = 5
const DESIGN_CONTENT_SIZE := Vector2(720.0, 1280.0)
const LOG_MAX_COUNT_DEFAULT := 500
const SYSTEM_REFRESH_INTERVAL_SECONDS := 30.0

var item_data_ref: Node = null
var spell_data_ref: Node = null
var lianli_area_data: Node = null
var enemy_data: Node = null

var current_lianli_area_id: String = ""
var active_mode: String = "none"
var allow_background_server_refresh: bool = true
var _test_shutdown_requested: bool = false
var _pending_refresh_all_player_data_count: int = 0
var _pending_notification_refresh_count: int = 0
var _network_ui_last_log_at: float = 0.0
var perf_debug_enabled: bool = OS.is_debug_build()
var _system_refresh_timer: Timer = null
var _system_refresh_inflight: bool = false
var _deferred_refresh_scopes: Dictionary = {}
var _deferred_refresh_scheduled: bool = false
var _game_data_coordinator = GAME_DATA_COORDINATOR_SCRIPT.new()
var _game_tab_navigator = GAME_TAB_NAVIGATOR_SCRIPT.new()
var _game_ui_bootstrap = GAME_UI_BOOTSTRAP_SCRIPT.new()
var _game_ui_wiring = GAME_UI_WIRING_SCRIPT.new()
var _game_ui_chrome = GAME_UI_CHROME_SCRIPT.new()
var _game_ui_module_assembler = GAME_UI_MODULE_ASSEMBLER_SCRIPT.new()
var _game_ui_state_binder = GAME_UI_STATE_BINDER_SCRIPT.new()
var _game_ui_scene_refs = GAME_UI_SCENE_REFS_SCRIPT.new()
const NETWORK_UI_LOG_THROTTLE_SECONDS := 2.0

func _ready():
	await _game_ui_bootstrap.initialize(self)

func _bind_scene_refs() -> void:
	_game_ui_scene_refs.bind(self)

func _setup_optional_nodes():
	_game_ui_chrome.setup_optional_nodes(self)


func _setup_notification_badges() -> void:
	_game_ui_chrome.setup_notification_badges(self)


func _on_notification_badge_state_changed(state: Dictionary) -> void:
	_apply_notification_badge_state(state)


func _apply_notification_badge_state(state: Dictionary) -> void:
	for key in _notification_badges.keys():
		var badge_info: Dictionary = _notification_badges[key]
		var badge: Control = badge_info.get("root", null)
		if not badge:
			continue
		var visible := bool(state.get(key, false))
		badge.visible = visible
		if not bool(badge_info.get("show_count", false)):
			continue
		var count_label: Label = badge_info.get("label", null)
		if count_label:
			var count_key := str(badge_info.get("count_key", ""))
			count_label.text = _format_notification_badge_count(int(state.get(count_key, 0))) if visible else ""


func _format_notification_badge_count(count: int) -> String:
	if count <= 0:
		return ""
	if count > 99:
		return "99+"
	return str(count)

func _setup_bottom_tab_layout():
	_game_ui_chrome.setup_bottom_tab_layout(self)

func _setup_neishi_sub_tab_layout():
	_game_ui_chrome.setup_neishi_sub_tab_layout(self)

func _on_viewport_size_changed():
	_game_ui_chrome.on_viewport_size_changed(self)

func update_font_sizes():
	# 主界面常驻字体回归固定设计稿字号，不再按真实屏幕宽度二次缩放。
	return

func _apply_safe_area_layout():
	_game_ui_chrome.apply_safe_area_layout(self)

func _setup_cultivation_visual_auto_center():
	_game_ui_chrome.setup_cultivation_visual_auto_center(self)

func _on_cultivation_layout_changed():
	_game_ui_chrome.on_cultivation_layout_changed(self)

func _reposition_cultivation_visual_between_panels():
	_game_ui_chrome.reposition_cultivation_visual_between_panels(self)

func _process(delta: float):
	# 更新UI
	if player:
		update_ui()

func setup_log_manager():
	log_manager = LogManager.new()
	log_manager.name = "LogManager"
	add_child(log_manager)
	log_manager.set_max_log_count(LOG_MAX_COUNT_DEFAULT)
	log_manager.perf_debug_enabled = perf_debug_enabled
	log_manager.set_rich_text_label(log_text)
	_setup_log_filter_tabs()

func _setup_log_filter_tabs():
	_ensure_debug_log_filter_button()
	_game_ui_chrome.setup_log_filter_tabs(self)
	_game_ui_wiring.setup_log_filter_connections(self)
	_apply_log_filter("all")

func _set_log_filter_tabs_disabled(all_sel: bool, system_sel: bool, battle_sel: bool, production_sel: bool, debug_sel: bool):
	if log_filter_all_button:
		log_filter_all_button.disabled = all_sel
	if log_filter_system_button:
		log_filter_system_button.disabled = system_sel
	if log_filter_battle_button:
		log_filter_battle_button.disabled = battle_sel
	if log_filter_production_button:
		log_filter_production_button.disabled = production_sel
	if log_filter_debug_button:
		log_filter_debug_button.disabled = debug_sel

func _apply_log_filter(filter_key: String):
	if not log_manager:
		return
	var normalized = String(filter_key).to_lower()
	log_manager.set_filter(normalized)
	match normalized:
		"system":
			_set_log_filter_tabs_disabled(false, true, false, false, false)
		"battle":
			_set_log_filter_tabs_disabled(false, false, true, false, false)
		"production":
			_set_log_filter_tabs_disabled(false, false, false, true, false)
		"debug":
			_set_log_filter_tabs_disabled(false, false, false, false, true)
		_:
			_set_log_filter_tabs_disabled(true, false, false, false, false)
	if log_text:
		UI_FEEDBACK_MANAGER.play_tab_content_in(log_text)

func _on_log_filter_all_pressed():
	_apply_log_filter("all")

func _on_log_filter_system_pressed():
	_apply_log_filter("system")

func _on_log_filter_battle_pressed():
	_apply_log_filter("battle")

func _on_log_filter_production_pressed():
	_apply_log_filter("production")

func _on_log_filter_debug_pressed():
	_apply_log_filter("debug")

func _ensure_debug_log_filter_button():
	if not log_filter_tab_bar:
		return
	if perf_debug_enabled:
		if not log_filter_debug_button:
			var debug_slot := MarginContainer.new()
			debug_slot.name = "LogFilterDebugButtonSlot"
			debug_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			debug_slot.add_theme_constant_override("margin_left", 3)
			debug_slot.add_theme_constant_override("margin_top", 4)
			debug_slot.add_theme_constant_override("margin_right", 3)
			debug_slot.add_theme_constant_override("margin_bottom", 4)

			log_filter_debug_button = Button.new()
			log_filter_debug_button.name = "LogFilterDebugButton"
			log_filter_debug_button.text = "调试"
			log_filter_debug_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			log_filter_debug_button.focus_mode = Control.FOCUS_NONE
			debug_slot.add_child(log_filter_debug_button)
			log_filter_tab_bar.add_child(debug_slot)
		if not log_copy_debug_button:
			var copy_slot := MarginContainer.new()
			copy_slot.name = "LogCopyDebugButtonSlot"
			copy_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			copy_slot.add_theme_constant_override("margin_left", 3)
			copy_slot.add_theme_constant_override("margin_top", 4)
			copy_slot.add_theme_constant_override("margin_right", 3)
			copy_slot.add_theme_constant_override("margin_bottom", 4)

			log_copy_debug_button = Button.new()
			log_copy_debug_button.name = "LogCopyDebugButton"
			log_copy_debug_button.text = "复制调试"
			log_copy_debug_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			log_copy_debug_button.focus_mode = Control.FOCUS_NONE
			log_copy_debug_button.pressed.connect(_on_copy_debug_log_pressed)
			copy_slot.add_child(log_copy_debug_button)
			log_filter_tab_bar.add_child(copy_slot)
	else:
		if log_filter_debug_button:
			var debug_parent := log_filter_debug_button.get_parent()
			if debug_parent:
				debug_parent.queue_free()
			log_filter_debug_button = null
		if log_copy_debug_button:
			var copy_parent := log_copy_debug_button.get_parent()
			if copy_parent:
				copy_parent.queue_free()
			log_copy_debug_button = null


func _on_copy_debug_log_pressed() -> void:
	if not perf_debug_enabled or not log_manager:
		return
	var debug_text := log_manager.get_plain_text_for_filter("debug", 100).strip_edges()
	if debug_text.is_empty():
		return
	DisplayServer.clipboard_set(debug_text)

func perf_debug_log(message: String) -> void:
	if not perf_debug_enabled:
		return
	if log_manager:
		log_manager.add_debug_log(message)

func perf_debug_log_timing(scope: String, elapsed_ms: int, detail: String = "") -> void:
	if not perf_debug_enabled:
		return
	var suffix := " %s" % detail if not detail.is_empty() else ""
	perf_debug_log("%s %dms%s" % [scope, elapsed_ms, suffix])

func set_perf_debug_enabled(enabled: bool) -> void:
	perf_debug_enabled = enabled
	if log_manager:
		log_manager.perf_debug_enabled = enabled
	_ensure_debug_log_filter_button()
	if _system_refresh_timer:
		_system_refresh_timer.paused = enabled
	var net = get_node_or_null("/root/GlobalNetworkManager")
	if net:
		net.perf_debug_sink = self if enabled else null

func setup_button_connections():
	_game_ui_wiring.setup_button_connections(self)

func setup_alchemy_module():
	_game_ui_module_assembler.setup_alchemy_module(self)

func _on_back_to_region_requested():
	"""处理返回地区请求"""
	show_region_tab()

func setup_settings_module():
	_game_ui_module_assembler.setup_settings_module(self)

func setup_mail_module():
	_game_ui_module_assembler.setup_mail_module(self)

func _on_mailbox_requested():
	show_mail_panel()

func _on_mail_back_requested():
	show_settings_tab()


func _on_task_state_changed(claimable_count: int) -> void:
	if notification_badge_state:
		notification_badge_state.update_task_claimable_count(claimable_count)
	if region_module and is_instance_valid(region_module):
		region_module.refresh_cards()


func _on_mail_state_changed(unread_count: int, _total_count: int) -> void:
	if notification_badge_state:
		notification_badge_state.update_mail_unread_count(unread_count)

func setup_profile_edit_popup():
	_game_ui_module_assembler.setup_profile_edit_popup(self)

func _set_children_mouse_filter_ignore(node: Node):
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_filter_ignore(child)

func _on_top_player_info_gui_input(event: InputEvent):
	if not (event is InputEventMouseButton):
		return
	var mb = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_open_profile_edit_popup()
	get_viewport().set_input_as_handled()

func _open_profile_edit_popup():
	if not profile_edit_popup:
		return
	var account_info := {}
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		account_info = game_manager.get_account_info()
	var nickname = str(account_info.get("nickname", "修仙者"))
	var avatar_id = str(account_info.get("avatar_id", ACCOUNT_CONFIG_SCRIPT.get_default_avatar_id()))
	profile_edit_popup.show_popup(nickname, avatar_id)

func _on_profile_popup_closed():
	pass

func _on_profile_nickname_submit_requested(new_nickname: String):
	if not api:
		_on_module_log("接口未初始化，请稍后再试")
		return
	if new_nickname.is_empty():
		_on_module_log("昵称不能为空")
		return
	if new_nickname.length() < 4 or new_nickname.length() > 10:
		_on_module_log("昵称长度应在4-10位之间")
		return
	if " " in new_nickname:
		_on_module_log("昵称不能包含空格")
		return
	if new_nickname.is_valid_int():
		_on_module_log("昵称不能全是数字")
		return

	var result = await api.change_nickname(new_nickname)
	if result.get("success", false):
		_on_module_log(_get_profile_nickname_result_text(result, "昵称修改成功"))
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			var account_info = game_manager.get_account_info()
			account_info["nickname"] = new_nickname
			game_manager.set_account_info(account_info)
		update_account_ui()
	else:
		var err_msg = _get_profile_nickname_result_text(result, "昵称修改失败")
		if not err_msg.is_empty():
			_on_module_log(err_msg)

func _on_profile_avatar_submit_requested(avatar_id: String):
	if not api:
		_on_module_log("接口未初始化，请稍后再试")
		return
	if avatar_id.is_empty():
		_on_module_log("请选择头像")
		return

	var result = await api.change_avatar(avatar_id)
	if result.get("success", false):
		_on_module_log(_get_profile_avatar_result_text(result, "头像更换成功"))
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			var account_info = game_manager.get_account_info()
			account_info["avatar_id"] = avatar_id
			game_manager.set_account_info(account_info)
		update_account_ui()
	else:
		var err_msg = _get_profile_avatar_result_text(result, "头像更换失败")
		if not err_msg.is_empty():
			_on_module_log(err_msg)

func _get_profile_nickname_result_text(result: Dictionary, fallback: String = "昵称修改失败") -> String:
	var reason_code = str(result.get("reason_code", ""))
	match reason_code:
		"ACCOUNT_NICKNAME_CHANGE_SUCCEEDED":
			return "昵称修改成功"
		"ACCOUNT_NICKNAME_EMPTY":
			return "昵称不能为空"
		"ACCOUNT_NICKNAME_LENGTH_INVALID":
			return "昵称长度应在4-10位之间"
		"ACCOUNT_NICKNAME_CONTAINS_SPACE":
			return "昵称不能包含空格"
		"ACCOUNT_NICKNAME_INVALID_CHARACTER":
			return "昵称包含非法字符"
		"ACCOUNT_NICKNAME_ALL_DIGITS":
			return "昵称不能全是数字"
		"ACCOUNT_NICKNAME_SENSITIVE":
			return "昵称包含敏感词汇"
		"ACCOUNT_NICKNAME_PLAYER_NOT_FOUND":
			return "角色数据异常，请重新登录后再试"
		_:
			return api.network_manager.get_api_error_text_for_ui(result, fallback)

func _get_profile_avatar_result_text(result: Dictionary, fallback: String = "头像更换失败") -> String:
	var reason_code = str(result.get("reason_code", ""))
	match reason_code:
		"ACCOUNT_AVATAR_CHANGE_SUCCEEDED":
			return "头像更换成功"
		"ACCOUNT_AVATAR_PLAYER_NOT_FOUND":
			return "角色数据异常，请重新登录后再试"
		_:
			return api.network_manager.get_api_error_text_for_ui(result, fallback)

func setup_region_module():
	_game_ui_module_assembler.setup_region_module(self)

func setup_herb_gather_module():
	_game_ui_module_assembler.setup_herb_gather_module(self)

func setup_task_module():
	_game_ui_module_assembler.setup_task_module(self)

func _on_herb_gather_requested():
	show_herb_gather_panel()

func _on_task_panel_requested():
	show_task_panel()

func setup_chuna_module():
	_game_ui_module_assembler.setup_chuna_module(self)

func setup_spell_module():
	_game_ui_module_assembler.setup_spell_module(self)

func setup_neishi_module():
	_game_ui_module_assembler.setup_neishi_module(self)

func _on_module_log(message: String):
	"""统一处理各模块的日志消息"""
	if log_manager:
		log_manager.add_system_log(message)

func _on_production_log(message: String):
	"""处理生产模块日志消息（采集/炼丹）"""
	if log_manager:
		log_manager.add_production_log(message)

func _bind_network_error_bridge():
	var net = get_node_or_null("/root/GlobalNetworkManager")
	if net:
		net.perf_debug_sink = self
	if net and net.has_signal("technical_error_for_ui"):
		if not net.technical_error_for_ui.is_connected(_on_network_technical_error_for_ui):
			net.technical_error_for_ui.connect(_on_network_technical_error_for_ui)

func _on_network_technical_error_for_ui(_message: String):
	# 统一口子：当前写入富文本日志，后续可在这里切换为弹窗。
	var now_sec = Time.get_unix_time_from_system()
	if now_sec - _network_ui_last_log_at < NETWORK_UI_LOG_THROTTLE_SECONDS:
		return
	_network_ui_last_log_at = now_sec
	if log_manager:
		log_manager.add_system_log("网络错误，请稍后再重试")

func _on_alchemy_log(message: String):
	"""处理炼丹模块的日志消息"""
	if log_manager:
		log_manager.add_production_log(message)

func setup_lianli_module():
	_game_ui_module_assembler.setup_lianli_module(self)

func load_game_data():
	_game_data_coordinator.load_game_data(self)

func set_player(player_node: Node):
	_game_ui_state_binder.set_player(self, player_node)

func set_spell_system(spell_system_node: Node):
	_game_ui_state_binder.set_spell_system(self, spell_system_node)

func set_alchemy_system(alchemy_system_node: Node):
	_game_ui_state_binder.set_alchemy_system(self, alchemy_system_node)

func set_recipe_data(recipe_data_node: Node):
	_game_ui_state_binder.set_recipe_data(self, recipe_data_node)

func set_item_data(item_data_node: Node):
	_game_ui_state_binder.set_item_data(self, item_data_node)

func _on_spell_used(spell_id: String):
	# 通知术法模块更新使用次数
	if spell_module:
		spell_module.on_spell_used(spell_id)

func set_inventory(inventory_node: Node):
	_game_ui_state_binder.set_inventory(self, inventory_node)

func refresh_all_player_data(options: Dictionary = {}):
	await _game_data_coordinator.refresh_all_player_data(self, options)


func schedule_deferred_refresh_scopes(scopes: Array) -> void:
	for scope_variant in scopes:
		var scope := str(scope_variant)
		if scope.is_empty():
			continue
		_deferred_refresh_scopes[scope] = true
	if _deferred_refresh_scheduled:
		return
	_deferred_refresh_scheduled = true
	call_deferred("_flush_deferred_refresh_scopes")


func _flush_deferred_refresh_scopes() -> void:
	_deferred_refresh_scheduled = false
	if _deferred_refresh_scopes.is_empty():
		return
	var scopes := _deferred_refresh_scopes.keys()
	_deferred_refresh_scopes.clear()
	_game_data_coordinator.run_deferred_refresh_scopes(self, scopes)

func _on_item_added(item_id: String, count: int):
	if chuna_module:
		chuna_module.update_inventory_ui()
	update_ui()  # 更新灵石数量显示
	if _silent_item_added_log_depth > 0:
		return
	if log_manager:
		log_manager.add_system_log("获得物品: " + item_data_ref.get_item_name(item_id) + " x" + UIUtils.format_display_number(float(count)))

func begin_silent_item_added_logs():
	_silent_item_added_log_depth += 1

func end_silent_item_added_logs():
	_silent_item_added_log_depth = max(0, _silent_item_added_log_depth - 1)

func show_neishi_tab():
	_game_tab_navigator.show_neishi_tab(self)

func show_chuna_tab():
	_game_tab_navigator.show_chuna_tab(self)

func show_region_tab():
	_game_tab_navigator.show_region_tab(self)

func show_lianli_tab():
	_game_tab_navigator.show_lianli_tab(self)

func show_settings_tab():
	_game_tab_navigator.show_settings_tab(self)

func show_mail_panel():
	_game_tab_navigator.show_mail_panel(self)

func show_herb_gather_panel():
	_game_tab_navigator.show_herb_gather_panel(self)

func show_task_panel():
	_game_tab_navigator.show_task_panel(self)

func _on_tab_neishi_pressed():
	show_neishi_tab()

func _on_tab_chuna_pressed():
	show_chuna_tab()

func _on_tab_region_pressed():
	show_region_tab()

func _on_tab_lianli_pressed():
	show_lianli_tab()

func _on_tab_settings_pressed():
	show_settings_tab()

func _setup_system_refresh_timer():
	if _system_refresh_timer:
		return
	_system_refresh_timer = Timer.new()
	_system_refresh_timer.wait_time = SYSTEM_REFRESH_INTERVAL_SECONDS
	_system_refresh_timer.one_shot = false
	_system_refresh_timer.autostart = true
	add_child(_system_refresh_timer)
	_system_refresh_timer.paused = perf_debug_enabled
	_system_refresh_timer.timeout.connect(_on_system_refresh_timer_timeout)

func _on_system_refresh_timer_timeout():
	if perf_debug_enabled:
		return
	if _system_refresh_inflight:
		return
	if not api:
		return
	_system_refresh_inflight = true
	await _refresh_notification_badges_from_server()
	_system_refresh_inflight = false


func _refresh_notification_badges_from_server() -> void:
	await _game_data_coordinator.refresh_notification_badges_from_server(self)


func clear_notification_badges() -> void:
	if notification_badge_state:
		notification_badge_state.reset()


func _count_claimable_tasks_from_result(result: Dictionary) -> int:
	var count := 0
	for list_key in ["daily_tasks", "newbie_tasks"]:
		var tasks: Array = result.get(list_key, [])
		for task_variant in tasks:
			if not (task_variant is Dictionary):
				continue
			var task := task_variant as Dictionary
			if bool(task.get("completed", false)) and not bool(task.get("claimed", false)):
				count += 1
	return count

func set_active_mode(mode: String):
	active_mode = mode

func clear_active_mode(mode: String):
	if active_mode == mode:
		active_mode = "none"

func can_enter_mode(target_mode: String) -> Dictionary:
	if active_mode == "none" or active_mode == target_mode:
		return {"ok": true, "message": ""}

	match active_mode:
		"cultivation":
			return {"ok": false, "message": "请先停止修炼"}
		"alchemy":
			return {"ok": false, "message": "请先停止炼丹"}
		"lianli":
			return {"ok": false, "message": "请先结束历练"}
		_:
			return {"ok": false, "message": "当前有进行中的操作"}

# 初始化历练区域按钮
func _init_lianli_area_buttons():
	if lianli_module and is_instance_valid(lianli_module):
		lianli_module.refresh_selection_cards(dungeon_info_cache)

# 副本信息缓存
var dungeon_info_cache: Dictionary = {}

func sync_dungeon_info_cache_from_lianli_system() -> void:
	if not lianli_system:
		return
	var daily_data = lianli_system.daily_dungeon_data if lianli_system.get("daily_dungeon_data") != null else {}
	if not (daily_data is Dictionary):
		return
	for dungeon_id in daily_data.keys():
		var raw_info = daily_data.get(dungeon_id, {})
		if not (raw_info is Dictionary):
			continue
		dungeon_info_cache[dungeon_id] = {
			"remaining_count": int(raw_info.get("remaining_count", 0)),
			"max_count": int(raw_info.get("max_count", 3))
		}

# 更新副本按钮文本（只使用缓存数据）
func _update_dungeon_button_text(button: Button, dungeon_id: String, area_name: String):
	if not button:
		return
	var cached_info = dungeon_info_cache.get(dungeon_id, {"remaining_count": 3, "max_count": 3})
	var remaining = int(cached_info.get("remaining_count", 3))
	var max_count = int(cached_info.get("max_count", 3))
	button.text = area_name + " (剩余: " + UIUtils.format_display_number_integer(float(remaining)) + " / " + UIUtils.format_display_number_integer(float(max_count)) + ")"

func _refresh_lianli_info_from_server():
	if not api:
		return

	var cave_result = await api.lianli_foundation_herb_cave()
	if cave_result.get("success", false):
		dungeon_info_cache["foundation_herb_cave"] = {
			"remaining_count": int(cave_result.get("remaining_count", 0)),
			"max_count": int(cave_result.get("max_count", 3))
		}

	var tower_result = await api.lianli_tower()
	if tower_result.get("success", false):
		if lianli_system:
			lianli_system.tower_highest_floor = int(tower_result.get("highest_floor", lianli_system.tower_highest_floor))
		if lianli_module and lianli_module.lianli_system:
			lianli_module.lianli_system.tower_highest_floor = int(tower_result.get("highest_floor", lianli_module.lianli_system.tower_highest_floor))

	update_lianli_area_buttons_display()

func set_background_server_refresh_enabled(enabled: bool) -> void:
	allow_background_server_refresh = enabled

func begin_test_shutdown() -> void:
	_test_shutdown_requested = true
	allow_background_server_refresh = false
	clear_notification_badges()

func has_pending_test_tasks() -> bool:
	var alchemy_pending := false
	if alchemy_module and is_instance_valid(alchemy_module):
		alchemy_pending = bool(alchemy_module.has_pending_test_tasks())
	var chuna_pending := false
	if chuna_module and is_instance_valid(chuna_module) and chuna_module.has_method("has_pending_test_tasks"):
		chuna_pending = bool(chuna_module.has_pending_test_tasks())
	var lianli_pending := false
	if lianli_module and is_instance_valid(lianli_module) and lianli_module.has_method("has_pending_test_tasks"):
		lianli_pending = bool(lianli_module.has_pending_test_tasks())
	return _pending_refresh_all_player_data_count > 0 or _pending_notification_refresh_count > 0 or alchemy_pending or chuna_pending or lianli_pending

func await_pending_test_tasks(max_frames: int = 120) -> void:
	var remaining_frames = max_frames
	while remaining_frames > 0 and has_pending_test_tasks():
		remaining_frames -= 1
		await get_tree().process_frame

# 更新历练区域按钮显示（用于刷新每日次数等）
func update_lianli_area_buttons_display():
	if lianli_module and is_instance_valid(lianli_module):
		lianli_module.refresh_selection_cards(dungeon_info_cache)

# ==================== 无尽塔功能 ====================

# 初始化无尽塔按钮
func _init_endless_tower_button():
	if lianli_module and is_instance_valid(lianli_module):
		lianli_module.refresh_selection_cards(dungeon_info_cache)

func _on_craft_count_changed(count: int):
	if alchemy_module:
		alchemy_module.set_craft_count(count)

func _on_craft_count_min():
	if alchemy_module:
		alchemy_module.set_craft_count_to_min()

func _on_craft_count_delta(delta: int):
	if alchemy_module:
		alchemy_module.adjust_craft_count(delta)

# 炼制数量Max
func _on_craft_count_max():
	if alchemy_module:
		alchemy_module.set_craft_count_to_max()

func update_ui():
	if not player:
		return
	
	var status = player.get_status_dict()
	
	# 根据境界和层数显示不同的文本（使用RealmSystem查表）
	var game_manager = get_node_or_null("/root/GameManager")
	var realm_system = game_manager.get_realm_system() if game_manager else null
	var level_name = ""
	if realm_system:
		level_name = realm_system.get_level_name(status.realm, status.realm_level)
	else:
		# 备用逻辑：如果无法获取realm_system，使用默认格式
		if status.realm_level == 10:
			level_name = "大圆满"
		else:
			level_name = "第" + str(status.realm_level) + "层"
	realm_label.text = status.realm + " " + level_name
	
	# 更新境界背景图片
	update_realm_background(status.realm)
	
	var stone_count = 0
	var immortal_crystal_count = 0
	if inventory:
		stone_count = inventory.get_item_count("spirit_stone")
		immortal_crystal_count = inventory.get_item_count("immortal_crystal")
		_ensure_currency_delta_labels()
		spirit_stone_label.text = UIUtils.format_display_number(float(stone_count))
	if immortal_crystal_label:
		immortal_crystal_label.text = UIUtils.format_display_number(float(immortal_crystal_count))
	_update_currency_feedback(stone_count, immortal_crystal_count)
	_update_top_bar_readability_backgrounds()
	
	# 更新修炼面板显示（通过CultivationModule）
	if cultivation_module:
		cultivation_module.update_display(status)

func _update_currency_feedback(stone_count: int, immortal_crystal_count: int) -> void:
	if not _currency_feedback_initialized:
		_last_spirit_stone_count = stone_count
		_last_immortal_crystal_count = immortal_crystal_count
		_currency_feedback_initialized = true
		return
	if spirit_stone_label and stone_count != _last_spirit_stone_count:
		var stone_delta := stone_count - _last_spirit_stone_count
		UI_FEEDBACK_MANAGER.play_value_bump(spirit_stone_label, 1 if stone_delta > 0 else -1)
		_play_spirit_stone_delta(stone_delta)
	if immortal_crystal_label and immortal_crystal_count != _last_immortal_crystal_count:
		var crystal_delta := immortal_crystal_count - _last_immortal_crystal_count
		UI_FEEDBACK_MANAGER.play_value_bump(immortal_crystal_label, 1 if crystal_delta > 0 else -1)
		_play_immortal_crystal_delta(crystal_delta)
	_last_spirit_stone_count = stone_count
	_last_immortal_crystal_count = immortal_crystal_count

func _play_spirit_stone_delta(delta: int) -> void:
	if delta == 0:
		return
	_ensure_currency_delta_labels()
	if not spirit_stone_delta_label:
		return
	_play_currency_delta_label(spirit_stone_delta_label, delta)

func _play_immortal_crystal_delta(delta: int) -> void:
	if delta == 0:
		return
	_ensure_currency_delta_labels()
	if not immortal_crystal_delta_label:
		return
	_play_currency_delta_label(immortal_crystal_delta_label, delta)

func _play_currency_delta_label(delta_label: Label, delta: int) -> void:
	var sign := "+" if delta > 0 else "-"
	delta_label.text = sign + UIUtils.format_display_number(abs(float(delta)))
	delta_label.modulate = Color(0.16, 0.62, 0.24, 1.0) if delta > 0 else Color(0.82, 0.22, 0.18, 1.0)
	delta_label.scale = Vector2.ONE
	var tween := delta_label.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(delta_label, "scale", Vector2(1.08, 1.08), 0.08)
	tween.chain().tween_property(delta_label, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(delta_label, "modulate:a", 0.0, 0.65).set_delay(0.35)
	tween.finished.connect(func() -> void:
		if is_instance_valid(delta_label):
			delta_label.text = ""
			delta_label.modulate.a = 0.0
	)

func _ensure_currency_delta_labels() -> void:
	if not spirit_stone_delta_label or not is_instance_valid(spirit_stone_delta_label):
		spirit_stone_delta_label = _ensure_currency_delta_label(spirit_stone_label, "SpiritStoneDeltaLabel")
	if not immortal_crystal_delta_label or not is_instance_valid(immortal_crystal_delta_label):
		immortal_crystal_delta_label = _ensure_currency_delta_label(immortal_crystal_label, "ImmortalCrystalDeltaLabel")

func _ensure_currency_delta_label(number_label: Label, label_name: String) -> Label:
	if not number_label:
		return null
	number_label.custom_minimum_size.x = 56.0
	var row := number_label.get_parent()
	if not (row is HBoxContainer):
		return null
	var existing := row.get_node_or_null(label_name)
	if existing is Label:
		(existing as Label).custom_minimum_size.x = 40.0
		return existing as Label
	var delta_label := Label.new()
	delta_label.name = label_name
	delta_label.visible = true
	delta_label.modulate.a = 0.0
	delta_label.text = ""
	delta_label.custom_minimum_size = Vector2(40, 0)
	delta_label.add_theme_font_size_override("font_size", 18)
	delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(delta_label)
	return delta_label

func _ensure_top_bar_readability_backgrounds() -> void:
	if not top_player_info or not top_bar_background:
		return
	var top_bar := top_bar_background.get_parent()
	if not (top_bar is Control):
		return
	var created_panel := false
	if not _top_player_info_readability_panel or not is_instance_valid(_top_player_info_readability_panel):
		_top_player_info_readability_panel = _create_top_bar_readability_panel("PlayerInfoReadabilityPanel")
		top_bar.add_child(_top_player_info_readability_panel)
		created_panel = true
	if not _currency_readability_panel or not is_instance_valid(_currency_readability_panel):
		_currency_readability_panel = _create_top_bar_readability_panel("CurrencyReadabilityPanel")
		top_bar.add_child(_currency_readability_panel)
		created_panel = true
	var top_bar_content := top_player_info.get_parent()
	if created_panel and top_bar_content and top_bar_content.get_parent() == top_bar:
		top_bar.move_child(_top_player_info_readability_panel, top_bar_content.get_index())
		top_bar.move_child(_currency_readability_panel, top_bar_content.get_index())

func _create_top_bar_readability_panel(panel_name: String) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.layout_mode = 1
	panel.z_index = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.94, 0.84, 0.40)
	style.border_color = Color(0.92, 0.82, 0.62, 0.30)
	style.set_corner_radius_all(14)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _update_top_bar_readability_backgrounds() -> void:
	_ensure_top_bar_readability_backgrounds()
	if not _top_player_info_readability_panel or not _currency_readability_panel:
		return
	var top_bar := top_bar_background.get_parent()
	if not (top_bar is Control):
		return
	var currency_target: Control = null
	if spirit_stone_label and spirit_stone_label.get_parent():
		currency_target = spirit_stone_label.get_parent().get_parent() as Control
	var shared_height := _get_top_bar_readability_reference_height(currency_target, top_player_info, Vector2(8, 5))
	_position_top_bar_readability_panel(_top_player_info_readability_panel, top_player_info, top_bar, Vector2(8, 5), shared_height)
	_position_top_bar_readability_panel(_currency_readability_panel, currency_target, top_bar, Vector2(8, 5), shared_height)

func _get_top_bar_readability_reference_height(primary_target: Control, fallback_target: Control, padding: Vector2) -> float:
	var target := primary_target if primary_target else fallback_target
	if not target:
		return 0.0
	return target.get_global_rect().size.y + padding.y * 2.0

func _position_top_bar_readability_panel(panel: Panel, target: Control, top_bar: Control, padding: Vector2, shared_height: float = 0.0) -> void:
	if not panel or not target or not top_bar:
		return
	var target_rect := target.get_global_rect()
	var top_bar_rect := top_bar.get_global_rect()
	var panel_size := target_rect.size + padding * 2.0
	if shared_height > 0.0:
		panel_size.y = shared_height
	var panel_position := target_rect.position - top_bar_rect.position - padding
	if shared_height > 0.0:
		panel_position.y = target_rect.position.y - top_bar_rect.position.y + (target_rect.size.y - shared_height) * 0.5
	panel.position = panel_position
	panel.size = panel_size

func update_realm_background(realm_name: String):
	if not top_bar_background:
		return

	var texture_path = REALM_FRAME_TEXTURES.get(realm_name, REALM_FRAME_TEXTURES["筑基期"])
	var texture = load(texture_path)
	if texture:
		top_bar_background.texture = texture
		if safe_top_fill:
			safe_top_fill.color = Color(0, 0, 0, 1)

# 修炼按钮处理已迁移到 CultivationModule

## 刷新储纳UI
func refresh_inventory_ui():
	if chuna_module:
		chuna_module.update_inventory_ui()

# 突破按钮处理已迁移到 CultivationModule

func _on_account_logged_in(account_info: Dictionary):
	update_account_ui()

func update_account_ui():
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		return
	
	# 从GameManager中获取账号信息
	var account_info = game_manager.get_account_info()
	
	# 更新昵称显示
	var nickname = account_info.get("nickname", "hsams")
	if player_name_label_top:
		player_name_label_top.text = nickname
	
	# 更新头像显示
	var avatar_id = account_info.get("avatar_id", "abstract")
	if avatar_texture:
		var avatar_path = ACCOUNT_CONFIG_SCRIPT.get_avatar_path(avatar_id)
		var texture = load(avatar_path)
		if texture:
			avatar_texture.texture = texture
		# 头像加载失败不提示

func claim_offline_reward():
	await _game_data_coordinator.claim_offline_reward(self)

func _get_offline_reward_result_message(result: Dictionary, fallback: String = "") -> String:
	var reason_code = str(result.get("reason_code", ""))
	match reason_code:
		"GAME_OFFLINE_REWARD_GRANTED":
			return ""
		"GAME_OFFLINE_REWARD_SKIPPED_SHORT_OFFLINE":
			return ""
		_:
			return api.network_manager.get_api_error_text_for_ui(result, fallback)

# 内视子Tab处理已迁移到 NeishiModule
