## A possible spawn point for the player. By default, the gamemode chooses one at
## random in the current level, but the behaviour can be overriden in
## [method GameMode._select_spawn_point_3d].
@tool @icon("res://addons/untrue/icons/PlayerSpawn3D.svg")
class_name PlayerSpawn3D extends Node3D

## If [code]false[/code], the spawn point won't be taken into account when calling
## [method PlayerSpawn3D.get_available].
@export var enabled: bool = true

## Returns an [Array] of all available enabled player spawns
static func get_available() -> Array:
	var world: Node = Game.get_world()
	assert(world, "Trying to get available player spawns but there is no level")
	return world.find_children("", "PlayerSpawn3D").filter(func(i): return i.enabled)
