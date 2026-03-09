extends Resource
class_name SQLiteObject
## A Data Object representative of data to store in [SQLite] database.
##
## [SQLiteObject] is the core class for GDataORM.  It handles the grunt work
## of defining what table structure is and any special flags that are needed
## for SQLite.[br][br]
##
## [b]Example:[/b]
## [codeblock]
## extends SQLiteObject
## class_name Account
## 
## var id: int
## var username: String
## var password: String
## var address: Address
##
## static func _setup() -> void:
##     set_table_name(Account, "accounts")
##     set_column_flags(Account, "id", Flags.PRIMARY_KEY | Flags.AUTO_INCREMENT | Flags.NOT_NULL)
##     set_column_flags(Account, "username", Flags.NOT_NULL)
##     set_column_flags(Account, "password", Flags.NOT_NULL)
## [/codeblock]

class TableDefs:
	extends RefCounted
	var columns: Dictionary[String, Dictionary] = {}
	var types: Dictionary[String, Types.DataType] = {}
	var klass: GDScript
	var table_name: String

static var _tables: Dictionary[GDScript, TableDefs] = {}
static var _registry: Dictionary[String, GDScript] = {}
var _db: SQLite

## A debugging utility to see what classes have been registered with [SQLiteObject].
## This is printed out to the terminal/output window for easy review.
static func print_registered_classes() -> void:
	print("SQLiteObject Registered Classes:")
	for klass_name in _registry:
		print(klass_name)

## A debugging utility to see the structure of all the classes registered with [SQLiteObject].
## This is printed out to the terminal/output window for easy review.
static func print_data_structure() -> void:
	print("SQLite Object Data Structure:")
	print("-----------------------------")
	for klass in _tables:
		var table = _tables[klass]
		print("SQLiteObject>%s" % klass.get_global_name())
		print("Table Name: %s" % table.table_name)
		print("COLUMNS:")
		
		for column in table.columns:
			var keys: Array = table.columns[column].keys().filter(func(x): return x != "data_type")
			var columns := [table.columns[column].data_type]
			columns.append_array(keys)
			print("\t%s(DataType.%s) - SQLite: (%s)" % [
				column,
				Types.DataType.find_key(table.types[column]),
				", ".join(columns)
			])
		print("")
	pass

## This function is called once when setting up the class.  This is automatically done with classes
## that are registered as a [DbSet] by the [method Context.setup] static function call.
static func setup(klass: GDScript) -> void:
	_registry[klass.get_global_name()] = klass
	var table: TableDefs
	if _tables.has(klass):
		table = _tables[klass]
	else:
		table = TableDefs.new()
		table.klass = klass
		table.table_name = klass.get_global_name()
		_tables[klass] = table
	
	for prop in klass.get_script_property_list():
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		
		if prop.name.begins_with("_"):
			continue
		
		var def = {}
		if Types.BaseTypes.has(prop.type):
			def.data_type = Types.DEFINITION[Types.BaseTypes[prop.type]]
			table.types[prop.name] = Types.BaseTypes[prop.type]
		else:
			def.data_type = Types.DEFINITION[Types.DataType.GODOT_DATATYPE]
			table.types[prop.name] = Types.DataType.GODOT_DATATYPE
		
		table.columns[prop.name] = def
	
	klass._setup()

## This is a virtual function that is called when setup() is called.  This allows you to
## setup the data class information such as Column Flags, Table Name and Column Types.
static func _setup() -> void:
	push_warning("No setup has been defined for this class.  No special column flags or types will be used.")

## This function allows you to set SQLite specific flags for columns, when storing the data.
## This function should only be called in [method SQLiteObject._setup] which is part of the
## initialization of the data.[br][br]
## [b]Example:[/b]
## [codeblock]
## static func _setup() -> void:
##     # Ensure ID is an Auto-Increment Primary key in the database, that is not allowed to be null.
##     set_column_flag(MyDataClass, "id", Flags.PRIMARY_KEY | Flags.AUTO_INCREMENT | Flags.NOT_NULL)
##     # Ensure that name is not null in the database, and that it doesn't match any other row of data.
##     set_column_flag(MyDataClass, "name", Flags.NOT_NULL | Flags.UNIQUE)
## [/codeblock]
static func set_column_flags(klass: GDScript, column: String, flags: int, extra_params: Dictionary = {}) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting any column flags!")
	assert(_tables[klass].columns.has(column), "Column has not been defined!  Make sure to declare the variable first!")
	
	var data_type = _tables[klass].types[column]
	var col_def = _tables[klass].columns[column]
	
	if flags & Types.Flags.DEFAULT and not extra_params.has("default"):
		assert(false,"Attempting to set a default, without defining it in extra parameters!")
	if flags & Types.Flags.AUTO_INCREMENT and not [Types.DataType.INT, Types.DataType.REAL].has(data_type):
		assert(false, "Attempting to set Auto Increment flag on Non-Integer column!")
	if flags & Types.Flags.FOREIGN_KEY:
		if not extra_params.has("table"):
			assert(false, "Attempting to set Foreign Key flag without defining the Table it associates with!")
		if not extra_params.has("foreign_key"):
			assert(false, "Attempting to set Foreign Key flag without defining the Foreign Key!")
	
	
	if flags & Types.Flags.NOT_NULL: col_def.not_null = true
	if flags & Types.Flags.UNIQUE: col_def.unique = true
	if flags & Types.Flags.DEFAULT: col_def.default = extra_params.default
	if flags & Types.Flags.AUTO_INCREMENT: col_def.auto_increment = true
	if flags & Types.Flags.PRIMARY_KEY: col_def.primary_key = true
	if flags & Types.Flags.FOREIGN_KEY:
		col_def.foreign_key = "%s.%s" % [extra_params.table, extra_params.foreign_key]
	_tables[klass].columns[column] = col_def

## Sets the table name to use in the [SQLite] database for storing/fetching data
## from the database.
static func set_table_name(klass: GDScript, table_name: String) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting the table name!")
	_tables[klass].table_name = table_name if table_name != "" else klass.get_global_name()

## Sets the column type of [enum SQLiteObject.DataType] along with any extra parameters needed.[br][br]
## [b][color=red]NOTE:[/color][/b] Only use this function if you know what you are doing.  GDataORM
## attempts to match the SQLite data type, with the Godot data type as best as possible.
static func set_column_type(klass: GDScript, column: String, type: Types.DataType, extra_params: Dictionary = {}) -> void:
	assert(_tables.has(klass), "Setup must be called first, before setting any column types!")
	assert(_tables[klass].columns.has(column), "Column has not been defined!  Make sure to declare the variable first!")
	
	if type == Types.DataType.CHAR and not extra_params.has("size"):
		assert(false, "Attempting to set Column type to CHAR without a size parameter!")
	
	_tables[klass].types[column] = type
	_tables[klass].columns[column].data_type = Types.DEFINITION[type] if type != Types.DataType.CHAR else Types.DEFINITION[type] % extra_params.size

## Sets a variable that has been defined in the class, to be ignored, so as to not persist the data in the
## [SQLite] database.  The variable must be defined, in order for it to be ignored.[br][br]
## [b][color=red]NOTE:[/color][/b] By default, GDataORM ignore's any variables that start with [code]_[/code] character.
static func ignore_column(klass: GDScript, column: String) -> void:
	assert(_tables.has(klass), "Setup must be called first, before ignoring any column types!")
	assert(_tables[klass].columns.has(column), "Column has not been defined!  Make sure to declare the variable first!")
	
	_tables[klass].types.erase(column)
	_tables[klass].columns.erase(column)

## Adds a variable that is normally ignored in the class, to not be ignoerd, so that it can persist the data
## in the [SQLite] database.  The variable must be defined, in order for this function to succeed.
static func add_column(klass: GDScript, column: String) -> void:
	assert(_tables.has(klass), "Setup must be called first, before adding any column types!")
	var props = klass.get_property_list()
	var res = props.filter(func(x): return x.name == column)
	assert(res.size() > 0, "You cannot add a column, that does not have the variable defined for it!")
	
	var prop = res[0]
	var def = {}
	if Types.BaseTypes.has(prop.type):
		def.data_type = Types.DEFINITION[Types.BaseTypes[prop.type]]
		_tables[klass].types[prop.name] = Types.BaseTypes[prop.type]
	else:
		def.data_type = Types.DEFINITION[Types.DataType.GODOT_DATATYPE]
		_tables[klass].types[prop.name] = Types.DataType.GODOT_DATATYPE
	
	_tables[klass].columns[prop.name] = def

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
	if typeof(id) == TYPE_STRING:
		db.query_with_bindings("SELECT ? FROM ? WHERE ?='?'", [primary_key, table.table_name, primary_key, id])
	else:
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
		var prop = props.filter(func(x): return x.name == key)[0]
		if (table.types[key] == Types.DataType.ARRAY or
			table.types[key] == Types.DataType.DICTIONARY):
			if data[key] == null and table.types[key] == Types.DataType.ARRAY:
				obj.get(key).assign([])
			elif data[key] == null and table.types[key] == Types.DataType.DICTIONARY:
				obj.get(key).assign({})
			else:
				obj.get(key).assign(JSON.parse_string(data[key]))
		elif table.types[key] == Types.DataType.GODOT_DATATYPE:
			if _registry.has(prop.class_name):
				var klass := _registry[prop.class_name]
				var cond := Condition.new()
				var pk: String = _get_primary_key(klass)
				cond.equal(pk, bytes_to_var(data[key]))
				var nobj = _find_one(obj._db, klass, cond)
				obj.set(key, nobj)
			else:
				obj.set(key, bytes_to_var(data[key]))
		else:
			obj.set(key, data[key])

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

## Verify that the [SQLiteObject] exists in the database.
func exists() -> bool:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	assert(_db, "exists(): This instance was not fetched from the database, or has not been added to a DbSet!")
	var table := _tables[self.get_script()]
	var primary_key = _get_primary_key(self.get_script())
	assert(primary_key != "", "A Primary Key has not been defined for this class.")
	var res = _db.select_rows(table.table_name,
		Condition.new().equal(primary_key, self.get(primary_key)).to_string(),
		[primary_key])
	return not res.is_empty()

## Saves the [SQLiteObject] to the database file.[br][br]
## [b][color=red]NOTE:[/color][/b] Of special note, an object needs to be added to a [DbSet] first through
## [method DbSet.append] for this function to work.  [method DbSet.append] will save the object when
## it is first added.  This function is mostly for recording updates to the [SQLiteObject] data.
func save() -> void:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	assert(_db, "save(): This instance was not fetched from the database, or has not been added to a DbSet!")
	var table := _tables[self.get_script()]
	var primary_key = _get_primary_key(self.get_script())

	var sql_data = {}
	var data: Variant
	for key in table.columns.keys():
		data = get(key)
		if (table.types[key] == Types.DataType.ARRAY or
			table.types[key] == Types.DataType.DICTIONARY
		):
			sql_data[key] = JSON.stringify(data)
		elif table.types[key] == Types.DataType.GODOT_DATATYPE:
			if typeof(data) == TYPE_OBJECT:
				if _registry.has(data.get_script().get_global_name()):
					var pk := _get_primary_key(data.get_script())
					var pk_val = data.get(pk)
					sql_data[key] = var_to_bytes(pk_val)
				else:
					sql_data[key] = var_to_bytes(data)
			else:
				sql_data[key] = var_to_bytes(data)
		else:
			sql_data[key] = data

	if primary_key != "" and exists():
		_db.update_rows(table.table_name,Condition.new().equal(primary_key, get(primary_key)).to_string(), sql_data)
	else:
		if primary_key != "" and table.columns[primary_key].has(&"auto_increment"):
			sql_data.erase(primary_key)
		
		_db.insert_row(table.table_name, sql_data)
		
		if primary_key != "" and table.columns[primary_key].has(&"auto_increment"):
			var cond := Condition.new().equal("name","%s" % table.table_name)
			var res := _db.select_rows("sqlite_sequence", cond.to_string(), ["seq"])
			assert(not res.is_empty(), "Failed to insert record into %s." % [table.table_name])
			set(primary_key, res[0].seq)

## Removes the [SQLiteObject] from the database.  This will fail, if the object was not fetched
## from the database first.  You can also use [method DbSet.erase] to remove an object from the
## database.
func delete() -> void:
	assert(_tables.has(self.get_script()), "Setup must be called first, before setting any column types!")
	assert(_db, "delete(): This instance was not fetched from the database, or has not been added to a DbSet!")
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
