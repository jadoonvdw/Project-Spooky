extends Node3D
@onready var animplayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	animplayer.play("flicker")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
