## Root of the game, can switch levels, and can hold the root of the hud. Can be
## extended to hold game-level code. Get its single instance with
## [code]Game.get_root()[/code].
@tool @icon("res://addons/untrue/icons/GameRoot.svg")
class_name GameRoot extends Node

static var _instance: GameRoot

## The level to instantiate automatically at the start of the level, if set.
@export_file("*.tscn", "*.scn") var default_level_path: String = ""

## Node into which instantiate the hud of a [GameMode]. If not set, defaults to this [GameRoot].
## Useful for putting the UI into a separate [CanvasLayer].
@export var hud_root: Node = null

@export var transition_animation_player: AnimationPlayer = null

var _current_level_path_internal: String

## The [PackedScene] corresponding to the currently loaded level; switching it
## switches the current level. Can be null.
var current_level_path: String = "":
	get:
		return _current_level_path_internal
	set(value):
		transition_to_level(value)

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
	
	if default_level_path:
		current_level_path = default_level_path

func _exit_tree():
	if _instance == self:
		_instance = null

func _set_instanced_level(p_new_level: LevelRoot, p_gamemode_kept: bool):
	if p_gamemode_kept:
		_instanced_level._transfer_gamemode(p_new_level)
	
	if _instanced_level:
		_instanced_level.queue_free()
	
	if p_new_level:
		_instanced_level = p_new_level
		add_child(_instanced_level)
		level_changed.emit(_instanced_level)
		
		if p_gamemode_kept:
			level_changed_same_gamemode.emit(_instanced_level)

func transition_to_level(p_level: String, p_transition: StringName = ""):
	_current_level_path_internal = p_level
		
	if Engine.is_editor_hint():
		return
	
	var new_level: LevelRoot = null
	var gamemode_kept: bool = false
		
	var start_anim_name: StringName
	var end_anim_name: StringName
	var has_end: bool
	
	if p_transition:
		assert(
			transition_animation_player,
			"Trying to player transition animation but transition_animation_player is not assigned",
		)
		
		if transition_animation_player.has_animation(p_transition):
			start_anim_name = p_transition
			has_end = false
		else:
			start_anim_name = p_transition + "_start"
			end_anim_name = p_transition + "_end"
			
			assert(
				transition_animation_player.has_animation(start_anim_name),
				"No start animation found for transition %s" % p_transition,
			)
			
			assert(
				transition_animation_player.has_animation(end_anim_name),
				"No end animation found for transition %s" % p_transition,
			)
			
			has_end = true
		
		transition_animation_player.play(start_anim_name)
		await transition_animation_player.animation_finished
	
	# load the level
	
	if p_level:
		new_level = (load(p_level) as PackedScene).instantiate() as LevelRoot
		
		assert(
			new_level or not p_level,
			"PackedScene assigned to current_level in GameRoot should be valid LevelRoot",
		)
		
		if (new_level.gamemode_replaceable and _instanced_level) or not new_level.game_mode:
			assert(_instanced_level, "Tried to start a level without a gamemode")
			gamemode_kept = true
		
	_set_instanced_level(new_level, gamemode_kept)
	
	if p_transition:
		if has_end:
			transition_animation_player.play(end_anim_name)
		else:
			transition_animation_player.play_backwards(start_anim_name)
