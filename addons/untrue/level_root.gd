## Root of any level. Can be switched from the [GameRoot], and has a [GameMode] that
## can be modified in the editor as well as in runtime. Can be extended to hold
## level specific code.
@tool @icon("res://addons/untrue/icons/LevelRoot.svg")
class_name LevelRoot extends Node

## [GameMode] to use by default for this level, can be changed at runtime.
@export var game_mode: GameMode = null:
	set(value):
		var old = null if _gamemode_transferred else game_mode
		
		if value:
			game_mode = (
				value.duplicate()
				if not (Engine.is_editor_hint() or value.resource_path.is_empty())
				else value
			)
		else:
			game_mode = null
		
		if not Engine.is_editor_hint() and is_inside_tree():
			_update_gamemode(old, game_mode)

## If [code]true[/code], when switching to this level from another level, the
## [GameMode] from that level will be kept instead.
## [br]
## This is the default behaviour if no [GameMode] is specified for this level.
## [br]
## This essentially means the [GameMode] from this level will only be used if
## this is the first level to be loaded.
@export var gamemode_replaceable: bool = false

## Node to use as a root for this level; if not specified, defaults to this LevelRoot.
## Useful when you need your level to have a transform, or to enable
## [member CanvasItem.y_sort_enabled] with a [Node2D].
@export var root_node: Node = null

## Emitted when a new [GameMode] is started. This does not include when a [GameMode]
## is kept between two [LevelRoot]s, to check this use [signal GameRoot.level_changed].
signal gamemode_started(p_gamemode: GameMode)

## Emitted when a [GameMode] is stopped. This happens when it is replaced, when
## a level with its own [GameMode] is loaded, or when the game quits.
signal gamemode_stopped(p_gamemode: GameMode)

var _gamemode_transferred: bool = false
var _gamemode_replaced: bool = false

func _init():
	if not root_node:
		root_node = self

func _ready():
	if not Engine.is_editor_hint():
		_update_gamemode(null, game_mode)

func _exit_tree():
	if not Engine.is_editor_hint():
		_update_gamemode(game_mode, null)

func _update_gamemode(p_old_gamemode: GameMode, p_new_gamemode: GameMode):
	if p_old_gamemode and not _gamemode_replaced:
		p_old_gamemode.notification(GameMode.NOTIFICATION_STOPPED)
		gamemode_stopped.emit(p_old_gamemode)
	
	if p_new_gamemode:
		if not p_new_gamemode.is_started():
			p_new_gamemode.notification(GameMode.NOTIFICATION_STARTED)
			gamemode_started.emit(p_new_gamemode)
		else:
			p_new_gamemode.notification(GameMode.NOTIFICATION_LEVEL_CHANGED)

func _transfer_gamemode(p_new_level: LevelRoot):
	var ret = game_mode
	
	_gamemode_transferred = true
	game_mode = null
	_gamemode_transferred = false
	
	p_new_level._gamemode_replaced = true
	p_new_level.game_mode = ret
	p_new_level._gamemode_replaced = false
	
	ret._transfer_scenes(p_new_level)
