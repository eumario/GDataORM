extends Migration

func _up() -> void:
	# Insert upgrade instructions to modify database structure below
	add_column("score", "level", Types.DataType.INT, Types.Flags.DEFAULT, {"default": 1})

func _down() -> void:
	# Insert downgrade instructions to modify database structure below.
	drop_column("score", "level")
