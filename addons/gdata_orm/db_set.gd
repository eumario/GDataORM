@tool
extends Resource
class_name DbSet

var klass: GDScript
var db: SQLite

func _init(h_klass: GDScript) -> void:
	klass = h_klass

func set_db(db_conn: SQLite) -> void:
	db = db_conn

func create_table(drop_if_exists: bool) -> void:
	klass._create_table(db, klass, drop_if_exists)

func table_exists() -> bool:
	return klass._table_exists(db, klass)

func has_id(id: Variant) -> bool:
	return klass._has_id(db, klass, id)
