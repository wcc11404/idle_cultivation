extends GutTest

const MODULE_HARNESS = preload("res://tests_gut/support/ModuleHarness.gd")

var harness: ModuleHarness = null

func _toggle_and_get_last_log(module, retries: int = 3, retry_wait: float = 0.12) -> String:
	for i in range(retries):
		await module._on_spell_equip_toggle()
		var msg = harness.last_log()
		if not msg.is_empty():
			return msg
		if i < retries - 1:
			await get_tree().create_timer(retry_wait).timeout
	return harness.last_log()

func before_each():
	harness = MODULE_HARNESS.new()
	add_child(harness)
	await harness.bootstrap("http://localhost:8444/api", "spell_ready")

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame

func test_spell_slot_limit_then_unequip_and_equip_messages():
	var module = harness.game_ui.spell_module

	module.current_viewing_spell = "basic_defense"
	harness.clear_logs()
	var limit_msg = await _toggle_and_get_last_log(module)
	assert_eq(limit_msg, "开局术法槽位已达上限，请先卸下任意术法", "槽位上限提示应使用中文槽位名")

	await get_tree().create_timer(0.2).timeout
	module.current_viewing_spell = "basic_steps"
	harness.clear_logs()
	var unequip_msg = await _toggle_and_get_last_log(module)
	assert_eq(unequip_msg, "基础步法卸下成功", "卸下成功文案应由客户端翻译")

	await get_tree().create_timer(0.2).timeout
	module.current_viewing_spell = "basic_defense"
	harness.clear_logs()
	var equip_msg = await _toggle_and_get_last_log(module)
	assert_eq(equip_msg, "基础防御装备成功", "装备成功文案应由客户端翻译")

func test_spell_actions_are_locked_during_battle():
	await harness.client.test_post("/test/set_runtime_state", {
		"is_in_lianli": true,
		"is_battling": true,
		"current_area_id": "area_1"
	})

	var spell_module = harness.game_ui.spell_module
	spell_module.current_viewing_spell = "basic_steps"
	harness.clear_logs()
	await spell_module._on_spell_equip_toggle()

	assert_true(harness.last_log().contains("战斗中无法"), "战斗中应拦截术法操作并输出客户端文案")

func test_spell_upgrade_and_charge_failure_messages_use_reason_code_copy():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module
	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_basic_boxing_techniques": 1
		}
	})
	assert_true(set_items.get("success", false), "应能补发基础拳法术法书")
	var unlock_result = await harness.client.inventory_use("spell_basic_boxing_techniques")
	assert_true(unlock_result.get("success", false), "应能先解锁基础拳法")

	module.current_viewing_spell = "basic_boxing_techniques"
	var upgrade_result = await harness.client.spell_upgrade("basic_boxing_techniques")
	assert_false(upgrade_result.get("success", true), "基础拳法在初始状态下不应满足升级条件")
	assert_true(module._get_spell_result_text(upgrade_result, "").contains("使用次数不足"), "升级失败应输出结构化次数不足文案")

	var player_state = await harness.client.test_post("/test/set_player_state", {"spirit_energy": 0})
	assert_true(player_state.get("success", false), "应能构造灵气不足状态")
	await harness.sync_full_state()

	module.current_viewing_spell = "basic_boxing_techniques"
	var charge_result = await harness.client.spell_charge("basic_boxing_techniques", 1)
	assert_false(charge_result.get("success", true), "自身灵气为0时充灵应失败")
	assert_true(module._get_spell_result_text(charge_result, "").contains("自身灵气不足"), "充灵失败应输出结构化灵气不足文案")

func test_spell_detail_popup_upgrade_conditions_sync_after_unlock_and_charge():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_basic_breathing": 1
		}
	})
	assert_true(set_items.get("success", false), "应能补发基础吐纳术法书")

	var set_player = await harness.client.test_post("/test/set_player_state", {
		"spirit_energy": 10
	})
	assert_true(set_player.get("success", false), "应能构造足够灵气状态")

	await harness.sync_full_state()

	var use_result = await harness.client.inventory_use("spell_basic_breathing")
	assert_true(use_result.get("success", false), "应能解锁基础吐纳")
	await harness.sync_full_state()

	module.current_viewing_spell = "basic_breathing"
	module._show_spell_detail("basic_breathing")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	assert_not_null(popup, "应创建术法详情弹窗")

	var use_count_label = popup.vbox.get_node_or_null("UpgradeConditionsBox/UseCountRow/UseCountValueLabel") if popup and popup.vbox else null
	var spirit_amount_label = popup.vbox.get_node_or_null("UpgradeConditionsBox/SpiritChargeRow/SpiritAmountLabel") if popup and popup.vbox else null
	var blank_jade_row = popup.vbox.get_node_or_null("StarConditionsBox/BlankJadeRow") if popup and popup.vbox else null
	var blank_jade_label = popup.vbox.get_node_or_null("StarConditionsBox/BlankJadeRow/BlankJadeLabel") if popup and popup.vbox else null
	var blank_jade_value_label = popup.vbox.get_node_or_null("StarConditionsBox/BlankJadeRow/BlankJadeValueLabel") if popup and popup.vbox else null
	assert_not_null(use_count_label, "弹窗应包含使用次数标签")
	assert_not_null(spirit_amount_label, "弹窗应包含所需灵气标签")
	assert_not_null(blank_jade_row, "弹窗应包含空白玉简升星条件占位行")
	assert_true(blank_jade_row.visible, "无空白玉简需求时仍应保留占位行，避免弹窗高度跳动")
	assert_eq(blank_jade_label.text, "", "无空白玉简需求时名称占位应为空")
	assert_eq(blank_jade_value_label.text, "", "无空白玉简需求时数量占位应为空")
	var level_data = module.spell_data.get_spell_level_data("basic_breathing", 1)
	var required_spirit = int(level_data.get("spirit_cost", 0))
	var expected_initial_charge_text = "0 / %d" % required_spirit
	assert_eq(use_count_label.text, "0 / 100", "解锁后升级条件应同步新的术法真值配置")
	assert_eq(spirit_amount_label.text, expected_initial_charge_text, "解锁后充灵条件应同步当前术法真值配置")

	var player_spirit_before_charge = int(module.player.spirit_energy) if module.player else 0
	await module._on_spell_charge_pressed()
	await get_tree().process_frame

	var expected_charged_amount = mini(10, mini(required_spirit, player_spirit_before_charge))
	var expected_charge_progress_text = "%d / %d" % [expected_charged_amount, required_spirit]
	assert_eq(spirit_amount_label.text, expected_charge_progress_text, "充灵后弹窗应实时反映当前规则下的充灵进度")

func test_spell_detail_popup_unobtained_spell_uses_level_one_preview():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	# 确保基础吐纳未解锁（只校验“未获得术法”分支展示）
	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_basic_breathing": 0
		}
	})
	assert_true(set_items.get("success", false), "应能清空术法解锁道具")
	await harness.sync_full_state()

	module.current_viewing_spell = "basic_breathing"
	module._show_spell_detail("basic_breathing")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	assert_not_null(popup, "应创建术法详情弹窗")

	var level_label = popup.vbox.get_node_or_null("LevelLabel") if popup and popup.vbox else null
	var attr_value = popup.vbox.get_node_or_null("AttributeValue") if popup and popup.vbox else null
	var effect_value = popup.vbox.get_node_or_null("EffectValue") if popup and popup.vbox else null
	var use_count_label = popup.vbox.get_node_or_null("UpgradeConditionsBox/UseCountRow/UseCountValueLabel") if popup and popup.vbox else null
	var spirit_amount_label = popup.vbox.get_node_or_null("UpgradeConditionsBox/SpiritChargeRow/SpiritAmountLabel") if popup and popup.vbox else null

	assert_not_null(level_label, "弹窗应包含等级标签")
	assert_not_null(attr_value, "弹窗应包含属性加成标签")
	assert_not_null(effect_value, "弹窗应包含术法效果标签")
	assert_not_null(use_count_label, "弹窗应包含使用次数标签")
	assert_not_null(spirit_amount_label, "弹窗应包含所需灵气标签")

	assert_eq(level_label.text, "等级：未解锁", "未获得术法应显示未解锁等级文案")
	assert_true(not attr_value.text.is_empty(), "未获得术法时属性加成应按1级数据展示")
	assert_true(not effect_value.text.is_empty(), "未获得术法时术法效果应按1级数据展示")
	assert_eq(use_count_label.text, "- / -", "未获得术法升级条件应保持未解锁占位文案")
	assert_eq(spirit_amount_label.text, "- / -", "未获得术法充灵条件应保持未解锁占位文案")

func test_spell_detail_popup_front_click_does_not_close_popup():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	module.current_viewing_spell = "basic_breathing"
	module._show_spell_detail("basic_breathing")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	assert_not_null(popup, "应创建术法详情弹窗")
	assert_true(popup.is_popup_visible(), "术法详情弹窗应处于显示状态")

	var global_point: Vector2 = popup.global_position + popup.size * 0.5
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = global_point
	click_event.global_position = global_point
	popup.background.gui_input.emit(click_event)

	assert_true(popup.is_popup_visible(), "点击弹窗前景区域时不应触发外部遮罩关闭")

func test_spell_detail_success_feedback_keeps_popup_visible():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	module.current_viewing_spell = "basic_breathing"
	module._show_spell_detail("basic_breathing")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	assert_not_null(popup, "应创建术法详情弹窗")
	assert_true(popup.is_popup_visible(), "术法详情弹窗应处于显示状态")

	popup.modulate.a = 0.0
	popup.play_success_feedback()
	await get_tree().create_timer(0.42).timeout

	assert_true(popup.is_popup_visible(), "成功反馈后弹窗仍应处于显示状态")
	assert_true(popup.modulate.a > 0.95, "成功反馈不应把弹窗根节点留成透明")
	assert_true(popup.vbox.modulate.a > 0.95, "成功反馈结束后内容容器应恢复可见")

func test_spell_thumbnail_uses_full_card_detail_entry_and_single_action_button():
	await harness.apply_preset_and_sync("spell_ready")
	var module = harness.game_ui.spell_module
	await module.show_tab()

	var equipped_spell_id := ""
	for spell_id in module.spell_system.get_player_spells().keys():
		var spell_data = module.spell_system.get_player_spells()[spell_id]
		var spell_info = module.spell_data.get_spell_data(str(spell_id))
		if bool(spell_data.get("obtained", false)) and str(spell_info.get("type", "")) != "production":
			equipped_spell_id = str(spell_id)
			break
	assert_false(equipped_spell_id.is_empty(), "测试前应存在一个已获得的非生产术法")
	if equipped_spell_id.is_empty():
		return
	var equipped_type = str(module.spell_data.get_spell_data(equipped_spell_id).get("type", "active"))
	module.spell_system.equipped_spells[equipped_type] = [equipped_spell_id]
	module.update_spell_ui()

	var equipped_card = module.spell_cards.get(equipped_spell_id)
	assert_not_null(equipped_card, "术法页中应存在已装备术法卡片")
	var equipped_vbox = equipped_card.get_child(0) if equipped_card and equipped_card.get_child_count() > 0 else null
	assert_not_null(equipped_vbox, "术法卡片应保留根 VBox，供测试和模块定位")
	if equipped_vbox == null:
		return
	assert_null(equipped_vbox.get_node_or_null("ButtonContainer/ViewButton"), "术法缩略卡不再包含查看按钮")

	var equip_button = equipped_vbox.get_node_or_null("ButtonContainer/EquipButton")
	assert_not_null(equip_button, "非生产术法应保留装备/卸下按钮")
	assert_true(equip_button.custom_minimum_size.x >= 90.0, "单按钮布局下装备按钮应居中加宽")

	var equipped_badge = equipped_vbox.get_node_or_null("TopArea/EquippedBadge")
	assert_not_null(equipped_badge, "术法卡片应包含已装备徽章节点")
	assert_true(equipped_badge.visible, "已装备术法应显示已装备徽章")

func test_production_spell_thumbnail_hides_action_button_but_keeps_card_entry():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module
	await module.show_tab()

	var production_card: Control = null
	for spell_id in module.spell_cards.keys():
		var spell_info = module.spell_data.get_spell_data(str(spell_id))
		if str(spell_info.get("type", "")) == "production":
			production_card = module.spell_cards[spell_id]
			break

	assert_not_null(production_card, "术法页中应存在生产术法卡片")
	var vbox = production_card.get_child(0) if production_card and production_card.get_child_count() > 0 else null
	assert_not_null(vbox, "生产术法卡片应保留根 VBox")
	var button_container = vbox.get_node_or_null("ButtonContainer")
	assert_not_null(button_container, "生产术法仍保留按钮容器节点，避免池化复用缺字段")
	assert_false(button_container.visible, "生产术法卡片不显示底部按钮，详情入口统一为点击整卡")

func test_spell_detail_popup_obtained_spell_uses_runtime_effect_copy():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_basic_boxing_techniques": 1
		}
	})
	assert_true(set_items.get("success", false), "应能补发基础拳法术法书")

	var use_result = await harness.client.inventory_use("spell_basic_boxing_techniques")
	assert_true(use_result.get("success", false), "应能解锁基础拳法")
	await harness.sync_full_state()

	module.current_viewing_spell = "basic_boxing_techniques"
	module._show_spell_detail("basic_boxing_techniques")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	assert_not_null(popup, "应创建术法详情弹窗")

	var effect_value = popup.vbox.get_node_or_null("EffectValue") if popup and popup.vbox else null
	assert_not_null(effect_value, "弹窗应包含术法效果标签")
	assert_eq(effect_value.text, "战斗中有概率造成1.1倍伤害", "已获得术法应显示运行时效果文案而不是旧占位文本")

func test_spell_detail_popup_multi_effect_spell_formats_drain_text():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_wither_glory_art": 1
		}
	})
	assert_true(set_items.get("success", false), "应能补发枯荣诀术法书")

	var use_result = await harness.client.inventory_use("spell_wither_glory_art")
	assert_true(use_result.get("success", false), "应能解锁枯荣诀")
	await harness.sync_full_state()

	module.current_viewing_spell = "wither_glory_art"
	module._show_spell_detail("wither_glory_art")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	var effect_value = popup.vbox.get_node_or_null("EffectValue") if popup and popup.vbox else null
	assert_not_null(effect_value, "弹窗应包含术法效果标签")
	assert_eq(effect_value.text, "战斗中有概率造成1.6倍伤害，并恢复造成伤害的2%气血", "多效果术法应正确展开吸血占位符")

func test_spell_detail_popup_multi_effect_spell_formats_turn_gauge_text():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module

	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_reverse_wave_break": 1
		}
	})
	assert_true(set_items.get("success", false), "应能补发逆浪破术法书")

	var use_result = await harness.client.inventory_use("spell_reverse_wave_break")
	assert_true(use_result.get("success", false), "应能解锁逆浪破")
	await harness.sync_full_state()

	module.current_viewing_spell = "reverse_wave_break"
	module._show_spell_detail("reverse_wave_break")
	await get_tree().process_frame

	var popup = module.spell_detail_popup
	var effect_value = popup.vbox.get_node_or_null("EffectValue") if popup and popup.vbox else null
	assert_not_null(effect_value, "弹窗应包含术法效果标签")
	assert_eq(effect_value.text, "战斗中有概率造成1.6倍伤害，并使敌方行动条减少5%", "多效果术法应正确展开行动条占位符")
