extends Migration

func _up() -> void:
	# Insert upgrade instructions to modify database structure below
	var table := create_table("score")
	table.add_column("id", Types.DataType.INT, Types.Flags.PRIMARY_KEY | Types.Flags.AUTO_INCREMENT | Types.Flags.NOT_NULL)
	table.add_column("score", Types.DataType.INT, Types.Flags.DEFAULT, {"default": 0})

func _down() -> void:
	# Insert downgrade instructions to modify database structure below.
	drop_table("score")
