extends "res://scripts/enemies/enemy_base.gd"

## The Computer Virus — first standard enemy.
## Patrols back and forth. Drops 1 Data Cookie on death.
## Inherits all patrol, hurt, and death logic from Enemy base.

func _ready() -> void:
	# Config specific to this enemy type
	patrol_speed      = 90.0
	patrol_distance   = 180.0
	cookie_drop_count = 1
	super._ready()

