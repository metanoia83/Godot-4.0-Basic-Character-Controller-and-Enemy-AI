extends Node3D

# QUEUE FREE THE ENEMY WHEN DEAD
func dead():
	get_parent().queue_free()


# DISABLE ENEMY COLLISION SHAPE WHEN DEAD
func disable_collision():
	get_parent().get_node("CollisionShape3D").disabled = true

# ENEMY HITS THE PLAYER - PLAYER DEAD
func _on_attack_body_entered(body):
	
	if body.is_in_group("Player") and !body.dead:
		body.dead = true
		body.jumping = false
		body.get_node("DeathTimer").start()
		get_tree().get_root().set_disable_input(true)
		
		#RESETS ENEMY TO IDLE STATE
		get_parent().patrolling = false
		get_parent().chasing = false
		get_parent().target = null
		get_parent().get_node("Timer").start()
