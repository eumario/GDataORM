@tool
extends Resource
class_name DbSet

var _klass: GDScript
var _db: SQLite

func _init(h_klass: GDScript) -> void:
	_klass = h_klass

func set_db(db_conn: SQLite) -> void:
	_db = db_conn

func create_table(drop_if_exists: bool) -> void:
	SQLiteObject._create_table(_db, _klass, drop_if_exists)

func table_exists() -> bool:
	return SQLiteObject._table_exists(_db, _klass)

func has_id(id: Variant) -> bool:
	return SQLiteObject._has_id(_db, _klass, id)

func find_one(conditions: Condition) -> SQLiteObject:
	return SQLiteObject._find_one(_db, _klass, conditions)

func find_many(conditions: Condition) -> Array:
	return SQLiteObject._find_many(_db, _klass, conditions)

func all() -> Array:
	return SQLiteObject._all(_db, _klass)

func append(obj: SQLiteObject) -> void:
	assert(obj.get_script() == _klass, "Attempting to add an SQLiteObject of %s to table of type %s!" % 
		[obj.get_script().get_global_name(), _klass.get_global_name()]
	)
	obj._db = _db
	obj.save()

func erase(obj: SQLiteObject) -> void:
	assert(obj.get_script() == _klass, "Attempting to remove an SQLiteObject of %s to table of type %s!" % 
		[obj.get_script().get_global_name(), _klass.get_global_name()]
	)
	obj._db = _db
	obj.delete()
