extends Node3D
@onready var animplayer = $AnimationPlayer
@onready var rng = RandomNumberGenerator.new()
@onready var timerTime = 0.3
# Called when the node enters the scene tree for the first time.

func _ready():
	animplayer.play("flicker")
	$lightFlickerTimer.start(timerTime)
	$lightFlickerTimer.timeout.connect(_on_timer_timeout)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_timer_timeout(): 
	#print("Timer Stop") #For testing the timer
	$lightBuzz.play()
	animplayer.play("flicker")
	rng.randomize
	timerTime = rng.randf_range(0.3, 1.5) #Change these values to change rate of car lights flickering
	$lightFlickerTimer.start(timerTime)
	

	
