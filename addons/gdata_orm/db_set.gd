@tool
extends Resource
class_name DbSet

var klass: GDScript
var _db: SQLite

func _init(h_klass: GDScript) -> void:
	klass = h_klass

func set_db(db_conn: SQLite) -> void:
	_db = db_conn

func create_table(drop_if_exists: bool) -> void:
	SQLiteObject._create_table(_db, klass, drop_if_exists)

func table_exists() -> bool:
	return SQLiteObject._table_exists(_db, klass)

func has_id(id: Variant) -> bool:
	return SQLiteObject._has_id(_db, klass, id)

func find_one(conditions: Condition) -> SQLiteObject:
	return SQLiteObject._find_one(_db, klass, conditions)

func find_many(conditions: Condition) -> Array:
	return SQLiteObject._find_many(_db, klass, conditions)

func all() -> Array:
	return SQLiteObject._all(_db, klass)
