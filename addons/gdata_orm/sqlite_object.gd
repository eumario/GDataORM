## TODO: Setup Foreign Key (Internal or SQLite)
extends Resource
class_name SQLiteObject

enum DataType { BOOL, INT, REAL, STRING, DICTIONARY, ARRAY, GODOT_DATATYPE, CHAR, BLOB }

const GodotTypes = {
	TYPE_BOOL: DataType.BOOL,
	TYPE_INT: DataType.INT,
	TYPE_FLOAT: DataType.REAL,
	TYPE_STRING: DataType.STRING,
	TYPE_DICTIONARY: DataType.DICTIONARY,
	TYPE_ARRAY: DataType.ARRAY,
}

const DEFINITION = [
	"int",
	"int",
	"real",
	"text",
	"text",
	"text",
	"blob",
	"char(%d)",
	"blob"
]

enum Flags {
	NONE = 1 << 0,
	NOT_NULL = 1 << 1,
	UNIQUE = 1 << 2,
	DEFAULT = 1 << 3,
	PRIMARY_KEY = 1 << 4,
	AUTO_INCREMENT = 1 << 5,
	FOREIGN_KEY = 1 << 6,
}

class TableDefs:
	var columns: Dictionary[String, Dictionary] = {}
	var types: Dictionary[String, DataType] = {}
	var klass: GDScript
	var table_name: String

static var _tables: Dictionary[GDScript, TableDefs] = {}

var _db: SQLite

static func setup(table_name: String = "") -> void:
	var obj = new()
	var klass: GDScript = obj.get_script()
	
	var table: TableDefs
	if _tables.has(klass):
		table = _tables[klass]
	else:
		table = TableDefs.new()
		table.klass = klass
		table.table_name = table_name if table_name != "" else klass.get_global_name()
	
	for prop in obj.get_property_list():
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.name == "_db":
			continue
		var def = {}
		if GodotTypes.has(prop.type):
			def.data_type = DEFINITION[GodotTypes[prop.type]]
		else:
			def.data_type = DEFINITION[DataType.GODOT_DATATYPE]
		
		table.columns[prop.name] = def
		table.types[prop.name] = GodotTypes[prop.type] if GodotTypes.has(prop.type) else DataType.GODOT_DATATYPE
	
	_setup()

static func set_column_flags(klass: GDScript, column: String, flags: int, extra_params: Dictionary = {}) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting any column flags!")
	assert(_tables[klass].columns.has(column), "Column has not been defined!  Make sure to declare the variable first!")
	
	var data_type = _tables[klass].types[column]
	var col_def = _tables[klass].columns[column]
	
	if flags & Flags.DEFAULT and not extra_params.has("default"):
		assert(false,"Attempting to set a default, without defining it in extra parameters!")
	if flags && Flags.AUTO_INCREMENT and (data_type != DataType.INT or data_type != DataType.REAL):
		assert(false, "Attempting to set Auto Increment flag on Non-Integer column!")
	if flags && Flags.FOREIGN_KEY:
		if not extra_params.has("table"):
			assert(false, "Attempting to set Foreign Key flag without defining the Table it associates with!")
		if not extra_params.has("foreign_key"):
			assert(false, "Attempting to set Foreign Key flag without defining the Foreign Key!")
	
	
	if flags & Flags.NOT_NULL: col_def.not_null = true
	if flags & Flags.UNIQUE: col_def.unique = true
	if flags & Flags.DEFAULT: col_def.default = extra_params.default
	if flags & Flags.AUTO_INCREMENT: col_def.auto_increment = true
	if flags & Flags.PRIMARY_KEY: col_def.primary_key = true
	if flags & Flags.FOREIGN_KEY: col_def.foreign_key = extra_params.foreign_key
	_tables[klass].columns[column] = col_def

static func set_table_name(klass: GDScript, table_name: String) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting the table name!")
	_tables[klass].table_name = table_name if table_name != "" else klass.get_global_name()

static func set_column_type(klass: GDScript, column: String, type: DataType, extra_params: Dictionary = {}) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	assert(_tables[klass].columns.has(column), "Column has not been defined!  Make sure to declare the variable first!")
	
	if type == DataType.CHAR and not extra_params.has("size"):
		assert(false, "Attempting to set Column type to CHAR without a size parameter!")
		
	_tables[klass].types[column] = DEFINITION[type] if type != DataType.CHAR else DEFINITION[type] % extra_params.size

static func _create_table(db: SQLite, klass: GDScript, drop_if_exists = false) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	assert(not _tables[klass].columns.is_empty(), "No columns has been defined, either no variables are defined in the GDScript source, or setup was not called first!")
	if _table_exists(db, klass):
		if drop_if_exists:
			db.drop_table(_tables[klass].table_name)
		else:
			assert(false, "Table already exists!")
	db.create_table(_tables[klass].table_name, _tables[klass].columns)

static func _table_exists(db: SQLite, klass: GDScript) -> bool:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	var table := _tables[klass]
	db.query_with_bindings("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", [table.table_name])
	return not db.query_result.is_empty()

static func _has_id(db: SQLite, klass: GDScript, id: Variant) -> bool:
	var primary_key = _get_primary_key(klass)
	var table := _tables[klass]
	db.query_with_bindings("SELECT ? FROM ? WHERE ?=?;", [primary_key, table.table_name, primary_key, id])
	return not db.query_result.is_empty()

static func _get_primary_key(klass: GDScript) -> String:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	var table := _tables[klass]
	var primary_key: String = ""
	for column in table.columns:
		if table.columns[column].has("primary_key"):
			primary_key = column
			break
	
	assert(primary_key != "", "No primary key has been defined!")
	return primary_key

static func _populate_object(table: TableDefs, obj: SQLiteObject, data: Dictionary) -> void:
	var props = obj.get_property_list()
	for key in data:
		if not props.any(func(x): return x.name == key):
			continue
		if (table.types[key] == DataType.ARRAY or
			table.types[key] == DataType.DICTIONARY):
			obj.set(key, JSON.parse_string(data[key]))
		elif table.types[key] == DataType.GODOT_DATATYPE:
			obj.set(key, bytes_to_var(data[key]))
		else:
			obj.set(key, data[key])

static func _setup() -> void:
	push_warning("No setup has been defined for this class.  No special column flags or types will be used.")

static func _find_one(db: SQLite, klass: GDScript, conditions: Condition) -> SQLiteObject:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	var table := _tables[klass]
	var res := db.select_rows(table.table_name, conditions.to_string(), table.columns.keys())
	
	if res.is_empty():
		return null
	else:
		var obj = klass.new()
		obj._db = db
		_populate_object(table, obj, res[0])
		return obj

static func _find_many(db: SQLite, klass: GDScript, conditions: Condition) -> Array:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	var table := _tables[klass]
	var objs: Array = []
	var res = db.select_rows(table.table_name, conditions.to_string(), table.columns.keys())
	
	for data in res:
		var obj = klass.new()
		obj._db = db
		_populate_object(table, obj, data)
		objs.append(obj)
	return objs

static func _all(db: SQLite, klass: GDScript) -> Array:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	var table := _tables[klass]
	var objs: Array = []
	var res = db.select_rows(table.table_name, "", table.columns.keys())
	
	for data in res:
		var obj = klass.new()
		obj._db = db
		_populate_object(table, obj, data)
		objs.append(obj)
	return objs

func exists() -> bool:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	var table := _tables[self.get_script()]
	var primary_key = _get_primary_key(self.get_script())
	assert(primary_key != "", "A Primary Key has not been defined for this class.")
	var res = _db.select_rows(table.table_name,
		Condition.new().equal(primary_key, self.get(primary_key)).to_string(),
		[primary_key])
	return not res.is_empty()

func save_database() -> void:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	var table := _tables[self.get_script()]
	var primary_key = _get_primary_key(self.get_script())

	var data = {}
	for key in table.columns.keys():
		if (table.types[key] == DataType.ARRAY or
			table.types[key] == DataType.DICTIONARY
		):
			data[key] = JSON.stringify(get(key))
		elif table.types[key] == DataType.GODOT_DATATYPE:
			data[key] = var_to_bytes(get(key))
		else:
			data[key] = get(key)

	if primary_key != "" and exists():
		_db.update_rows(table.table_name,Condition.new().equal(primary_key, get(primary_key)).to_string(), data)
	else:
		if primary_key != "" and table.columns[primary_key].auto_increment:
			data.erase(primary_key)
		_db.insert_row(table.table_name, data)

func delete() -> void:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	var table := _tables[self.get_script()]
	var primary_key = _get_primary_key(self.get_script())
	
	assert(primary_key != "", "In order to delete data from the database, it must have a primary key!")
	
	if not exists():
		push_warning("Attempting to delete a record that doesn't exist!")
		return
	
	_db.delete_rows(table.table_name, Condition.new().equal(primary_key, get(primary_key)).to_string())

func _to_string() -> String:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	var table := _tables[self.get_script()]
	var primary_key = _get_primary_key(self.get_script())
	var kname = self.get_script().get_global_name()
	if primary_key != "":
		return "<%s:%s:%s>" % [kname, table.table_name, get(primary_key)]
	else:
		return "<%s:%s:G-%s>" % [kname, table.table_name, get_instance_id()]
