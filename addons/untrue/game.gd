@tool @icon("res://addons/untrue/icons/Game.svg")
class_name Game extends Object

## Returns the [GameRoot]
static func get_game_root() -> GameRoot:
	return GameRoot._instance

## Returns the current [LevelRoot], or null if there is none loaded.
static func get_level() -> LevelRoot:
	var game_root: GameRoot = get_game_root()
	
	if game_root:
		return game_root.get_level_root()
	else:
		return null

## Returns the currently active [GameMode], or null if no level is loaded.
static func get_gamemode() -> GameMode:
	var level_root: LevelRoot = get_level()
	
	if level_root:
		return level_root.game_mode
	else:
		return null

## Returns the current world, that is the world root node of the current level,
## or null if no level is loaded.
static func get_world() -> Node:
	var level_root: LevelRoot = get_level()
	
	if level_root:
		return level_root.root_node
	else:
		return null
