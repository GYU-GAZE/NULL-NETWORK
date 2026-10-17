extends Control

var ready_size: Vector2
var ready_content_size: Vector2
var ready_window_rect: Rect2
var ready_maximized: bool


func _ready() -> void:
	ready_size = size
	ready_content_size = (get_parent() as Control).size
	var window := get_parent().get_parent().get_parent().get_parent().get_parent() as WindowBase
	ready_window_rect = window.get_rect()
	ready_maximized = window.is_maximized
