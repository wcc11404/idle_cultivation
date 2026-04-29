extends GutTest

const MODULE_HARNESS = preload("res://tests_gut/support/ModuleHarness.gd")

var harness: ModuleHarness = null
var _signal_count := 0
var _unread_count := -1
var _total_count := -1


func before_each():
	harness = MODULE_HARNESS.new()
	add_child(harness)
	await harness.bootstrap("http://localhost:8444/api")
	_signal_count = 0
	_unread_count = -1
	_total_count = -1


func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame


func test_mail_module_panel_shows_and_refreshes():
	await harness.client.reset_account()
	await harness.sync_full_state()

	var module = harness.game_ui.mail_module
	assert_not_null(module, "MailModule 应初始化")
	assert_not_null(module.panel, "MailPanel 应创建")

	await module.show_tab()
	assert_true(module.panel.visible, "show_tab 后面板应可见")
	assert_true(module.count_label.text.contains("邮件"), "数量文案应包含“邮件”")


func test_mail_indicator_refresh_keeps_session_state():
	await harness.client.reset_account()
	await harness.sync_full_state()

	var module = harness.game_ui.mail_module
	assert_not_null(module, "MailModule 应初始化")
	module.mail_state_changed.connect(func(unread: int, total: int):
		_signal_count += 1
		_unread_count = unread
		_total_count = total
	)

	await module.refresh_indicator_only()
	assert_eq(_signal_count, 1, "刷新邮箱摘要时应发出一次状态信号")
	assert_gte(_unread_count, 0, "邮箱未读数量应为非负数")
	assert_gte(_total_count, _unread_count, "邮箱总数应不小于未读数")
