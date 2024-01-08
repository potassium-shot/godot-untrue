# Untrue
Untrue is a small [Godot](https://godotengine.org/) plugin that adds some game structure nodes, to swap levels, gamemodes, etc.

This repository contains a small demo project of the plugin. The plugin itself is contained in the `addons/` folder. To install it, copy the `addons/untrue` folder to the `addons/` folder of your own project.

# What it adds
Adds organizational classes like the GameRoot node, the LevelRoot node, or the GameMode resource, in order to facilitate making the base structure for a game. It is lightly inspired by Unreal, hence the name.

This plugin adds the GameRoot, which is the main node of the game, and can load levels with transitions;

The LevelRoot, which contains a GameMode;

The GameMode, which is extensible, and has references to optional scenes for the player character, camera and controller, as well as a hud for the ui. These can be changed at runtime, as well as the entire GameMode itself, which updates the instances of these scenes as well.

PlayerSpawn2D and PlayerSpawn3D nodes allow easy selection of spawn points.

