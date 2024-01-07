class_name TestGamemode extends GameMode

func _started():
	print("i just started")

func _stopped():
	print("i just stopped")
	# doesn't print when quitting the game, but it does execute i swear lol
	# check with a breakpoint, seems like it doesn't have the time to flush it
	# to the console when quitting
