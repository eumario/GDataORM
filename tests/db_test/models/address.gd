extends SQLiteObject
class_name Address

@export var id: int
@export var first_name: String
@export var last_name: String
@export var city: String
@export var state: String
@export var zip_code: int

static func _setup() -> void:
	set_column_flags(Address, "id", Flags.PRIMARY_KEY | Flags.AUTO_INCREMENT | Flags.NOT_NULL)
	set_column_flags(Address, "first_name", Flags.NOT_NULL)
	set_column_flags(Address, "last_name", Flags.NOT_NULL)
