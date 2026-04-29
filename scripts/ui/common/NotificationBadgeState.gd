extends Node

class_name NotificationBadgeState

signal state_changed(state: Dictionary)

const BADGE_REGION_TAB := "region_tab_badge"
const BADGE_SETTINGS_TAB := "settings_tab_badge"
const BADGE_TASK_BUTTON := "task_claimable"
const BADGE_MAIL_BUTTON := "mail_unread"

var _state := {
	"task_claimable_count": 0,
	"mail_unread_count": 0,
	"task_claimable": false,
	"mail_unread": false,
	"region_tab_badge": false,
	"settings_tab_badge": false,
}


func update_task_claimable_count(count: int) -> void:
	var safe_count := maxi(0, count)
	_state["task_claimable_count"] = safe_count
	_state["task_claimable"] = safe_count > 0
	_state["region_tab_badge"] = bool(_state["task_claimable"])
	_emit_state_changed()


func update_mail_unread_count(count: int) -> void:
	var safe_count := maxi(0, count)
	_state["mail_unread_count"] = safe_count
	_state["mail_unread"] = safe_count > 0
	_state["settings_tab_badge"] = bool(_state["mail_unread"])
	_emit_state_changed()


func reset() -> void:
	_state = {
		"task_claimable_count": 0,
		"mail_unread_count": 0,
		"task_claimable": false,
		"mail_unread": false,
		"region_tab_badge": false,
		"settings_tab_badge": false,
	}
	_emit_state_changed()


func get_badge_visible(key: String) -> bool:
	return bool(_state.get(key, false))


func get_state() -> Dictionary:
	return _state.duplicate(true)


func _emit_state_changed() -> void:
	state_changed.emit(get_state())
