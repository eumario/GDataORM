extends RefCounted
class_name Context

@export var file_path: String

var _db: SQLite

func setup() -> void:
	var props = get_property_list()
	for prop in props:
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.type != TYPE_OBJECT or prop.class_name != "DbSet":
			continue
		var dbset: DbSet = get(prop.name)
		dbset.klass.setup(dbset.klass)

func open_db(db_path: String = "") -> void:
	var props = get_property_list()
	if db_path != "":
		file_path = db_path
	_db = SQLite.new()
	_db.path = file_path
	_db.open_db()
	for prop in props:
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.type != TYPE_OBJECT or prop.class_name != "DbSet":
			continue
		var dbset: DbSet = get(prop.name)
		dbset.set_db(_db)

func close_db() -> void:
	_db.close_db()

func ensure_tables() -> void:
	var props = get_property_list()
	for prop in props:
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.type != TYPE_OBJECT or prop.class_name != "DbSet":
			continue
		var dbset: DbSet = get(prop.name)
		if not dbset.table_exists():
			dbset.create_table(false)

func force_create_tables() -> void:
	var props = get_property_list()
	for prop in props:
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.type != TYPE_OBJECT or prop.class_name != "DbSet":
			continue
		var dbset: DbSet = get(prop.name)
		dbset.create_table(true)
