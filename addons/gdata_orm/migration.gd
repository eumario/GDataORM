@abstract
extends RefCounted
class_name Migration
## Base class for creating Schema Migrations in a Database.

var _db: SQLite
var _last_table: TableDef = null


func _init(db: SQLite) -> void:
	_db = db

func _log(msg: String) -> void:
	if ProjectSettings.get_setting(Types.DEBUG_MIGRATION):
		print("[Migration]: %s" % msg)

## Function to define alterations when upgrading to this migration.
@abstract func _up() -> void


## Function to define alterations when downgrading from this migration.
@abstract func _down() -> void


func _apply_last_table() -> void:
	if _last_table == null: return
	_log("Creating table %s" % [_last_table.name])
	_db.create_table(_last_table.name, _last_table.columns)
	_last_table = null


## This is called by the [Migrator] class, it handles migration of all available migrations.
func apply(direction: String) -> void:
	call("_%s" % direction)
	_apply_last_table()


class TableDef:
	extends RefCounted
	## A DSL class to allow chaining to define a table to be stored in the database.[br][br]
	##
	## [b]An Example:[/b][br]
	## [codeblock]
	## extends Migration
	##
	## def _up() -> void:
	##   (create_table("my_table")
	##     .add_column("id", Types.DataType.INT, Types.Flags.PRIMARY_KEY|Types.Flags.AUTOINCREMENT|Types.Flags.NOT_NULL)
	##     .add_column("name", Types.DataType.STRING, Types.Flags.NOT_NULL|Types.Flags.DEFAULT, {"default": "None"})
	##     .add_column("email", Types.DataType.STRING)
	##     .add_column("address", Types.DataType.STRING))
	## 
	## def _down() -> void:
	##   drop_table("my_table")
	## [/codeblock]
	##
	## [b]Another Example[/b][br]
	## [codeblock]
	## extends Migration
	##
	## def _up() -> void:
	##   var table = create_table("my_table")
	##   table.add_column("id", Types.DataType.INT, Types.Flags.PRIMARY_KEY|Types.Flags.AUTOINCREMENT|Types.Flags.NOT_NULL)
	##   table.add_column("name", Types.DataType.STRING, Types.Flags.NOT_NULL)
	##   table.add_column("score", Types.DataType.INT)
	## 
	## def _down() -> void:
	##   drop_table("my_table")
	## [/codeblock]
	var columns: Dictionary[String, Dictionary] = {}
	var name: String
	
	static func _create_column_def(type: Types.DataType, flags: int, extra_params: Dictionary) -> Dictionary:
		var column := {}
		if Types.BaseTypes.has(type):
			column.data_type = Types.DEFINITION[Types.BaseTypes[type]]
		else:
			column.data_type = Types.DEFINITION[Types.DataType.GODOT_DATATYPE]

		if flags & Types.Flags.DEFAULT and not extra_params.has("default"):
			assert(false,"Attempting to set a default, without defining it in extra parameters!")
		if flags & Types.Flags.AUTO_INCREMENT and not [Types.DataType.INT, Types.DataType.REAL].has(type):
			assert(false, "Attempting to set Auto Increment flag on Non-Integer column!")
		if flags & Types.Flags.FOREIGN_KEY:
			if not extra_params.has("table"):
				assert(false, "Attempting to set Foreign Key flag without defining the Table it associates with!")
			if not extra_params.has("foreign_key"):
				assert(false, "Attempting to set Foreign Key flag without defining the Foreign Key!")
		
		
		if flags & Types.Flags.NOT_NULL: column.not_null = true
		if flags & Types.Flags.UNIQUE: column.unique = true
		if flags & Types.Flags.DEFAULT: column.default = extra_params.default
		if flags & Types.Flags.AUTO_INCREMENT: column.auto_increment = true
		if flags & Types.Flags.PRIMARY_KEY: column.primary_key = true
		if flags & Types.Flags.FOREIGN_KEY:
			column.foreign_key = "%s.%s" % [extra_params.table,extra_params.foreign_key]
		
		return column
	
	func _init(_name: String) -> void:
		name = _name
	
	func add_column(name: String, type: Types.DataType, flags: int = Types.Flags.NONE, extra_params: Dictionary = {}):
		assert(not columns.has(name), "Column %s has already been defined!" % name)
		var def = _create_column_def(type, flags, extra_params)
		columns[name] = def
		return self


## Create a table with defined columns, See [Migration.TableDef] for more information.
func create_table(name: String) -> TableDef:
	_apply_last_table()
	var td := TableDef.new(name)
	_last_table = td
	return td


## Renames a table from the old name to the new name.
func rename_table(old_name: String, name: String) -> void:
	_apply_last_table()
	_log("Renaming table %s to %s" % [old_name, name])
	_db.query("ALTER TABLE '%s' RENAME TO '%s';" % [old_name, name])


## Drops a table from the database.
func drop_table(name) -> void:
	_apply_last_table()
	_log("Dropping table %s" % [name])
	_db.drop_table(name)


## Add's a column to an already existing table in the database.
func add_column(table_name: String, name: String, type: Types.DataType, flags: int = Types.Flags.NONE, extra_params: Dictionary = {}) -> void:
	_apply_last_table()
	_log("Adding Column %s to table %s" % [name, table_name])
	var def = TableDef._create_column_def(type, flags, extra_params)
	var sql_stmt := "ALTER TABLE '%s' ADD COLUMN '%s'" % [table_name, name]
	sql_stmt += " " + (Types.DEFINITION[type].to_upper() if Types.DEFINITION[type] != "int" else "INTEGER")
	if def.get(&"primary_key", false):
		sql_stmt += " PRIMARY KEY"
		if def.get(&"auto_increment",false):
			sql_stmt += " AUTOINCREMENT"
	if def.get(&"not_null", false):
		sql_stmt += " NOT NULL"
	if def.get(&"unique", false):
		sql_stmt += " UNIQUE"
	if def.has(&"default"):
		sql_stmt += " DEFAULT "
		if type == Types.DataType.DICTIONARY or type == Types.DataType.ARRAY:
			sql_stmt += "'%s'" % [JSON.stringify(def.default)]
		elif type == Types.DataType.GODOT_DATATYPE and def.default.get_class() is SQLiteObject:
			var pk := SQLiteObject._get_primary_key(def.default.get_class())
			sql_stmt += "'%s'" % [var_to_bytes(def.default.get(pk))]
		elif type == Types.DataType.GODOT_DATATYPE:
			sql_stmt += "'%s'" % [var_to_bytes(def.default)]
		else:
			sql_stmt += "%s" % [def.default]
	if def.has(&"foreign_key"):
		var key_elements = def.foreign_key.split(".")
		sql_stmt += ", FOREIGN KEY (%s) REFERENCES %s.(%s)" % [name, key_elements[0], key_elements[1]]
	
	sql_stmt += ";"
	_db.query(sql_stmt)


## Drop's a column from an already existing table in the database.
func drop_column(table_name: String, name: String) -> void:
	_apply_last_table()
	_log("Dropping column %s from table %s" % [name, table_name])
	_db.query("ALTER TABLE '%s' DROP COLUMN '%s'" % [table_name, name])


## Insert's a singular record into the table in the database.
func insert(table_name: String, data: Dictionary) -> bool:
	_apply_last_table()
	_log("Inserting data into %s:\n\t%s" % [table_name, JSON.stringify(data)])
	return _db.insert_row(table_name, data)

## Insert a number of records into the table in the database.
func insert_rows(table_name: String, data: Array) -> bool:
	_apply_last_table()
	_log("Inserting %d rows into %s" % [data.size(), table_name])
	return _db.insert_rows(table_name, data)

## Deletes data from the table in the database.
func delete_rows(table_name: String, cond: Condition) -> bool:
	_apply_last_table()
	_log("Deleting data from %s Where %s" % [table_name, cond])
	var res := _db.delete_rows(table_name, cond.to_string())
	_log("(%d) rows affected." % _db.get_reference_count())
	return res
