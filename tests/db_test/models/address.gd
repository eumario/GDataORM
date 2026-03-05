@tool
extends SQLiteObject
class_name Address

@export var id: int
@export var first_name: String
@export var last_name: String
@export var city: String
@export var state: String
@export var zip_code: int

static func _setup() -> void:
	set_table_name(Address, "addresses")
	set_column_flags(Address, "id", Types.Flags.PRIMARY_KEY | Types.Flags.AUTO_INCREMENT | Types.Flags.NOT_NULL)
	set_column_flags(Address, "first_name", Types.Flags.NOT_NULL)
	set_column_flags(Address, "last_name", Types.Flags.NOT_NULL)
