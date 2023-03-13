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
		for i in get_tree().get_nodes_in_group("Enemy"):
			if i.chasing == true:
				i.patrolling = false
				i.chasing = false
				i.target = null
				i.get_node("Timer").start()
