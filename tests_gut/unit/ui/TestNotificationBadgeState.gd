extends GutTest

const MODULE_HARNESS = preload("res://tests_gut/support/ModuleHarness.gd")
const NOTIFICATION_BADGE_STATE_SCRIPT = preload("res://scripts/ui/common/NotificationBadgeState.gd")

var harness: ModuleHarness = null


func before_each():
	harness = MODULE_HARNESS.new()
	add_child(harness)
	await harness.bootstrap("http://localhost:8444/api")


func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame


func test_notification_badge_state_aggregates_task_and_mail():
	var state = NOTIFICATION_BADGE_STATE_SCRIPT.new()
	add_child(state)

	state.update_task_claimable_count(2)
	assert_eq(state.get_state().get("task_claimable_count", -1), 2, "任务可领奖数应写入状态")
	assert_true(state.get_badge_visible("task_claimable"), "任务按钮红点应点亮")
	assert_true(state.get_badge_visible("region_tab_badge"), "地区页签红点应透传点亮")
	assert_false(state.get_badge_visible("settings_tab_badge"), "未读邮箱未更新前设置页签不应点亮")

	state.update_mail_unread_count(3)
	assert_eq(state.get_state().get("mail_unread_count", -1), 3, "邮箱未读数应写入状态")
	assert_true(state.get_badge_visible("mail_unread"), "邮箱按钮红点应点亮")
	assert_true(state.get_badge_visible("settings_tab_badge"), "设置页签红点应透传点亮")

	state.reset()
	assert_false(state.get_badge_visible("task_claimable"), "重置后任务按钮红点应熄灭")
	assert_false(state.get_badge_visible("mail_unread"), "重置后邮箱按钮红点应熄灭")
	remove_child(state)
	state.queue_free()
	await get_tree().process_frame


func test_game_ui_badges_follow_state_updates():
	var game_ui = harness.game_ui
	game_ui.clear_notification_badges()

	assert_false(_is_badge_visible(game_ui.tab_region, "region_tab_badge"), "初始地区页签红点应熄灭")
	assert_false(_is_badge_visible(game_ui.tab_settings, "settings_tab_badge"), "初始设置页签红点应熄灭")
	assert_false(_is_badge_visible(game_ui.xianwu_office_button, "task_claimable"), "初始任务按钮红点应熄灭")
	assert_false(_is_badge_visible(game_ui.mailbox_button, "mail_unread"), "初始邮箱按钮红点应熄灭")

	game_ui._on_task_state_changed(1)
	assert_true(_is_badge_visible(game_ui.tab_region, "region_tab_badge"), "任务可领取时地区页签红点应点亮")
	assert_true(_is_badge_visible(game_ui.xianwu_office_button, "task_claimable"), "任务可领取时仙务司按钮红点应点亮")
	assert_eq(_get_badge_text(game_ui.xianwu_office_button, "task_claimable"), "1", "任务按钮红点应显示数量")
	assert_false(_is_badge_visible(game_ui.tab_settings, "settings_tab_badge"), "仅任务有红点时设置页签应保持熄灭")

	game_ui._on_mail_state_changed(2, 2)
	assert_true(_is_badge_visible(game_ui.tab_settings, "settings_tab_badge"), "邮箱未读时设置页签红点应点亮")
	assert_true(_is_badge_visible(game_ui.mailbox_button, "mail_unread"), "邮箱未读时邮箱按钮红点应点亮")
	assert_eq(_get_badge_text(game_ui.mailbox_button, "mail_unread"), "2", "邮箱按钮红点应显示未读数量")

	game_ui._on_task_state_changed(108)
	assert_eq(_get_badge_text(game_ui.xianwu_office_button, "task_claimable"), "99+", "任务数量超过 99 时应封顶显示")

	game_ui.clear_notification_badges()
	assert_false(_is_badge_visible(game_ui.tab_region, "region_tab_badge"), "重置后地区页签红点应熄灭")
	assert_false(_is_badge_visible(game_ui.tab_settings, "settings_tab_badge"), "重置后设置页签红点应熄灭")
	assert_eq(_get_badge_text(game_ui.mailbox_button, "mail_unread"), "", "重置后数字角标文案应清空")


func _is_badge_visible(target: Control, key: String) -> bool:
	if not target:
		return false
	var badge = target.get_node_or_null("NotificationBadge_" + key)
	return badge != null and badge.visible


func _get_badge_text(target: Control, key: String) -> String:
	if not target:
		return ""
	var badge = target.get_node_or_null("NotificationBadge_" + key)
	if not badge:
		return ""
	var count_label = badge.get_node_or_null("CountLabel")
	return count_label.text if count_label else ""
