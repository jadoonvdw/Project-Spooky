#CREDIT FOR THIS SCRIPT TO Dragon20C ON YOUTUBE THEY'RE GOATED FOR THIS
extends Node3D

@export var footstep_sounds : Array[AudioStreamMP3]
@export var ground_pos : Marker3D
@onready var player : CharacterBody3D = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	player.step.connect(play_sound)

func play_sound():
	var audio_player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	var random_index : int  = randi_range(0,footstep_sounds.size() - 1)
	audio_player.stream = footstep_sounds[random_index]
	audio_player.max_db = -7
	audio_player.pitch_scale = randf_range(0.8,1.1)
	ground_pos.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(func destroy(): audio_player.queue_free())

