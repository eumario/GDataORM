@tool
extends SQLiteObject
class_name Account

@export var id: int
@export var username: String
@export var password: String
@export var address: Address

static func _setup() -> void:
	set_table_name(Account, "accounts")
	set_column_flags(Account, "id", Types.Flags.PRIMARY_KEY | Types.Flags.AUTO_INCREMENT | Types.Flags.NOT_NULL)
	set_column_flags(Account, "username", Types.Flags.NOT_NULL)
	set_column_flags(Account, "password", Types.Flags.NOT_NULL)
