extends Node3D

var mouse_sensitivity = 0.5

@onready var player = get_tree().get_nodes_in_group("Player")[0]

func _process(delta):
	# CAMERA FOLLOWING CHARACTER
	global_position = player.global_position + Vector3(0,4,0)

func _input(event):
	
	# HANDLES CAMERA ROTATION ALONG X & Y AXIS
	if event is InputEventMouseMotion:
		var rotx = rotation.x - event.relative.y/1000 * mouse_sensitivity
		rotation.y -= event.relative.x/1000 * mouse_sensitivity
		rotx = clamp(rotx, -1, 1)
		rotation.x = rotx
		
		
	# HANDLES CAMERA ZOOM IN & ZOOM OUT USING MOUSE WHEEL
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var tween = create_tween()
			tween.tween_property($SpringArm3D, "spring_length", max($SpringArm3D.get_length() - 0.5, 4), 0.1)

			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var tween = create_tween()
			tween.tween_property($SpringArm3D, "spring_length", min($SpringArm3D.get_length() + 0.5, 15), 0.1)
			
			

