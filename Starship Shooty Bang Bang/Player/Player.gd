extends RigidBody2D

signal shoot
signal lives_changed
signal dead



export (int) var engine_power
export (int) var spin_power
export (PackedScene) var Bullet
export (float) var fire_rate


var thrust = Vector2()
var screensize = Vector2()
var rotation_dir = 0
var can_shoot = true
var lives = 0 setget set_lives


enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = null


func _ready():
	change_state(INIT)
	screensize = get_viewport().get_visible_rect().size
	$GunTimer.wait_time = fire_rate

#We turn the collisionshape on and off with each state
func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.disabled = true
			$Sprite.modulate.a = 0.5
			print("INIT")
		ALIVE:
			$CollisionShape2D.disabled  = false
			$Sprite.modulate.a = 1.0
			print("ALIVE")
		INVULNERABLE:
			$CollisionShape2D.disabled  = true
			$Sprite.modulate.a = 0.5
			$InvulnerabilityTimer.start()
			print("INVULNERABLE")
		DEAD:
			$CollisionShape2D.disabled = true
			$Sprite.hide()
			linear_velocity = Vector2()
			emit_signal("dead")
			print("DEAD")
	state = new_state


func _process(delta):
	get_input()


func get_input():
	#Handles movement for ship
	thrust = Vector2()
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thrust"):
		thrust = Vector2(engine_power, 0)
		rotation_dir = 0
	if Input.is_action_pressed("rotate_right"):
		rotation_dir +=1
	if Input.is_action_pressed("rotate_left"):
		rotation_dir -= 1

	#shooting bullets
	if Input.is_action_pressed("shoot"):
		shoot()
		
func _physics_process(delta):
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(spin_power * rotation_dir)


func _integrate_forces(physics_state):
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(spin_power * rotation_dir)
	var xform = physics_state.get_transform()
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	if xform.origin.x < 0:
		xform.origin.x = screensize.x
	if xform.origin.y > screensize.y:
		xform.origin.y = 0
	if xform.origin.y < 0:
		xform.origin.y = screensize.y
	physics_state.set_transform(xform)


func shoot():
	if state == INVULNERABLE:
		return
	emit_signal("shoot", Bullet, $Muzzle.global_position, rotation)
	can_shoot = false
	$GunTimer.start()

func _on_GunTimer_timeout():
	can_shoot = true
	
func set_lives(value):
	lives = value
	emit_signal('lives_changed', lives)
	
func start():
	$Sprite.show()
	self.lives = 3
	change_state(ALIVE)
	

func _on_InvulnerabilityTimer_timeout():
	change_state(ALIVE)


func _on_AnimationPlayer_animation_finished(name):
	$Explosion.hide()
	
func _on_Player_body_entered(body):
	if body.is_in_group('rocks'):
		body.explode()
		$Explosion.show()
		$Explosion/AnimationPlayer.play("Explosion")
		self.lives -= 1
		if lives <= 0:
			change_state(DEAD)
		else:
			change_state(INVULNERABLE)
