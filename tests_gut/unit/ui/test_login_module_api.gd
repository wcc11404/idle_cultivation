extends GutTest

const LoginScene = preload("res://scenes/app/Login.tscn")
const SessionHelperRef = preload("res://tests_gut/support/session_helper.gd")
const ServerConfig = preload("res://scripts/network/ServerConfig.gd")

var login_ui: Control = null

func before_each():
	SessionHelperRef.reset_local_session("http://localhost:8444/api")
	login_ui = LoginScene.instantiate()
	add_child(login_ui)
	await get_tree().process_frame
	await get_tree().process_frame

func after_each():
	if login_ui and is_instance_valid(login_ui):
		if login_ui.get_parent() == self:
			remove_child(login_ui)
		login_ui.free()
		login_ui = null
	SessionHelperRef.reset_local_session("http://localhost:8444/api")
	await get_tree().process_frame

func _random_username(prefix: String = "gut_user_") -> String:
	return prefix + str(Time.get_ticks_usec())

func test_login_unregistered_username_uses_reason_code_copy():
	login_ui.username_input.text = _random_username("not_found_")
	login_ui.password_input.text = "abc123!@#"

	await login_ui._on_login_pressed()

	assert_eq(login_ui.message_label.text, "用户名未注册", "未注册账号应映射为固定客户端文案")

func test_login_wrong_password_uses_reason_code_copy():
	login_ui.username_input.text = "test"
	login_ui.password_input.text = "wrong_password_123"

	await login_ui._on_login_pressed()

	assert_eq(login_ui.message_label.text, "密码错误", "密码错误应映射为固定客户端文案")

func test_register_existing_username_uses_reason_code_copy():
	login_ui.username_input.text = "test"
	login_ui.password_input.text = "abc123!@#"

	await login_ui._on_register_pressed()

	assert_eq(login_ui.message_label.text, "用户名已存在", "已存在用户名应映射为固定客户端文案")

func test_refresh_invalid_token_prompts_relogin_and_clears_token():
	var file = FileAccess.open(ServerConfig.TOKEN_FILE, FileAccess.WRITE)
	assert_not_null(file, "应能写入测试 token 文件")
	file.store_string("invalid_token_for_refresh")
	file.close()
	assert_true(login_ui.api.network_manager.load_token(), "应能加载伪造 token")

	await login_ui.check_auto_login()

	assert_eq(login_ui.message_label.text, "请重新登录", "refresh 失败应提示重新登录")
	assert_false(FileAccess.file_exists(ServerConfig.TOKEN_FILE), "refresh 失败后应清理本地 token")
