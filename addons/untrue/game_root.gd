## Root of the game, can switch levels, and can hold the root of the hud. Can be
## extended to hold game-level code. Get its single instance with
## [code]Game.get_root()[/code].
@tool @icon("res://addons/untrue/icons/GameRoot.svg")
class_name GameRoot extends Node

static var _instance: GameRoot

## The level to instantiate automatically at the start of the level, if set.
@export_file("*.tscn", "*.scn") var default_level_path: String = ""

## Transition for the default level, if set.
@export var default_level_transition: StringName = &""

## Node into which instantiate the level. If not set, defaults to the [GameRoot].
@export var level_parent_node: Node = null

## Node into which instantiate the hud of a [GameMode]. If not set, defaults to this [GameRoot].
## Useful for putting the UI into a separate [CanvasLayer].
@export var hud_root: Node = null

## Optionnal animation player to play transition animations when switching level.
## See [method GameRoot.transition_to_level].
@export var transition_animation_player: AnimationPlayer = null

## Optionnal loading screen. Will be instanced in the [member GameRoot.hud_root]
## if the loading of a level takes more than [member GameRoot.loading_screen_show_timeout]
## seconds.
@export var loading_screen: PackedScene = null

## If loading a level takes more than this amount of time, the loading screen is
## instanced, provided it is set.
@export_range(0.0, 1.0, 0.1, "suffix:sec.", "or_greater", "hide_slider")
var loading_screen_show_timeout: float = 2.0

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

## Emitted when a new level is loaded along with (and not instead of)
## [signal GameRoot.level_changed], but only if the same [GameMode] instance was
## kept between the two.
signal level_changed_same_gamemode(p_new_level: LevelRoot)

## Emitted every frame when loading a scene, reports the current level of progress.
signal loading_level_progress_changed(p_progress: float)

var _instanced_level: LevelRoot = null

var _instanced_loading_screen: Control = null

## Returns the current instantiated [LevelRoot], or null if no level is loaded.
func get_level_root() -> LevelRoot:
	return _instanced_level

func _init():
	if Engine.is_editor_hint():
		return
	
	if not level_parent_node:
		level_parent_node = self
	
	if not hud_root:
		hud_root = self

func _enter_tree():
	_instance = self

func _ready():
	if Engine.is_editor_hint():
		return
	
	if default_level_path:
		transition_to_level(default_level_path, default_level_transition)

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
		level_parent_node.add_child(_instanced_level)
		level_changed.emit(_instanced_level)
		
		if p_gamemode_kept:
			level_changed_same_gamemode.emit(_instanced_level)

## Transitions from the current level to another, specified by a load path.
## If no transition is specified, the loading is instant. Otherwise, it will
## try to find an animation with the name of [param p_transition] in the
## [member GameRoot.transition_animation_player], and will play it before loading
## the new level, and play it back in reverse after.
## [br]
## If an animation of that name is not found, it will try to find 2 animations
## with the name [code]p_transition + "_start"[/code] and
## [code]p_transition + "_end"[/code], which are respectively played before and
## after loading the level.
func transition_to_level(p_level: String, p_transition: StringName = &""):
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
		
		if _instanced_level:
			transition_animation_player.play(start_anim_name)
			await transition_animation_player.animation_finished
	
	# load the level
	
	if p_level:
		new_level = (await _load_level_async(p_level)).instantiate() as LevelRoot
		
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

func _load_level_async(p_path: String) -> PackedScene:
	ResourceLoader.load_threaded_request(p_path, "PackedScene")
	
	var loading_timer = get_tree().create_timer(loading_screen_show_timeout)
	loading_timer.timeout.connect(_show_loading_screen)
	
	while true:
		var progress: Array = []
		
		match ResourceLoader.load_threaded_get_status(p_path, progress):
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				loading_level_progress_changed.emit(progress)
			ResourceLoader.THREAD_LOAD_LOADED:
				if loading_timer:
					loading_timer.timeout.disconnect(_show_loading_screen)
				
				_hide_loading_screen()
				return ResourceLoader.load_threaded_get(p_path) as PackedScene
			_:
				assert(false, "Level loading failed")
				break
		
		await get_tree().process_frame
	
	if loading_timer:
		loading_timer.timeout.disconnect(_show_loading_screen)
	
	_hide_loading_screen()
	return null

func _show_loading_screen():
	if loading_screen:
		_instanced_loading_screen = loading_screen.instantiate()
		hud_root.add_child(_instanced_loading_screen)

func _hide_loading_screen():
	if _instanced_loading_screen:
		_instanced_loading_screen.queue_free()
