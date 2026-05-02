extends Control

const MAIN_SCENE := preload("res://scenes/app/Main.tscn")

func _ready() -> void:
	var main_instance := MAIN_SCENE.instantiate()
	add_child(main_instance)
	await get_tree().process_frame
	await get_tree().process_frame

	var bottom_tab_bar: HBoxContainer = main_instance.get_node("ContentFrame/VBoxContainer/TabBar")
	var neishi_tab_bar: HBoxContainer = main_instance.get_node("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/NeishiTopTabShell/NeishiTabBar")
	var top_bar: Control = main_instance.get_node("ContentFrame/VBoxContainer/TopBar")
	var top_bar_content: HBoxContainer = main_instance.get_node("ContentFrame/VBoxContainer/TopBar/TopBarContent")
	var status_header_row: HBoxContainer = main_instance.get_node("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/StatusArea/PlayerDataContainer/VBoxContainer/StatsHeaderRow")
	var breakthrough_header_row: HBoxContainer = main_instance.get_node("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/CultivationContainer/BreakthroughPanel/BreakthroughPanelMargin/BreakthroughPanelVBox/BreakthroughHeaderRow")
	print("[TabProbe] bottom_tab_bar size=", bottom_tab_bar.size, " custom_min=", bottom_tab_bar.custom_minimum_size)
	print("[TabProbe] neishi_tab_bar size=", neishi_tab_bar.size, " custom_min=", neishi_tab_bar.custom_minimum_size)
	print("[TabProbe] top_bar size=", top_bar.size, " custom_min=", top_bar.custom_minimum_size, " content_offsets=(", top_bar_content.offset_top, ",", top_bar_content.offset_bottom, ")")

	var bottom_btn: Button = bottom_tab_bar.get_node("NeishiButton")
	var neishi_btn: Button = neishi_tab_bar.get_node("CultivationTabSlot/CultivationTab")
	var neishi_shell: PanelContainer = main_instance.get_node("ContentFrame/VBoxContainer/ContentPanel/NeishiPanel/NeishiTopTabShell")
	print("[TabProbe] bottom_btn size=", bottom_btn.size, " custom_min=", bottom_btn.custom_minimum_size)
	print("[TabProbe] neishi_btn size=", neishi_btn.size, " custom_min=", neishi_btn.custom_minimum_size)
	var shell_style: StyleBoxFlat = neishi_shell.get("theme_override_styles/panel") as StyleBoxFlat
	var normal_style: StyleBoxFlat = neishi_btn.get("theme_override_styles/normal") as StyleBoxFlat
	var selected_style: StyleBoxFlat = neishi_btn.get("theme_override_styles/disabled") as StyleBoxFlat
	print("[TabProbe] neishi_shell bg=", shell_style.bg_color if shell_style else "null")
	print("[TabProbe] neishi_btn normal bg=", normal_style.bg_color if normal_style else "null")
	print("[TabProbe] neishi_btn selected bg=", selected_style.bg_color if selected_style else "null")
	print("[TabProbe] status_header sep=", status_header_row.get_theme_constant("separation"))
	print("[TabProbe] breakthrough_header sep=", breakthrough_header_row.get_theme_constant("separation"))

	get_tree().quit()
