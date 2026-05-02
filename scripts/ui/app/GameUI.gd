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
const GAME_SERVER_API_SCRIPT = preload("res://scripts/network/GameServerAPI.gd")
const BOTTOM_TAB_BAR_STYLE_TEMPLATE = preload("res://scripts/ui/common/BottomTabBarStyleTemplate.gd")
const TOP_TAB_BAR_STYLE_TEMPLATE = preload("res://scripts/ui/common/TopTabBarStyleTemplate.gd")
const DISPLAY_PANEL_TEMPLATE = preload("res://scripts/ui/common/DisplayPanelTemplate.gd")
const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const NOTIFICATION_BADGE_STATE_SCRIPT = preload("res://scripts/ui/common/NotificationBadgeState.gd")
const ACCOUNT_CONFIG_SCRIPT = preload("res://scripts/core/account/AccountConfig.gd")
const UI_FONT_PROVIDER = preload("res://scripts/ui/common/UIFontProvider.gd")
const UI_ICON_PROVIDER = preload("res://scripts/ui/common/UIIconProvider.gd")
const SAFE_AREA_HELPER = preload("res://scripts/ui/common/SafeAreaHelper.gd")

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

@onready var player_name_label_top: Label = $ContentFrame/VBoxContainer/TopBar/TopBarContent/PlayerInfo/PlayerNameLabel
@onready var avatar_texture: TextureRect = $ContentFrame/VBoxContainer/TopBar/TopBarContent/PlayerInfo/AvatarContainer/AvatarTexture
@onready var top_player_info: HBoxContainer = $ContentFrame/VBoxContainer/TopBar/TopBarContent/PlayerInfo
@onready var top_bar_background: TextureRect = $ContentFrame/VBoxContainer/TopBar/TopBarBackground
@onready var safe_top: Control = $SafeTop
@onready var safe_top_fill: ColorRect = $SafeTop/TopFill
@onready var content_frame: Control = $ContentFrame
@onready var safe_bottom: Control = $SafeBottom
@onready var safe_bottom_fill: ColorRect = $SafeBottom/BottomFill
@onready var realm_label: Label = $ContentFrame/VBoxContainer/TopBar/TopBarContent/RealmContainer/RealmLabel
@onready var spirit_stone_label: Label = $ContentFrame/VBoxContainer/TopBar/TopBarContent/CurrencyContainer/CurrencyValuesCenter/CurrencyValues/SpiritStoneLabel
@onready var spirit_stone_icon: TextureRect = $ContentFrame/VBoxContainer/TopBar/TopBarContent/CurrencyContainer/SpiritStoneIcon
@onready var immortal_crystal_label: Label = $ContentFrame/VBoxContainer/TopBar/TopBarContent/CurrencyContainer/CurrencyValuesCenter/CurrencyValues/ImmortalCrystalLabel

@onready var status_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/CultivationVisual/CultivationStatusLabel
@onready var health_bar: ProgressBar = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/HealthRow/HealthBar
@onready var health_value: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/HealthRow/HealthValue

# 灵气条
@onready var spirit_bar: ProgressBar = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/SpiritRow/SpiritBar
@onready var spirit_value: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/SpiritRow/SpiritValue

# 属性标签
@onready var attack_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow/AttackItem/AttackValueLabel
@onready var defense_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow/DefenseItem/DefenseValueLabel
@onready var speed_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow/SpeedItem/SpeedValueLabel
@onready var penetration_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow2/PenetrationItem/PenetrationValueLabel
@onready var crit_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow2/CritItem/CritValueLabel
@onready var crit_damage_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow2/CritDamageItem/CritDamageValueLabel
@onready var spirit_gain_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow3/SpiritGainItem/SpiritGainValueLabel
@onready var health_regen_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsRow3/HealthRegenItem/HealthRegenValueLabel

# 修炼小人素材
@onready var cultivation_figure: TextureRect = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/CultivationVisual/CultivationFigure
@onready var cultivation_figure_particles: TextureRect = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/CultivationVisual/CultivationFigureParticles
@onready var cultivation_visual: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/CultivationVisual
@onready var cultivation_container: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer
@onready var status_area_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea
@onready var breakthrough_panel_container: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel

@onready var log_text: RichTextLabel = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogText
@onready var log_filter_tab_shell: PanelContainer = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogFilterTopTabShell
@onready var log_filter_tab_bar: HBoxContainer = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogFilterTopTabShell/LogFilterTabBar
@onready var log_filter_all_button: Button = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogFilterTopTabShell/LogFilterTabBar/LogFilterAllButtonSlot/LogFilterAllButton
@onready var log_filter_system_button: Button = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogFilterTopTabShell/LogFilterTabBar/LogFilterSystemButtonSlot/LogFilterSystemButton
@onready var log_filter_battle_button: Button = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogFilterTopTabShell/LogFilterTabBar/LogFilterBattleButtonSlot/LogFilterBattleButton
@onready var log_filter_production_button: Button = $ContentFrame/VBoxContainer/LogArea/LogVBox/LogFilterTopTabShell/LogFilterTabBar/LogFilterProductionButtonSlot/LogFilterProductionButton
@onready var cultivate_button: Button = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughButtonBar/CultivateButton
@onready var breakthrough_button: Button = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughButtonBar/BreakthroughButton
@onready var bottom_bar: HBoxContainer = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughButtonBar
@onready var breakthrough_material_label_1: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughMaterialsMargin/BreakthroughMaterialsRow/BreakthroughMaterialLabel1
@onready var breakthrough_material_label_2: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughMaterialsMargin/BreakthroughMaterialsRow/BreakthroughMaterialLabel2
@onready var breakthrough_material_label_3: Label = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughMaterialsMargin/BreakthroughMaterialsRow/BreakthroughMaterialLabel3

@onready var tab_neishi: Button = $ContentFrame/VBoxContainer/TabBar/NeishiButton
@onready var tab_chuna: Button = $ContentFrame/VBoxContainer/TabBar/ChunaButton
@onready var tab_region: Button = get_node_or_null("ContentFrame/VBoxContainer/TabBar/RegionButton")
@onready var tab_lianli: Button = $ContentFrame/VBoxContainer/TabBar/BattleButton
@onready var tab_settings: Button = $ContentFrame/VBoxContainer/TabBar/SettingsButton
@onready var tab_bar: HBoxContainer = $ContentFrame/VBoxContainer/TabBar
@onready var neishi_tab_shell: PanelContainer = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/NeishiTopTabShell
@onready var neishi_tab_bar: HBoxContainer = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/NeishiTopTabShell/NeishiTabBar
@onready var bottom_spacer: Control = get_node_or_null("ContentFrame/VBoxContainer/BottomSpacer")
@onready var status_header_row: HBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsHeaderRow")
@onready var breakthrough_header_row: HBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughHeaderRow")
@onready var status_header_bottom_spacer: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/HeaderBottomSpacer")
@onready var status_health_left_pad: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/HealthRow/HealthLeftPad")
@onready var status_spirit_left_pad: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/SpiritRow/SpiritLeftPad")
@onready var status_separator_margin: MarginContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/SeparatorMargin")
@onready var breakthrough_header_bottom_spacer: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughHeaderBottomSpacer")
@onready var breakthrough_materials_margin: MarginContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughMaterialsMargin")

@onready var neishi_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel
@onready var chuna_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel
@onready var region_panel: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/RegionPanel")
@onready var herb_gather_panel: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/HerbGatherPanel")
@onready var task_panel: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel")
@onready var lianli_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel
@onready var settings_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel
@onready var settings_scroll: ScrollContainer = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll

# 内室子Tab
@onready var cultivation_tab: Button = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/NeishiTopTabShell/NeishiTabBar/CultivationTabSlot/CultivationTab
@onready var spell_tab: Button = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/NeishiTopTabShell/NeishiTabBar/SpellTabSlot/SpellTab

@onready var cultivation_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer
@onready var spell_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/SpellPanel
@onready var save_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SaveButton")
@onready var fps_30_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/FpsSection/FpsPresetRow/Fps30Button
@onready var fps_60_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/FpsSection/FpsPresetRow/Fps60Button
@onready var fps_120_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/FpsSection/FpsPresetRow/Fps120Button
@onready var fps_144_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/FpsSection/FpsPresetRow/Fps144Button
@onready var fps_unlimited_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/FpsSection/FpsPresetRow/FpsUnlimitedButton
@onready var fps_limit_option_button: OptionButton = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/FpsSection/FpsLimitOptionButton
@onready var music_mute_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/AudioSection/MusicRow/MusicMuteButton
@onready var music_volume_slider: HSlider = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/AudioSection/MusicRow/MusicVolumeSlider
@onready var music_volume_value_label: Label = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/AudioSection/MusicRow/MusicVolumeValueLabel
@onready var redeem_code_input: LineEdit = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/RedeemSection/RedeemCodeRow/RedeemCodeInput
@onready var redeem_confirm_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/RedeemSection/RedeemCodeRow/RedeemConfirmButton
@onready var mailbox_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/ActionButtons/MailboxButton
@onready var mall_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/ActionButtons/MallButton
@onready var rank_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/ActionButtons/RankButton
@onready var guide_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/ActionButtons/GuideButton
@onready var logout_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/VBoxContainer/SettingsScroll/SettingsContentVBox/ActionButtons/LogoutButton
@onready var rank_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/RankPanel
@onready var rank_scroll: ScrollContainer = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/RankPanel/VBoxContainer/RankScroll
@onready var rank_list: VBoxContainer = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/RankPanel/VBoxContainer/RankScroll/RankList
@onready var back_button: Button = $ContentFrame/VBoxContainer/ContentPanel/SettingsPanel/RankPanel/VBoxContainer/TitleBar/BackButton

@onready var lianli_select_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel
@onready var lianli_scene_panel: Control = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel

@onready var inventory_grid: GridContainer = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ScrollContainer/InventoryGrid
@onready var capacity_label: Label = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/TopBar/CapacityLabel
@onready var expand_button: Button = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/TopBar/ExpandButton
@onready var sort_button: Button = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/TopBar/SortButton
@onready var item_detail_panel: Panel = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ItemDetailPanel
# 查看按钮（可选）
var view_button: Button = null
@onready var use_button: Button = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ItemDetailPanel/VBoxContainer/MainHBox/ButtonContainer/ButtonVBox/UseButton
@onready var batch_use_button: Button = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ItemDetailPanel/VBoxContainer/MainHBox/ButtonContainer/ButtonVBox/BatchUseButton
@onready var discard_button: Button = $ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ItemDetailPanel/VBoxContainer/MainHBox/ButtonContainer/ButtonVBox/DiscardButton

@onready var lianli_area_1_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/Area1Button")
@onready var lianli_area_2_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/Area2Button")
@onready var lianli_area_3_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/Area3Button")
@onready var lianli_area_4_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/Area4Button")
@onready var lianli_area_5_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/Area5Button")
@onready var lianli_area_6_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/EndlessTowerButton")
@onready var endless_tower_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel/VBoxContainer/EndlessTowerButton")

# 炼丹房UI节点
@onready var alchemy_workshop_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/RegionPanel/VBoxContainer/AlchemyWorkshopButton")
@onready var herb_mountain_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/RegionPanel/VBoxContainer/HerbMountainButton")
@onready var xianwu_office_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/RegionPanel/VBoxContainer/XianwuOfficeButton")
@onready var herb_gather_back_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/HerbGatherPanel/VBoxContainer/TitleBar/BackButton")
@onready var herb_gather_point_list: VBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/HerbGatherPanel/VBoxContainer/PointScroll/PointList")
@onready var task_back_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TitleBar/BackButton")
@onready var task_tab_shell: PanelContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TitleBar/TaskTopTabShell")
@onready var task_tab_bar: HBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TitleBar/TaskTopTabShell/TaskTabBar")
@onready var task_daily_tab_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TitleBar/TaskTopTabShell/TaskTabBar/DailyTabSlot/DailyTab")
@onready var task_newbie_tab_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TitleBar/TaskTopTabShell/TaskTabBar/NewbieTabSlot/NewbieTab")
@onready var task_scroll: ScrollContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TaskScroll")
@onready var task_list: VBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/TaskPanel/VBoxContainer/TaskScroll/TaskList")
@onready var alchemy_room_panel: Control = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel")
@onready var recipe_list_container: VBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/RecipeListPanel/RecipeListVBox/RecipeScroll/RecipeListContainer")
@onready var recipe_name_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/RecipeNameLabel")
@onready var success_rate_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/SuccessRateLabel")
@onready var craft_time_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CraftTimeLabel")
@onready var materials_container: VBoxContainer = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/MaterialsContainer")
@onready var craft_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/ButtonHBox/CraftButton")
@onready var stop_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/ButtonHBox/StopButton")
@onready var craft_progress_bar: ProgressBar = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CraftProgressBar")
@onready var craft_count_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CraftCountLabel")
@onready var count_1_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CountHBox/Count1Button")
@onready var count_10_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CountHBox/Count10Button")
@onready var count_100_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CountHBox/Count100Button")
@onready var count_max_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CountHBox/CountMaxButton")
@onready var count_plus_10_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CountHBox/CountPlus10Button")
@onready var count_final_max_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/MainHBox/CraftPanel/CraftVBox/CountHBox/CountFinalMaxButton")
@onready var alchemy_info_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/BottomPanel/BottomVBox/BottomHBox/AlchemyInfoLabel")
@onready var furnace_info_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/BottomPanel/BottomVBox/BottomHBox/FurnaceInfoLabel")
@onready var alchemy_back_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/AlchemyRoomPanel/VBoxContainer/TitleBar/BackButton")

# 区域按钮列表
var lianli_area_buttons: Array = []
var lianli_area_ids: Array = []

@onready var player_name_label: Label = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/CombatInfoPanel/CombatInfoMargin/CombatInfoVBox/PlayerInfo/PlayerNameLabel
@onready var player_health_bar_lianli: ProgressBar = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/CombatInfoPanel/CombatInfoMargin/CombatInfoVBox/PlayerInfo/PlayerHealthBar
@onready var player_health_value_lianli: Label = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/CombatInfoPanel/CombatInfoMargin/CombatInfoVBox/PlayerInfo/PlayerHealthValue
@onready var enemy_name_label: Label = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/CombatInfoPanel/CombatInfoMargin/CombatInfoVBox/EnemyInfo/EnemyNameLabel
@onready var enemy_health_bar: ProgressBar = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/CombatInfoPanel/CombatInfoMargin/CombatInfoVBox/EnemyInfo/EnemyHealthBar
@onready var enemy_health_value: Label = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/CombatInfoPanel/CombatInfoMargin/CombatInfoVBox/EnemyInfo/EnemyHealthValue
@onready var lianli_status_label: Label = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/LianliStatusLabel

# BattleInfo UI控件
@onready var area_name_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/AreaInfoPanel/AreaInfoMargin/AreaInfoVBox/AreaInfoContentMargin/AreaInfoContentVBox/AreaNameLabel")
@onready var reward_info_label: Label = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/AreaInfoPanel/AreaInfoMargin/AreaInfoVBox/AreaInfoContentMargin/AreaInfoContentVBox/RewardInfoLabel")

# BattleButtonContainer UI控件
@onready var continuous_checkbox: CheckBox = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/BattleButtonContainer/ContinuousCheckBox")
@onready var continue_button: Button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/BattleButtonContainer/ContinueButton")
@onready var lianli_speed_button: Button = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/BattleButtonContainer/SpeedExitContainer/LianliSpeedButton
@onready var exit_lianli_button: Button = $ContentFrame/VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel/VBoxContainer/BattleButtonContainer/SpeedExitContainer/ExitLianliButton

var log_manager: LogManager = null

const GRID_COLS = 5
const DESIGN_CONTENT_SIZE := Vector2(720.0, 1280.0)
const LOG_MAX_COUNT_DEFAULT := 500
const SYSTEM_REFRESH_INTERVAL_SECONDS := 30.0
const BADGE_COLOR := Color(0.9059, 0.2980, 0.2353, 1.0)
const BADGE_BORDER_COLOR := Color(1.0, 0.9608, 0.9412, 1.0)
const BADGE_TEXT_COLOR := Color(1.0, 0.9804, 0.9725, 1.0)

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
var _system_refresh_timer: Timer = null
var _system_refresh_inflight: bool = false
const NETWORK_UI_LOG_THROTTLE_SECONDS := 2.0

func _ready():
	UI_FONT_PROVIDER.apply_to_root(self)
	if spirit_stone_icon:
		spirit_stone_icon.texture = UI_ICON_PROVIDER.load_svg_texture(UI_ICON_PROVIDER.ICON_SPIRIT_STONE)
	# 安全获取可选节点
	_setup_optional_nodes()
	_setup_notification_badges()
	_setup_bottom_tab_layout()
	_setup_neishi_sub_tab_layout()
	
	# 初始化GameServerAPI
	api = GAME_SERVER_API_SCRIPT.new()
	add_child(api)
	
	await get_tree().process_frame
	_bind_network_error_bridge()
	
	# 先初始化所有模块
	setup_log_manager()
	setup_alchemy_module()
	setup_settings_module()
	setup_profile_edit_popup()
	setup_region_module()
	setup_herb_gather_module()
	setup_task_module()
	setup_mail_module()
	setup_chuna_module()
	setup_spell_module()
	setup_neishi_module()
	setup_lianli_module()
	
	# 再连接按钮信号（模块已创建）
	setup_button_connections()
	
	# 显示默认内视页面（模块初始化完成后）
	show_neishi_tab()
	
	# 在log_manager初始化后添加欢迎消息
	if log_manager:
		log_manager.add_system_log("欢迎来到修仙世界！")
		log_manager.add_system_log("点击下方按钮开始修炼")
	
	# 加载游戏数据（模块初始化完成后）
	load_game_data()
	
	# 游戏加载完成后获取离线奖励
	await claim_offline_reward()
	await _refresh_notification_badges_from_server()

func _setup_optional_nodes():
	view_button = get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ItemDetailPanel/VBoxContainer/MainHBox/ButtonContainer/ButtonVBox/ViewButton")
	_setup_action_button_templates()
	_setup_log_scroll_behavior()
	_setup_settings_scroll_behavior()
	_setup_status_header_style()
	_setup_breakthrough_panel_style()
	_apply_safe_area_layout()
	_setup_cultivation_visual_auto_center()

	# 监听屏幕大小变化
	if get_viewport() and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


func _setup_notification_badges() -> void:
	if not notification_badge_state:
		notification_badge_state = NOTIFICATION_BADGE_STATE_SCRIPT.new()
		notification_badge_state.name = "NotificationBadgeState"
		add_child(notification_badge_state)
	if not notification_badge_state.state_changed.is_connected(_on_notification_badge_state_changed):
		notification_badge_state.state_changed.connect(_on_notification_badge_state_changed)

	_notification_badges.clear()
	_register_notification_badge("region_tab_badge", tab_region, Vector2(12.0, 12.0), Vector2(-18.0, 6.0))
	_register_notification_badge("settings_tab_badge", tab_settings, Vector2(12.0, 12.0), Vector2(-18.0, 6.0))
	_register_notification_badge("task_claimable", xianwu_office_button, Vector2(30.0, 30.0), Vector2(-20.0, 4.0), true, "task_claimable_count")
	_register_notification_badge("mail_unread", mailbox_button, Vector2(30.0, 30.0), Vector2(-20.0, 4.0), true, "mail_unread_count")
	_apply_notification_badge_state(notification_badge_state.get_state())


func _register_notification_badge(
	key: String,
	target: Control,
	size: Vector2,
	top_right_offset: Vector2,
	show_count: bool = false,
	count_key: String = ""
) -> void:
	if not target:
		return
	var badge := Control.new()
	badge.name = "NotificationBadge_" + key
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = top_right_offset.x - size.x
	badge.offset_right = top_right_offset.x
	badge.offset_top = top_right_offset.y
	badge.offset_bottom = top_right_offset.y + size.y

	var badge_panel := Panel.new()
	badge_panel.name = "BadgePanel"
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.anchor_left = 0.0
	badge_panel.anchor_right = 1.0
	badge_panel.anchor_top = 0.0
	badge_panel.anchor_bottom = 1.0
	badge_panel.offset_left = 0.0
	badge_panel.offset_right = 0.0
	badge_panel.offset_top = 0.0
	badge_panel.offset_bottom = 0.0

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = BADGE_COLOR
	badge_style.border_color = BADGE_BORDER_COLOR
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(int(minf(size.x, size.y) * 0.5))
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge.add_child(badge_panel)

	var badge_info := {
		"root": badge,
		"show_count": show_count,
		"count_key": count_key,
	}

	if show_count:
		var count_label := Label.new()
		count_label.name = "CountLabel"
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.anchor_left = 0.0
		count_label.anchor_right = 1.0
		count_label.anchor_top = 0.0
		count_label.anchor_bottom = 1.0
		count_label.offset_left = 0.0
		count_label.offset_right = 0.0
		count_label.offset_top = -1.0
		count_label.offset_bottom = 0.0
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 16)
		count_label.add_theme_color_override("font_color", BADGE_TEXT_COLOR)
		count_label.text = ""
		badge.add_child(count_label)
		badge_info["label"] = count_label

	target.add_child(badge)
	_notification_badges[key] = badge_info


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

func _setup_action_button_templates():
	if cultivate_button:
		ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(
			cultivate_button,
			cultivate_button.custom_minimum_size,
			20
		)
	if breakthrough_button:
		ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(
			breakthrough_button,
			breakthrough_button.custom_minimum_size,
			20
		)

func _setup_status_header_style():
	if not status_header_row:
		return
	DISPLAY_PANEL_TEMPLATE.apply_to_row(status_header_row, DISPLAY_PANEL_TEMPLATE.build_standard_header_config({
		"title_text": "属性面板"
	}))
	# 展示面板模板约束：内容左侧与标题首字左侧对齐，标题下留白固定
	DISPLAY_PANEL_TEMPLATE.apply_content_layout(
		[status_health_left_pad, status_spirit_left_pad],
		status_separator_margin,
		status_header_bottom_spacer
	)

func _setup_breakthrough_panel_style():
	if not breakthrough_header_row:
		return
	DISPLAY_PANEL_TEMPLATE.apply_to_row(breakthrough_header_row, DISPLAY_PANEL_TEMPLATE.build_standard_header_config({
		"title_text": "突破详情"
	}))
	# 展示面板模板约束：内容左侧与标题首字左侧对齐，标题下留白固定
	DISPLAY_PANEL_TEMPLATE.apply_content_layout(
		[],
		breakthrough_materials_margin,
		breakthrough_header_bottom_spacer
	)

func _setup_log_scroll_behavior():
	if not log_text:
		return
	var v_scrollbar: VScrollBar = log_text.get_v_scroll_bar()
	if not v_scrollbar:
		return
	# 保留滚动能力，但隐藏纵向滚动条视觉
	v_scrollbar.modulate = Color(1, 1, 1, 0)
	v_scrollbar.self_modulate = Color(1, 1, 1, 0)
	v_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_scrollbar.custom_minimum_size.x = 0.0

func _setup_settings_scroll_behavior():
	if not settings_scroll:
		return
	var v_scrollbar: VScrollBar = settings_scroll.get_v_scroll_bar()
	if v_scrollbar:
		# 设置页保留滚动能力，但不显示纵向滚轴
		v_scrollbar.modulate = Color(1, 1, 1, 0)
		v_scrollbar.self_modulate = Color(1, 1, 1, 0)
		v_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_scrollbar.custom_minimum_size.x = 0.0
	if rank_scroll:
		rank_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rank_scroll.vertical_scroll_mode = 3
		var rank_v_scrollbar: VScrollBar = rank_scroll.get_v_scroll_bar()
		if rank_v_scrollbar:
			rank_v_scrollbar.modulate = Color(1, 1, 1, 0)
			rank_v_scrollbar.self_modulate = Color(1, 1, 1, 0)
			rank_v_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rank_v_scrollbar.custom_minimum_size.x = 0.0
		var rank_h_scrollbar: HScrollBar = rank_scroll.get_h_scroll_bar()
		if rank_h_scrollbar:
			rank_h_scrollbar.modulate = Color(1, 1, 1, 0)
			rank_h_scrollbar.self_modulate = Color(1, 1, 1, 0)
			rank_h_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rank_h_scrollbar.custom_minimum_size.y = 0.0

func _setup_bottom_tab_layout():
	if not tab_bar:
		return
	var tab_bar_height: float = max(62.0, tab_bar.custom_minimum_size.y)
	BOTTOM_TAB_BAR_STYLE_TEMPLATE.apply_to_bar(tab_bar, {
		"bar_height": tab_bar_height,
		"font_size": 23,
		"text_raise": 20.0,
		"line_position": "top",
		"line_width": 2,
		"selected_line_width": 3,
		"normal_bg": Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0),
		"hover_bg": Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0),
		"pressed_bg": Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0),
		"selected_bg": Color(0.95, 0.92, 0.85, 1.0),
		"line_color": Color(0.52, 0.49, 0.45, 1.0),
		"selected_line_color": Color(222.0 / 255.0, 180.0 / 255.0, 53.0 / 255.0, 1.0),
		"font_color": Color(0.35, 0.32, 0.28, 1.0),
		"selected_font_color": Color(222.0 / 255.0, 180.0 / 255.0, 53.0 / 255.0, 1.0)
	})
	if bottom_spacer:
		bottom_spacer.custom_minimum_size.y = 8.0

func _setup_neishi_sub_tab_layout():
	if not neishi_tab_bar:
		return
	var neishi_tab_height: float = max(58.0, neishi_tab_bar.custom_minimum_size.y)
	TOP_TAB_BAR_STYLE_TEMPLATE.apply_to_bar(neishi_tab_bar, {
		"bar_height": 38.0,
		"font_size": 20,
		"separation": 0,
		"button_corner_radius": 12,
		"shell_inset_x": 18.0,
		"shell_inset_y": 9.0,
		"shell_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"shell_border_color": Color(0.86, 0.78, 0.63, 0.45),
		"shell_corner_radius": 20,
		"normal_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"hover_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"pressed_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"selected_bg": Color(188.0 / 255.0, 144.0 / 255.0, 48.0 / 255.0, 1.0),
		"font_color": Color(0.33, 0.28, 0.22, 1.0),
		"selected_font_color": Color(0.98, 0.96, 0.92, 1.0)
	})

func _on_viewport_size_changed():
	_apply_safe_area_layout()
	call_deferred("_reposition_cultivation_visual_between_panels")

func update_font_sizes():
	# 主界面常驻字体回归固定设计稿字号，不再按真实屏幕宽度二次缩放。
	return

func _apply_safe_area_layout():
	if not content_frame:
		return
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var safe_rect: Rect2 = SAFE_AREA_HELPER.get_safe_inner_rect(self)
	content_frame.scale = Vector2.ONE
	content_frame.position = safe_rect.position
	content_frame.size = safe_rect.size
	_update_safe_fill_frames(viewport_rect.size, safe_rect)
	call_deferred("_reposition_cultivation_visual_between_panels")

func _setup_cultivation_visual_auto_center():
	if cultivation_container and not cultivation_container.resized.is_connected(_on_cultivation_layout_changed):
		cultivation_container.resized.connect(_on_cultivation_layout_changed)
	if status_area_panel and not status_area_panel.resized.is_connected(_on_cultivation_layout_changed):
		status_area_panel.resized.connect(_on_cultivation_layout_changed)
	if breakthrough_panel_container and not breakthrough_panel_container.resized.is_connected(_on_cultivation_layout_changed):
		breakthrough_panel_container.resized.connect(_on_cultivation_layout_changed)
	call_deferred("_reposition_cultivation_visual_between_panels")

func _on_cultivation_layout_changed():
	call_deferred("_reposition_cultivation_visual_between_panels")

func _reposition_cultivation_visual_between_panels():
	if not cultivation_visual or not cultivation_container or not status_area_panel or not breakthrough_panel_container:
		return
	if not neishi_panel or not neishi_panel.visible:
		return

	var top_edge: float = status_area_panel.position.y + status_area_panel.size.y
	var bottom_edge: float = breakthrough_panel_container.position.y
	if bottom_edge <= top_edge:
		return

	var center_y: float = (top_edge + bottom_edge) * 0.5
	var new_x: float = (cultivation_container.size.x - cultivation_visual.size.x) * 0.5
	var new_y: float = center_y - cultivation_visual.size.y * 0.5
	cultivation_visual.position = Vector2(new_x, new_y)

func _update_safe_fill_frames(viewport_size: Vector2, safe_rect: Rect2):
	if safe_top:
		safe_top.position = Vector2.ZERO
		safe_top.size = Vector2(viewport_size.x, max(0.0, safe_rect.position.y))
	if safe_top_fill:
		safe_top_fill.color = Color(0, 0, 0, 1)
	if safe_bottom:
		safe_bottom.position = Vector2(0.0, safe_rect.end.y)
		safe_bottom.size = Vector2(viewport_size.x, max(0.0, viewport_size.y - safe_rect.end.y))
	if safe_bottom_fill:
		safe_bottom_fill.color = Color(0, 0, 0, 1)

func _process(delta: float):
	# 更新UI
	if player:
		update_ui()

func setup_log_manager():
	log_manager = LogManager.new()
	log_manager.name = "LogManager"
	add_child(log_manager)
	log_manager.set_max_log_count(LOG_MAX_COUNT_DEFAULT)
	log_manager.set_rich_text_label(log_text)
	_setup_log_filter_tabs()

func _setup_log_filter_tabs():
	if not log_filter_tab_bar:
		return
	TOP_TAB_BAR_STYLE_TEMPLATE.apply_to_bar(log_filter_tab_bar, {
		"bar_height": 36.0,
		"font_size": 18,
		"button_corner_radius": 10,
		"shell_inset_x": 14.0,
		"shell_inset_y": 10.0,
		"shell_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"shell_border_color": Color(0.86, 0.78, 0.63, 0.35),
		"shell_corner_radius": 18,
		"normal_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"hover_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"pressed_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"selected_bg": Color(188.0 / 255.0, 144.0 / 255.0, 48.0 / 255.0, 1.0),
		"font_color": Color(0.33, 0.28, 0.22, 1.0),
		"selected_font_color": Color(0.98, 0.96, 0.92, 1.0)
	})
	if log_filter_all_button and not log_filter_all_button.pressed.is_connected(_on_log_filter_all_pressed):
		log_filter_all_button.pressed.connect(_on_log_filter_all_pressed)
	if log_filter_system_button and not log_filter_system_button.pressed.is_connected(_on_log_filter_system_pressed):
		log_filter_system_button.pressed.connect(_on_log_filter_system_pressed)
	if log_filter_battle_button and not log_filter_battle_button.pressed.is_connected(_on_log_filter_battle_pressed):
		log_filter_battle_button.pressed.connect(_on_log_filter_battle_pressed)
	if log_filter_production_button and not log_filter_production_button.pressed.is_connected(_on_log_filter_production_pressed):
		log_filter_production_button.pressed.connect(_on_log_filter_production_pressed)
	_apply_log_filter("all")

func _set_log_filter_tabs_disabled(all_sel: bool, system_sel: bool, battle_sel: bool, production_sel: bool):
	if log_filter_all_button:
		log_filter_all_button.disabled = all_sel
	if log_filter_system_button:
		log_filter_system_button.disabled = system_sel
	if log_filter_battle_button:
		log_filter_battle_button.disabled = battle_sel
	if log_filter_production_button:
		log_filter_production_button.disabled = production_sel

func _apply_log_filter(filter_key: String):
	if not log_manager:
		return
	var normalized = String(filter_key).to_lower()
	log_manager.set_filter(normalized)
	match normalized:
		"system":
			_set_log_filter_tabs_disabled(false, true, false, false)
		"battle":
			_set_log_filter_tabs_disabled(false, false, true, false)
		"production":
			_set_log_filter_tabs_disabled(false, false, false, true)
		_:
			_set_log_filter_tabs_disabled(true, false, false, false)

func _on_log_filter_all_pressed():
	_apply_log_filter("all")

func _on_log_filter_system_pressed():
	_apply_log_filter("system")

func _on_log_filter_battle_pressed():
	_apply_log_filter("battle")

func _on_log_filter_production_pressed():
	_apply_log_filter("production")

func setup_button_connections():
	# 修炼和突破按钮（CultivationModule）
	if cultivate_button and cultivation_module:
		cultivate_button.pressed.connect(cultivation_module.on_cultivate_button_pressed)
	if breakthrough_button and cultivation_module:
		breakthrough_button.pressed.connect(cultivation_module.on_breakthrough_button_pressed)
	
	if tab_neishi:
		tab_neishi.pressed.connect(_on_tab_neishi_pressed)
	if tab_chuna:
		tab_chuna.pressed.connect(_on_tab_chuna_pressed)
	if tab_region:
		tab_region.pressed.connect(_on_tab_region_pressed)
	if tab_lianli:
		tab_lianli.pressed.connect(_on_tab_lianli_pressed)
	if tab_settings:
		tab_settings.pressed.connect(_on_tab_settings_pressed)
	if top_player_info:
		top_player_info.gui_input.connect(_on_top_player_info_gui_input)
	
	# 内室子Tab连接（NeishiModule）
	if cultivation_tab and neishi_module:
		cultivation_tab.pressed.connect(neishi_module.on_cultivation_tab_pressed)
	if spell_tab and neishi_module:
		spell_tab.pressed.connect(neishi_module.on_spell_tab_pressed)
	
	# 初始化无尽塔按钮（不需要lianli_area_data）
	_init_endless_tower_button()
	
	# 注意：历练区域按钮在load_game_data()之后初始化
	
	# 历练按钮连接（LianliModule）
	if continuous_checkbox and lianli_module:
		continuous_checkbox.toggled.connect(lianli_module.on_continuous_toggled)
	if continue_button and lianli_module:
		continue_button.pressed.connect(lianli_module.on_continue_pressed)
	if lianli_speed_button and lianli_module:
		lianli_speed_button.pressed.connect(lianli_module.on_lianli_speed_pressed)
	if exit_lianli_button and lianli_module:
		exit_lianli_button.pressed.connect(lianli_module.on_exit_lianli_pressed)

func setup_alchemy_module():
	# 创建炼丹模块
	alchemy_module = ALCHEMY_MODULE_SCRIPT.new()
	alchemy_module.name = "AlchemyModule"
	add_child(alchemy_module)
	
	# 设置UI节点引用
	alchemy_module.alchemy_room_panel = alchemy_room_panel
	alchemy_module.recipe_list_container = recipe_list_container
	alchemy_module.recipe_name_label = recipe_name_label
	alchemy_module.success_rate_label = success_rate_label
	alchemy_module.craft_time_label = craft_time_label
	alchemy_module.materials_container = materials_container
	alchemy_module.craft_button = craft_button
	alchemy_module.stop_button = stop_button
	alchemy_module.craft_progress_bar = craft_progress_bar
	alchemy_module.craft_count_label = craft_count_label
	alchemy_module.alchemy_info_label = alchemy_info_label
	alchemy_module.furnace_info_label = furnace_info_label
	alchemy_module.count_1_button = count_1_button
	alchemy_module.count_10_button = count_10_button
	alchemy_module.count_100_button = count_100_button
	alchemy_module.count_max_button = count_max_button
	alchemy_module.count_plus_10_button = count_plus_10_button
	alchemy_module.count_final_max_button = count_final_max_button
	alchemy_module.alchemy_back_button = alchemy_back_button
	alchemy_module.spell_system = spell_system
	
	# 初始化炼丹模块（在设置UI节点引用之后）
	alchemy_module.initialize(self, player, alchemy_system, recipe_data, item_data_ref, api)
	
	# 设置样式（必须在所有引用设置完成后）
	alchemy_module.setup_styles()

	# 连接数量选择按钮
	if count_1_button:
		count_1_button.pressed.connect(_on_craft_count_min)
	if count_10_button:
		count_10_button.pressed.connect(func(): _on_craft_count_delta(-10))
	if count_100_button:
		count_100_button.pressed.connect(func(): _on_craft_count_delta(-1))
	if count_max_button:
		count_max_button.pressed.connect(func(): _on_craft_count_delta(1))
	if count_plus_10_button:
		count_plus_10_button.pressed.connect(func(): _on_craft_count_delta(10))
	if count_final_max_button:
		count_final_max_button.pressed.connect(_on_craft_count_max)
	
	# 连接信号
	alchemy_module.log_message.connect(_on_alchemy_log)
	alchemy_module.back_to_dongfu_requested.connect(_on_back_to_region_requested)
	
	# 连接返回按钮
	if alchemy_back_button:
		alchemy_back_button.pressed.connect(_on_back_to_region_requested)

func _on_back_to_region_requested():
	"""处理返回地区请求"""
	show_region_tab()

func setup_settings_module():
	# 创建设置模块
	settings_module = SETTINGS_MODULE_SCRIPT.new()
	settings_module.name = "SettingsModule"
	add_child(settings_module)
	
	# 设置UI节点引用
	settings_module.settings_panel = settings_panel
	settings_module.save_button = save_button
	settings_module.logout_button = logout_button
	settings_module.rank_button = rank_button
	settings_module.mall_button = mall_button
	settings_module.guide_button = guide_button
	settings_module.mailbox_button = mailbox_button
	settings_module.redeem_confirm_button = redeem_confirm_button
	settings_module.redeem_code_input = redeem_code_input
	settings_module.fps_30_button = fps_30_button
	settings_module.fps_60_button = fps_60_button
	settings_module.fps_120_button = fps_120_button
	settings_module.fps_144_button = fps_144_button
	settings_module.fps_unlimited_button = fps_unlimited_button
	settings_module.fps_limit_option_button = fps_limit_option_button
	settings_module.music_mute_button = music_mute_button
	settings_module.music_volume_slider = music_volume_slider
	settings_module.music_volume_value_label = music_volume_value_label
	settings_module.rank_panel = rank_panel
	settings_module.rank_list = rank_list
	settings_module.back_button = back_button
	
	# 初始化模块
	settings_module.initialize(self, player, api)
	
	# 连接信号
	settings_module.log_message.connect(_on_module_log)
	if not settings_module.mailbox_requested.is_connected(_on_mailbox_requested):
		settings_module.mailbox_requested.connect(_on_mailbox_requested)

func setup_mail_module():
	mail_module = MAIL_MODULE_SCRIPT.new()
	mail_module.name = "MailModule"
	add_child(mail_module)
	mail_module.initialize(self, api, item_data_ref)
	mail_module.log_message.connect(_on_module_log)
	mail_module.back_requested.connect(_on_mail_back_requested)
	if not mail_module.mail_state_changed.is_connected(_on_mail_state_changed):
		mail_module.mail_state_changed.connect(_on_mail_state_changed)
	_setup_system_refresh_timer()

func _on_mailbox_requested():
	show_mail_panel()

func _on_mail_back_requested():
	show_settings_tab()


func _on_task_state_changed(claimable_count: int) -> void:
	if notification_badge_state:
		notification_badge_state.update_task_claimable_count(claimable_count)


func _on_mail_state_changed(unread_count: int, _total_count: int) -> void:
	if notification_badge_state:
		notification_badge_state.update_mail_unread_count(unread_count)

func setup_profile_edit_popup():
	if profile_edit_popup:
		return
	profile_edit_popup = PROFILE_EDIT_POPUP_SCRIPT.new()
	add_child(profile_edit_popup)
	profile_edit_popup.setup(self)
	profile_edit_popup.nickname_submit_requested.connect(_on_profile_nickname_submit_requested)
	profile_edit_popup.avatar_submit_requested.connect(_on_profile_avatar_submit_requested)
	profile_edit_popup.popup_closed.connect(_on_profile_popup_closed)

	if top_player_info:
		top_player_info.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_children_mouse_filter_ignore(top_player_info)

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
	# 创建地区模块
	region_module = DONGFU_MODULE_SCRIPT.new()
	region_module.name = "RegionModule"
	add_child(region_module)
	
	# 设置UI节点引用
	region_module.region_panel = region_panel
	region_module.alchemy_workshop_button = alchemy_workshop_button
	region_module.herb_mountain_button = herb_mountain_button
	region_module.xianwu_office_button = xianwu_office_button
	
	# 初始化模块
	region_module.initialize(self, player, alchemy_module)
	region_module.log_message.connect(_on_module_log)
	region_module.herb_gather_requested.connect(_on_herb_gather_requested)
	region_module.task_panel_requested.connect(_on_task_panel_requested)

func setup_herb_gather_module():
	herb_gather_module = HERB_GATHER_MODULE_SCRIPT.new()
	herb_gather_module.name = "HerbGatherModule"
	add_child(herb_gather_module)

	herb_gather_module.herb_gather_panel = herb_gather_panel
	herb_gather_module.point_list = herb_gather_point_list
	herb_gather_module.back_button = herb_gather_back_button
	herb_gather_module.spell_system = spell_system
	herb_gather_module.initialize(self, player, inventory, item_data_ref, api)
	herb_gather_module.log_message.connect(_on_production_log)
	herb_gather_module.back_to_region_requested.connect(_on_back_to_region_requested)

func setup_task_module():
	task_module = TASK_MODULE_SCRIPT.new()
	task_module.name = "TaskModule"
	add_child(task_module)

	task_module.task_panel = task_panel
	task_module.back_button = task_back_button
	task_module.task_tab_bar = task_tab_bar
	task_module.daily_tab_button = task_daily_tab_button
	task_module.newbie_tab_button = task_newbie_tab_button
	task_module.task_scroll = task_scroll
	task_module.task_list = task_list
	task_module.initialize(self, api)
	task_module.log_message.connect(_on_module_log)
	task_module.back_to_region_requested.connect(_on_back_to_region_requested)
	if not task_module.task_state_changed.is_connected(_on_task_state_changed):
		task_module.task_state_changed.connect(_on_task_state_changed)

func _on_herb_gather_requested():
	show_herb_gather_panel()

func _on_task_panel_requested():
	show_task_panel()

func setup_chuna_module():
	# 创建储纳模块
	chuna_module = CHUNA_MODULE_SCRIPT.new()
	chuna_module.name = "ChunaModule"
	add_child(chuna_module)
	
	# 设置UI节点引用
	chuna_module.chuna_panel = chuna_panel
	chuna_module.inventory_grid = inventory_grid
	chuna_module.capacity_label = capacity_label
	chuna_module.item_detail_panel = item_detail_panel
	chuna_module.view_button = view_button
	chuna_module.use_button = use_button
	chuna_module.batch_use_button = batch_use_button
	chuna_module.discard_button = discard_button
	chuna_module.expand_button = expand_button
	chuna_module.sort_button = sort_button
	
	# 初始化模块
	chuna_module.initialize(self, player, inventory, item_data_ref, spell_system, spell_data_ref, alchemy_system, api, recipe_data)
	
	# 连接信号
	chuna_module.log_message.connect(_on_module_log)

func setup_spell_module():
	spell_module = SPELL_MODULE_SCRIPT.new()
	spell_module.name = "SpellModule"
	add_child(spell_module)
	
	# 设置UI节点引用
	spell_module.spell_panel = spell_panel
	spell_module.spell_tab = spell_tab
	
	# 初始化模块
	spell_module.initialize(self, player, spell_system, spell_data_ref, api)
	
	# 连接信号
	spell_module.log_message.connect(_on_module_log)

func setup_neishi_module():
	# 创建修炼突破模块
	cultivation_module = CULTIVATION_MODULE_SCRIPT.new()
	cultivation_module.name = "CultivationModule"
	add_child(cultivation_module)
	
	# 设置UI节点引用
	cultivation_module.cultivation_panel = cultivation_panel
	cultivation_module.cultivate_button = cultivate_button
	cultivation_module.breakthrough_button = breakthrough_button
	cultivation_module.breakthrough_material_labels = [
		breakthrough_material_label_1,
		breakthrough_material_label_2,
		breakthrough_material_label_3
	]
	
	# 设置气血/灵气条
	cultivation_module.health_bar = health_bar
	cultivation_module.health_value = health_value
	cultivation_module.spirit_bar = spirit_bar
	cultivation_module.spirit_value = spirit_value
	
	# 设置属性标签
	cultivation_module.attack_value_label = attack_value_label
	cultivation_module.defense_value_label = defense_value_label
	cultivation_module.speed_value_label = speed_value_label
	cultivation_module.penetration_value_label = penetration_value_label
	cultivation_module.crit_value_label = crit_value_label
	cultivation_module.crit_damage_value_label = crit_damage_value_label
	cultivation_module.spirit_gain_value_label = spirit_gain_value_label
	cultivation_module.health_regen_value_label = health_regen_value_label
	
	# 设置修炼状态标签和小人素材
	cultivation_module.status_label = status_label
	cultivation_module.cultivation_figure = cultivation_figure
	cultivation_module.cultivation_figure_particles = cultivation_figure_particles
	
	# 初始化模块
	var game_manager = get_node("/root/GameManager")
	cultivation_system = game_manager.get_cultivation_system() if game_manager else null
	lianli_system = game_manager.get_lianli_system() if game_manager else null
	var realm_system = game_manager.get_realm_system() if game_manager else null
	cultivation_module.initialize(self, player, cultivation_system, lianli_system, item_data_ref, alchemy_module, api, spell_system, realm_system)
	
	# 连接信号
	cultivation_module.log_message.connect(_on_module_log)
	
	# 创建内视模块
	neishi_module = NEISHI_MODULE_SCRIPT.new()
	neishi_module.name = "NeishiModule"
	add_child(neishi_module)
	
	# 设置UI节点引用
	neishi_module.neishi_panel = neishi_panel
	neishi_module.cultivation_panel = cultivation_panel
	neishi_module.spell_panel = spell_panel
	neishi_module.cultivation_tab = cultivation_tab
	neishi_module.spell_tab = spell_tab
	
	# 初始化模块
	neishi_module.initialize(self, player)
	
	# 设置子模块
	neishi_module.set_cultivation_module(cultivation_module)
	neishi_module.set_spell_module(spell_module)
	
	# 连接信号
	neishi_module.log_message.connect(_on_module_log)

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
	# 创建历练模块
	lianli_module = LIANLI_MODULE_SCRIPT.new()
	lianli_module.name = "LianliModule"
	add_child(lianli_module)
	
	# 设置UI节点引用
	lianli_module.lianli_panel = lianli_panel
	lianli_module.lianli_scene_panel = lianli_scene_panel
	lianli_module.lianli_select_panel = lianli_select_panel
	lianli_module.lianli_status_label = lianli_status_label
	lianli_module.area_name_label = area_name_label
	lianli_module.reward_info_label = reward_info_label
	
	# 战斗UI
	lianli_module.enemy_name_label = enemy_name_label
	lianli_module.enemy_health_bar = enemy_health_bar
	lianli_module.enemy_health_value = enemy_health_value
	lianli_module.player_health_bar_lianli = player_health_bar_lianli
	lianli_module.player_health_value_lianli = player_health_value_lianli
	
	lianli_module.continuous_checkbox = continuous_checkbox
	lianli_module.continue_button = continue_button
	lianli_module.lianli_speed_button = lianli_speed_button
	lianli_module.exit_lianli_button = exit_lianli_button
	
	lianli_module.initialize(self, player, lianli_system, lianli_area_data, item_data_ref, inventory, chuna_module, log_manager, alchemy_module, api, spell_data_ref, spell_system)
	
	lianli_module.log_message.connect(_on_module_log)

func load_game_data():
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		item_data_ref = game_manager.get_item_data()
		spell_data_ref = game_manager.get_spell_data()
		lianli_system = game_manager.get_lianli_system()
		lianli_area_data = game_manager.get_lianli_area_data()
		enemy_data = game_manager.get_enemy_data()
		set_spell_system(game_manager.get_spell_system())
		
		set_alchemy_system(game_manager.get_alchemy_system())
		set_recipe_data(game_manager.get_recipe_data())
		set_item_data(game_manager.get_item_data())
		
		if game_manager.get_player():
			set_player(game_manager.get_player())
		if game_manager.get_inventory():
			set_inventory(game_manager.get_inventory())
		
		lianli_system = game_manager.get_lianli_system()
		lianli_area_data = game_manager.get_lianli_area_data()
		
		if lianli_module:
			lianli_module.lianli_system = lianli_system
			lianli_module.lianli_area_data = lianli_area_data
			lianli_module.item_data_ref = item_data_ref
			lianli_module.spell_data = spell_data_ref
			lianli_module.spell_system = spell_system
		
		if spell_module:
			spell_module.spell_system = spell_system
			spell_module.spell_data = spell_data_ref
			spell_module.player = player
			spell_module.api = api
			spell_module.update_spell_ui()
		
		_init_lianli_area_buttons()
		
		if lianli_module and endless_tower_button:
			lianli_module.update_endless_tower_button_text(endless_tower_button)
		
		game_manager.account_logged_in.connect(_on_account_logged_in)
		
		update_account_ui()

func set_player(player_node: Node):
	player = player_node
	# 初始化炼丹模块的玩家引用
	if alchemy_module:
		alchemy_module.player = player
	# 初始化储纳模块的玩家引用
	if chuna_module:
		chuna_module.player = player
	# 初始化修炼突破模块的玩家引用
	if cultivation_module:
		cultivation_module.player = player
	# 初始化术法模块的玩家引用
	if spell_module:
		spell_module.player = player
	# 初始化历练模块的玩家引用
	if lianli_module:
		lianli_module.player = player
	# 初始化设置模块的玩家引用
	if settings_module:
		settings_module.player = player
	if herb_gather_module:
		herb_gather_module.player = player

func set_spell_system(spell_system_node: Node):
	spell_system = spell_system_node
	# 连接术法使用信号，实现使用次数实时更新
	if spell_system:
		spell_system.spell_used.connect(_on_spell_used)
	# 初始化术法模块的术法系统引用
	if spell_module:
		spell_module.spell_system = spell_system
		spell_module.spell_data = spell_data_ref
	if alchemy_module:
		alchemy_module.spell_system = spell_system
	if herb_gather_module:
		herb_gather_module.spell_system = spell_system
	# 初始化储纳模块的术法系统引用
	if chuna_module:
		chuna_module.spell_system = spell_system
		chuna_module.spell_data = spell_data_ref

func set_alchemy_system(alchemy_system_node: Node):
	alchemy_system = alchemy_system_node
	# 初始化炼丹模块的炼丹系统引用
	if alchemy_module:
		alchemy_module.alchemy_system = alchemy_system
	# 初始化储纳模块的炼丹系统引用
	if chuna_module:
		chuna_module.alchemy_system = alchemy_system

func set_recipe_data(recipe_data_node: Node):
	recipe_data = recipe_data_node
	# 初始化炼丹模块的丹方数据引用
	if alchemy_module:
		alchemy_module.recipe_data = recipe_data

func set_item_data(item_data_node: Node):
	item_data_ref = item_data_node
	if alchemy_module:
		alchemy_module.item_data = item_data_node
	if chuna_module:
		chuna_module.item_data = item_data_node
	if mail_module:
		mail_module.item_data_ref = item_data_node
	if cultivation_module:
		cultivation_module.item_data = item_data_node
	if herb_gather_module:
		herb_gather_module.item_data = item_data_node

func _on_spell_used(spell_id: String):
	# 通知术法模块更新使用次数
	if spell_module:
		spell_module.on_spell_used(spell_id)

func set_inventory(inventory_node: Node):
	inventory = inventory_node
	if chuna_module:
		chuna_module.inventory = inventory
		chuna_module.update_inventory_ui()
	if cultivation_module:
		cultivation_module.inventory = inventory
	if lianli_module:
		lianli_module.inventory = inventory
	if alchemy_module:
		alchemy_module.inventory = inventory
	if herb_gather_module:
		herb_gather_module.inventory = inventory

func refresh_all_player_data():
	"""
	统一刷新所有玩家数据。
	在进行全量数据同步前，会尝试先上报各模块的本地缓存数据。
	"""
	_pending_refresh_all_player_data_count += 1
	# 1. 先上报修炼进度（乐观更新的数据）
	if cultivation_module:
		await cultivation_module._flush_pending_report()
	
	# 2. 从服务器加载全量数据
	if _test_shutdown_requested or not api:
		_pending_refresh_all_player_data_count = maxi(0, _pending_refresh_all_player_data_count - 1)
		return
		
	var result = await api.load_game()
	if not result.get("success", false):
		_on_module_log("玩家数据同步失败，请检查网络连接")
		_pending_refresh_all_player_data_count = maxi(0, _pending_refresh_all_player_data_count - 1)
		return

	var data = result.get("data", {})
	
	# 3. 分发并应用数据到各个核心系统
	if data.has("spell_system") and spell_system:
		spell_system.apply_save_data(data["spell_system"])
		if spell_module:
			spell_module.spell_system = spell_system # 确保引用最新
			spell_module.spell_data = spell_data_ref # 确保引用最新
			spell_module.update_spell_ui()

	if data.has("player") and player:
		player.apply_save_data(data["player"])
		if cultivation_module and not player.get_is_cultivating() and cultivation_module.has_method("reset_local_runtime_state"):
			cultivation_module.reset_local_runtime_state(true)
		
	if data.has("inventory") and inventory:
		inventory.apply_save_data(data["inventory"])
		# 强制触发储纳模块 UI 刷新
		if chuna_module:
			chuna_module.inventory = inventory # 确保引用最新
			chuna_module.item_data = item_data_ref # 确保引用最新
			chuna_module.setup_inventory_grid()
			chuna_module.update_inventory_ui()
			
	if data.has("alchemy_system") and alchemy_system:
		alchemy_system.apply_save_data(data["alchemy_system"])
		if alchemy_module:
			alchemy_module.alchemy_system = alchemy_system # 确保引用最新
			alchemy_module.item_data = item_data_ref # 确保引用最新
			alchemy_module.refresh_ui()
			
	# 4. 更新主界面 UI（属性条、境界等）
	update_ui()
	
	# 历练模块可能也需要更新
	if lianli_module:
		lianli_module.inventory = inventory # 确保引用最新
		lianli_module.item_data_ref = item_data_ref # 确保引用最新
		if data.has("lianli_system"):
			lianli_module.on_player_data_refreshed(data["lianli_system"])
		# 刷新历练区域按钮（可能涉及次数刷新）
		update_lianli_area_buttons_display()
		# 从服务器刷新副本信息缓存
		if allow_background_server_refresh:
			call_deferred("_refresh_lianli_info_from_server")

	if inventory and not inventory.item_added.is_connected(_on_item_added):
		inventory.item_added.connect(_on_item_added)
	_pending_refresh_all_player_data_count = maxi(0, _pending_refresh_all_player_data_count - 1)

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
	neishi_panel.visible = true
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = false
	if mail_module and mail_module.panel:
		mail_module.panel.visible = false
	lianli_panel.visible = false
	settings_panel.visible = false
	# 隐藏炼丹房
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	# 隐藏储纳Tab
	if chuna_module:
		chuna_module.hide_tab()
	tab_neishi.disabled = true
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = false
	tab_lianli.disabled = false
	tab_settings.disabled = false

	# 初始化内室子Tab（NeishiModule）
	if neishi_module:
		neishi_module.show_tab()
	call_deferred("_reposition_cultivation_visual_between_panels")

func show_chuna_tab():
	neishi_panel.visible = false
	chuna_panel.visible = true
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = false
	if mail_module and mail_module.panel:
		mail_module.panel.visible = false
	lianli_panel.visible = false
	settings_panel.visible = false
	# 隐藏炼丹房
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	# 显示储纳Tab
	if chuna_module:
		chuna_module.show_tab()
	tab_neishi.disabled = false
	tab_chuna.disabled = true
	if tab_region:
		tab_region.disabled = false
	tab_lianli.disabled = false
	tab_settings.disabled = false
	# 确保面板可见
	if item_detail_panel:
		item_detail_panel.visible = true

func show_region_tab():
	neishi_panel.visible = false
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = true
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = false
	if mail_module and mail_module.panel:
		mail_module.panel.visible = false
	lianli_panel.visible = false
	settings_panel.visible = false
	# 隐藏炼丹房
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	# 显示地区Tab
	if region_module:
		region_module.show_tab()
	tab_neishi.disabled = false
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = true
	tab_lianli.disabled = false
	tab_settings.disabled = false

func show_lianli_tab():
	neishi_panel.visible = false
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = false
	if mail_module and mail_module.panel:
		mail_module.panel.visible = false
	lianli_panel.visible = true
	settings_panel.visible = false
	# 隐藏炼丹房
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	tab_neishi.disabled = false
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = false
	tab_lianli.disabled = true
	tab_settings.disabled = false

	# 先用本地快照更新，再异步从服务端刷新每日次数/塔层
	update_lianli_area_buttons_display()
	if endless_tower_button and lianli_module:
		lianli_module.update_endless_tower_button_text(endless_tower_button)
	if allow_background_server_refresh:
		call_deferred("_refresh_lianli_info_from_server")

	# 检查是否处于历练中
	if lianli_module:
		lianli_module.on_tab_entered()
		if lianli_system and lianli_system.is_in_lianli:
			# 还在历练中，显示战斗场景
			lianli_module.show_lianli_scene_panel()
		else:
			# 历练已结束或未开始，显示选择面板
			lianli_module.show_lianli_select_panel()

func show_settings_tab():
	neishi_panel.visible = false
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = false
	if mail_module and mail_module.panel:
		mail_module.panel.visible = false
	lianli_panel.visible = false
	settings_panel.visible = true
	# 隐藏炼丹房
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	# 显示设置Tab
	if settings_module:
		settings_module.show_tab()
	tab_neishi.disabled = false
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = false
	tab_lianli.disabled = false
	tab_settings.disabled = true

func show_mail_panel():
	neishi_panel.visible = false
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = false
	lianli_panel.visible = false
	settings_panel.visible = false
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	tab_neishi.disabled = false
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = false
	tab_lianli.disabled = false
	tab_settings.disabled = true
	if mail_module:
		mail_module.show_tab()

func show_herb_gather_panel():
	neishi_panel.visible = false
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = true
	if task_panel:
		task_panel.visible = false
	lianli_panel.visible = false
	settings_panel.visible = false
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	tab_neishi.disabled = false
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = true
	tab_lianli.disabled = false
	tab_settings.disabled = false
	if herb_gather_module:
		herb_gather_module.show_tab()

func show_task_panel():
	neishi_panel.visible = false
	chuna_panel.visible = false
	if region_panel:
		region_panel.visible = false
	if herb_gather_panel:
		herb_gather_panel.visible = false
	if task_panel:
		task_panel.visible = true
	lianli_panel.visible = false
	settings_panel.visible = false
	if alchemy_module:
		alchemy_module.hide_alchemy_room()
	tab_neishi.disabled = false
	tab_chuna.disabled = false
	if tab_region:
		tab_region.disabled = true
	tab_lianli.disabled = false
	tab_settings.disabled = false
	if task_module:
		task_module.show_tab()

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
	_system_refresh_timer.timeout.connect(_on_system_refresh_timer_timeout)

func _on_system_refresh_timer_timeout():
	if _system_refresh_inflight:
		return
	if not api:
		return
	_system_refresh_inflight = true
	await _refresh_notification_badges_from_server()
	_system_refresh_inflight = false


func _refresh_notification_badges_from_server() -> void:
	if _test_shutdown_requested:
		return
	_pending_notification_refresh_count += 1
	if task_module:
		await task_module.refresh_indicator_only()
	elif api:
		var task_result: Dictionary = await api.task_list()
		if task_result.get("success", false):
			_on_task_state_changed(_count_claimable_tasks_from_result(task_result))

	if mail_module:
		await mail_module.refresh_indicator_only()
	elif api:
		var mail_result: Dictionary = await api.mail_list()
		if mail_result.get("success", false):
			_on_mail_state_changed(int(mail_result.get("unread_count", 0)), int(mail_result.get("count", 0)))
	_pending_notification_refresh_count = maxi(0, _pending_notification_refresh_count - 1)


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
	lianli_area_buttons = []
	lianli_area_ids = []
	
	if lianli_area_1_button:
		lianli_area_buttons.append(lianli_area_1_button)
	if lianli_area_2_button:
		lianli_area_buttons.append(lianli_area_2_button)
	if lianli_area_3_button:
		lianli_area_buttons.append(lianli_area_3_button)
	if lianli_area_4_button:
		lianli_area_buttons.append(lianli_area_4_button)
	if lianli_area_6_button:
		lianli_area_buttons.append(lianli_area_6_button)
	if lianli_area_5_button:
		lianli_area_buttons.append(lianli_area_5_button)
	
	var normal_area_ids = []
	var daily_area_ids = []
	
	if lianli_area_data:
		normal_area_ids = lianli_area_data.get_normal_area_ids()
		daily_area_ids = lianli_area_data.get_daily_area_ids()
	else:
		normal_area_ids = ["area_1", "area_2", "area_3", "area_4"]
		daily_area_ids = ["foundation_herb_cave"]
	
	var tower_area_ids = ["sourth_endless_tower"]

	lianli_area_ids = normal_area_ids + daily_area_ids + tower_area_ids
	
	# 更新按钮文本和连接信号
	var current_index = 0
	
	# 获取lianli_system以获取tower_highest_floor
	var lianli_sys = get_node_or_null("/root/GameManager").get_lianli_system() if get_node_or_null("/root/GameManager") else null
	var tower_floor = 1
	if lianli_sys:
		tower_floor = lianli_sys.tower_highest_floor + 1
	
	# 显示普通区域
	for area_id in normal_area_ids:
		if current_index < lianli_area_buttons.size():
			var button = lianli_area_buttons[current_index]
			var area_name = lianli_area_data.get_area_name(area_id) if lianli_area_data else area_id
			button.text = area_name
			button.visible = true
			button.disabled = false
			# 断开之前的连接（避免重复连接）
			var connections = button.get_signal_connection_list("pressed")
			for conn in connections:
				button.pressed.disconnect(conn.callable)
			# 使用LianliModule处理
			if lianli_module:
				button.pressed.connect(lianli_module.on_lianli_area_pressed.bind(area_id))
			current_index += 1

	# 显示无尽塔
	for area_id in tower_area_ids:
		if current_index < lianli_area_buttons.size():
			var button = lianli_area_buttons[current_index]
			var area_name = ""
			if area_id == "sourth_endless_tower":
				var tower_name = lianli_area_data.get_tower_name() if lianli_area_data else "南麓试练塔"
				area_name = "%s (第%d层)" % [tower_name, tower_floor]
			else:
				area_name = lianli_area_data.get_area_name(area_id) if lianli_area_data else area_id
			
			button.text = area_name
			button.visible = true
			button.disabled = false
			var connections = button.get_signal_connection_list("pressed")
			for conn in connections:
				button.pressed.disconnect(conn.callable)
			if lianli_module:
				if area_id == "sourth_endless_tower":
					button.pressed.connect(lianli_module.on_endless_tower_pressed)
				else:
					button.pressed.connect(lianli_module.on_lianli_area_pressed.bind(area_id))
			current_index += 1

	# 显示每日副本
	for area_id in daily_area_ids:
		if current_index < lianli_area_buttons.size():
			var button = lianli_area_buttons[current_index]
			var area_name = lianli_area_data.get_area_name(area_id) if lianli_area_data else area_id
			# 使用缓存数据，不立即调用API
			_update_dungeon_button_text(button, area_id, area_name)
			button.visible = true
			button.disabled = false
			# 断开之前的连接（避免重复连接）
			var connections = button.get_signal_connection_list("pressed")
			for conn in connections:
				button.pressed.disconnect(conn.callable)
			# 使用LianliModule处理
			if lianli_module:
				button.pressed.connect(lianli_module.on_lianli_area_pressed.bind(area_id))
			current_index += 1
	
	# 隐藏剩余的按钮
	for i in range(current_index, lianli_area_buttons.size()):
		lianli_area_buttons[i].visible = false

# 副本信息缓存
var dungeon_info_cache: Dictionary = {}

# 更新副本按钮文本（只使用缓存数据）
func _update_dungeon_button_text(button: Button, dungeon_id: String, area_name: String):
	# 只显示缓存的信息或默认值
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
	if endless_tower_button and lianli_module:
		lianli_module.update_endless_tower_button_text(endless_tower_button)

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
	return _pending_refresh_all_player_data_count > 0 or _pending_notification_refresh_count > 0 or alchemy_pending or chuna_pending

func await_pending_test_tasks(max_frames: int = 120) -> void:
	var remaining_frames = max_frames
	while remaining_frames > 0 and has_pending_test_tasks():
		remaining_frames -= 1
		await get_tree().process_frame

# 更新历练区域按钮显示（用于刷新每日次数等）
func update_lianli_area_buttons_display():
	if not lianli_area_data or not player:
		return

	var normal_area_ids = lianli_area_data.get_normal_area_ids()
	var daily_area_ids = lianli_area_data.get_daily_area_ids()
	var tower_area_ids = ["sourth_endless_tower"]

	var current_index = 0

	for area_id in normal_area_ids:
		if current_index < lianli_area_buttons.size():
			var button = lianli_area_buttons[current_index]
			var area_name = lianli_area_data.get_area_name(area_id)
			button.text = area_name
			button.disabled = false
			current_index += 1

	var lianli_system = get_node_or_null("/root/GameManager").get_lianli_system() if get_node_or_null("/root/GameManager") else null
	var tower_floor = 1
	if lianli_system:
		tower_floor = lianli_system.tower_highest_floor + 1
	for area_id in tower_area_ids:
		if current_index < lianli_area_buttons.size():
			var button = lianli_area_buttons[current_index]
			var tower_name = lianli_area_data.get_tower_name() if lianli_area_data else "南麓试练塔"
			var area_name = tower_name + " (第" + str(tower_floor) + "层)"
			button.text = area_name
			button.disabled = false
			current_index += 1

	for area_id in daily_area_ids:
		if current_index < lianli_area_buttons.size():
			var button = lianli_area_buttons[current_index]
			var area_name = lianli_area_data.get_area_name(area_id)
			_update_dungeon_button_text(button, area_id, area_name)
			button.disabled = false
			current_index += 1

# ==================== 无尽塔功能 ====================

# 初始化无尽塔按钮
func _init_endless_tower_button():
	if endless_tower_button and lianli_module:
		endless_tower_button.pressed.connect(lianli_module.on_endless_tower_pressed)
		lianli_module.update_endless_tower_button_text(endless_tower_button)

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
	spirit_stone_label.text = "灵石: " + UIUtils.format_display_number(float(stone_count))
	if immortal_crystal_label:
		immortal_crystal_label.text = "仙晶: " + UIUtils.format_display_number(float(immortal_crystal_count))
	
	# 更新修炼面板显示（通过CultivationModule）
	if cultivation_module:
		cultivation_module.update_display(status)

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
	# 主动获取离线奖励
	# 服务端自动计算离线时间
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		return
	
	if api:
		var result = await api.claim_offline_reward()
		if result.get("success", false):
			var reward = result.get("offline_reward", null)
			if reward != null and reward is Dictionary:
				# 成功且有奖励
				var rewarded_offline_seconds = int(result.get("offline_seconds", 0))
				
				# 计算小时和分钟
				var total_minutes = int(rewarded_offline_seconds / 60)
				var hours = int(total_minutes / 60)
				var minutes = total_minutes % 60
				
				# 应用奖励
				if player:
					# 应用灵气奖励（不超过上限）
					if reward.has("spirit_energy"):
						# 使用add_spirit方法，它会自动处理上限
						player.add_spirit(reward.spirit_energy)
					
					# 应用灵石奖励
					if reward.has("spirit_stones") and inventory:
						inventory.add_item("spirit_stone", reward.spirit_stones)
				
				# 显示离线奖励信息
				if log_manager:
					log_manager.add_system_log("===================================")
					log_manager.add_system_log("离线时长: " + str(hours) + "小时" + str(minutes) + "分钟")
					log_manager.add_system_log("获得离线奖励：")
					if reward.has("spirit_energy"):
						log_manager.add_system_log("  - 灵气: +" + UIUtils.format_display_number(float(reward.spirit_energy)))
					if reward.has("spirit_stones"):
						log_manager.add_system_log("  - 灵石: +" + UIUtils.format_display_number(float(reward.spirit_stones)))
					log_manager.add_system_log("===================================")
				# 刷新UI
				update_ui()
				refresh_inventory_ui()
			else:
				# 成功但无奖励，不提示
				pass
		else:
			# 获取离线奖励失败
			if log_manager:
				var err_msg = _get_offline_reward_result_message(result, "获取离线奖励失败")
				if err_msg.is_empty():
					log_manager.add_system_log("获取离线奖励失败")
				else:
					log_manager.add_system_log(err_msg)

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
