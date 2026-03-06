extends Migration

func _up() -> void:
	var table: Migration.TableDef

	# Create Table accounts
	table = create_table("accounts")
	table.add_column("id", Types.DataType.INT, Types.Flags.PRIMARY_KEY | Types.Flags.NOT_NULL, {})
	table.add_column("username", Types.DataType.STRING, Types.Flags.NOT_NULL, {})
	table.add_column("password", Types.DataType.STRING, Types.Flags.NOT_NULL, {})
	table.add_column("address", Types.DataType.GODOT_DATATYPE, Types.Flags.NONE, {})

	# Create Table addresses
	table = create_table("addresses")
	table.add_column("id", Types.DataType.INT, Types.Flags.PRIMARY_KEY | Types.Flags.NOT_NULL, {})
	table.add_column("first_name", Types.DataType.STRING, Types.Flags.NOT_NULL, {})
	table.add_column("last_name", Types.DataType.STRING, Types.Flags.NOT_NULL, {})
	table.add_column("city", Types.DataType.STRING, Types.Flags.NONE, {})
	table.add_column("state", Types.DataType.STRING, Types.Flags.NONE, {})
	table.add_column("zip_code", Types.DataType.INT, Types.Flags.NONE, {})


func _down() -> void:

	# Drop Table accounts
	drop_table("accounts")

	# Drop Table addresses
	drop_table("addresses")

