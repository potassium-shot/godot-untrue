## Specifies the scenes for the player character, camera and controller, as well
## as a hud. Can be extended to hold game mode specific code.
@tool @icon("res://addons/untrue/icons/Gamemode.svg")
class_name GameMode extends Resource

@export_group("Player", "player_")

## Player character, for example a character body. Can be null.
@export var player_character_scene: PackedScene = null:
	set(value):
		player_character_scene = value
		
		if not Engine.is_editor_hint() and _is_started:
			_any_player_scene_updated(&"character")

## The main player camera. Can be null.
@export var player_camera_scene: PackedScene = null:
	set(value):
		player_camera_scene = value
		
		if not Engine.is_editor_hint() and _is_started:
			_any_player_scene_updated(&"camera")

## Player controller, handles player input. Can be null.
@export var player_controller_scene: PackedScene = null:
	set(value):
		player_controller_scene = value
		
		if not Engine.is_editor_hint() and _is_started:
			_any_player_scene_updated(&"controller")

## Root of the UI. Can be null.
@export var hud_scene: PackedScene = null:
	set(value):
		hud_scene = value
		
		if not Engine.is_editor_hint() and _is_started:
			_hud_scene_updated()

## Emitted when the player character instance is changed, including when the
## [GameMode] starts. Never called if there is none.
signal player_character_changed(p_new_player_character: Node)

## Emitted when the player camera instance is changed, including when the
## [GameMode] starts. Never called if there is none.
signal player_camera_changed(p_new_player_camera: Node)

## Emitted when the player controller instance is changed, including when the
## [GameMode] starts. Never called if there is none.
signal player_controller_changed(p_new_player_controller: Node)

## Emitted when the hud instance is changed, including when the
## [GameMode] starts. Never called if there is none.
signal hud_changed(p_new_hud: Control)

var _player_character: Node:
	set(value):
		_player_character = value
		player_character_changed.emit(value)

var _player_camera: Node:
	set(value):
		_player_camera = value
		player_camera_changed.emit(value)

var _player_controller: Node:
	set(value):
		_player_controller = value
		player_controller_changed.emit(value)

var _hud: Control:
	set(value):
		_hud = value
		hud_changed.emit(value)


var _is_started: bool = false

## Called when the [GameMode] starts, see [method GameMode._started]
const NOTIFICATION_STARTED: int = 160

## Called when the [GameMode] stops, see [method GameMode._stopped]
const NOTIFICATION_STOPPED: int = 161

## Called when the [LevelRoot] is changed, but the current [GameMode] is kept.
## See [method GameMode._level_changed]
const NOTIFICATION_LEVEL_CHANGED: int = 162

func _notification(what: int):
	match what:
		NOTIFICATION_STARTED:
			_is_started = true
			_any_player_scene_updated(&"character")
			_any_player_scene_updated(&"camera")
			_any_player_scene_updated(&"controller")
			_hud_scene_updated()
			_started()
		
		NOTIFICATION_STOPPED:
			_stopped()
			
			if _player_character:
				_player_character.queue_free()
			if _player_camera:
				_player_camera.queue_free()
			if _player_controller:
				_player_controller.queue_free()
			if _hud:
				_hud.queue_free()
			
			_is_started = false
		
		NOTIFICATION_LEVEL_CHANGED:
			_level_changed()
		
		_:
			pass

func _any_player_scene_updated(scene: StringName):
	var current_one_property_name: StringName = "_player_%s" % scene
	var current_one: Node = get(current_one_property_name)
	
	if current_one:
		current_one.queue_free()
	
	var packed_scene: PackedScene = get("player_%s_scene" % scene)
	
	if packed_scene:
		var new_one: Node = packed_scene.instantiate()
		Game.get_world().add_child(new_one)
		
		if scene == &"character": # Don't judge me please
			var node_2d = new_one as Node2D
			
			if node_2d:
				var selected_spawn = _select_spawn_point_2d()
				
				if selected_spawn:
					node_2d.global_position = selected_spawn.global_position
			else:
				var node_3d = new_one as Node3D
				
				if node_3d:
					var select_spawn = _select_spawn_point_3d()
					
					if select_spawn:
						node_3d.global_position = select_spawn.global_position
		
		set(current_one_property_name, new_one)
	else:
		set(current_one_property_name, null)

func _hud_scene_updated():
	if _hud:
		_hud.queue_free()
	
	if hud_scene:
		var new_hud: Control = hud_scene.instantiate() as Control
		assert(new_hud, "Hud scene should be a valid Control")
		Game.get_game_root().hud_root.add_child(new_hud)
		_hud = new_hud
	else:
		_hud = null

## Returns [code]true[/code] if the [GameMode] is started and hasn't stopped.
func is_started() -> bool:
	return _is_started

## Called when the [GameMode] is started, guarranteed to be after the [GameRoot]
## and the [LevelRoot] are ready.
func _started():
	pass

## Called when the [GameMode] is stopped, which can happen if the [GameMode] is
## switched with another, if the [LevelRoot] is destroyed, or if the game stops.
func _stopped():
	pass

## Called when the [LevelRoot] is changed, but the [GameMode] is kept.
## Happens if the new [LevelRoot] did not have a [GameMode] of its own,
## or if it had the same type of [GameMode] and [code]TODO[/code] is
## [code]true[/code].
func _level_changed():
	pass

## Selects a spawn point. Default behaviour is to select a random one, but it can
## be overriden. Call [method PlayerSpawn2D.get_available] to get a list of available
## [PlayerSpawn2D] nodes.
func _select_spawn_point_2d() -> PlayerSpawn2D:
	var spawn_points: Array = PlayerSpawn2D.get_available()
	
	if not spawn_points.is_empty():
		return spawn_points.pick_random()
	else:
		return null

## Selects a spawn point. Default behaviour is to select a random one, but it can
## be overriden. Call [method PlayerSpawn3D.get_available] to get a list of available
## [PlayerSpawn3D] nodes.
func _select_spawn_point_3d() -> PlayerSpawn3D:
	var spawn_points: Array = PlayerSpawn3D.get_available()
	
	if not spawn_points.is_empty():
		return spawn_points.pick_random()
	else:
		return null

func _transfer_scenes(p_new_level: LevelRoot):
	if _player_character:
		_player_character.get_parent().remove_child(_player_character)
		p_new_level.add_child(_player_character)
	
	if _player_camera:
		_player_camera.get_parent().remove_child(_player_camera)
		p_new_level.add_child(_player_camera)
	
	if _player_controller:
		_player_controller.get_parent().remove_child(_player_controller)
		p_new_level.add_child(_player_controller)

## Returns the current instance of [member GameMode.player_character_scene], if any
func get_player_character() -> Node:
	return _player_character

## Returns the current instance of [member GameMode.player_camera_scene], if any
func get_player_camera() -> Node:
	return _player_camera

## Returns the current instance of [member GameMode.player_controller_scene], if any
func get_player_controller() -> Node:
	return _player_controller

## Returns the current instance of [member GameMode.hud_scene], if any
func get_hud() -> Control:
	return _hud
