## Root of the game, can switch levels, and can hold the root of the hud. Can be
## extended to hold game-level code. Get its single instance with
## [code]Game.get_root()[/code].
@tool @icon("res://addons/untrue/icons/GameRoot.svg")
class_name GameRoot extends Node

static var _instance: GameRoot

## The level to instantiate automatically at the start of the level, if set.
@export var default_level: PackedScene = null

## Node into which instantiate the hud of a [GameMode]. If not set, defaults to this [GameRoot].
## Useful for putting the UI into a separate [CanvasLayer].
@export var hud_root: Node = null

## The [PackedScene] corresponding to the currently loaded level; switching it
## switches the current level. Can be null.
var current_level: PackedScene = null:
	set(value):
		current_level = value
		
		if Engine.is_editor_hint():
			return
		
		var new_level: LevelRoot = null
		var gamemode_kept: bool = false
		
		if value:
			new_level = value.instantiate() as LevelRoot
			
			assert(
				new_level or not value,
				"PackedScene assigned to current_level in GameRoot should be valid LevelRoot"
			)
			
			if (new_level.gamemode_replaceable and _instanced_level) or not new_level.game_mode:
				assert(_instanced_level, "Tried to start a level without a gamemode")
				_instanced_level._transfer_gamemode(new_level)
				gamemode_kept = true
		
		if _instanced_level:
			_instanced_level.queue_free()
		
		if new_level:
			_instanced_level = new_level
			add_child(_instanced_level)
			level_changed.emit(_instanced_level)
			
			if gamemode_kept:
				level_changed_same_gamemode.emit(_instanced_level)

## Emitted when a new level is loaded. Does not trigger when setting
## [member GameRoot.current_level] to [code]null[/code].
signal level_changed(p_new_level: LevelRoot)

## Emitting when a new level is loaded along with (and not instead of)
## [signal GameRoot.level_changed], but only if the same [GameMode] instance was
## kept between the two.
signal level_changed_same_gamemode(p_new_level: LevelRoot)

var _instanced_level: LevelRoot = null

## Returns the current instantiated [LevelRoot], or null if no level is loaded.
func get_level_root() -> LevelRoot:
	return _instanced_level

func _init():
	if Engine.is_editor_hint():
		return
	
	if not hud_root:
		hud_root = self

func _enter_tree():
	_instance = self

func _ready():
	if Engine.is_editor_hint():
		return
	
	if default_level:
		current_level = default_level

func _exit_tree():
	if _instance == self:
		_instance = null
