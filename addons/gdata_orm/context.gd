extends RefCounted
class_name Context
## The Central core for interacting with Databases.
##
## Context is the class which creates a Database Connection to a [SQLite] database,
## and sets up all tables as defined by the DbSet definitions of the class.[br][br]
##
## [b]Example:[/b]
## [codeblock]
## extends Context
## class_name AppContext
##
## var characters: DbSet
## var inventories: DbSet
## var items: DbSet
##
## func _init() -> void:
##     characters = DbSet.new(Character)
##     inventories = DbSet.new(Inventory)
##     items = DbSet.new(Item)
##
## [/codeblock]

## The path in which to find the database, Example: `my_context.file_path = "user://my_database.db"`
@export var file_path: String

var _db: SQLite

## Called to initialize the Context.  This should be called just after the creation of the context, in order to
## register all [DbSet]'s with the Context, as well, as call [method SQLiteObject.setup] on all SQLiteObject's
## that have been defined as a DbSet of this class.
func setup() -> void:
	var props = get_property_list()
	for prop in props:
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.type != TYPE_OBJECT or prop.class_name != "DbSet":
			continue
		
		var dbset: DbSet = get(prop.name)
		dbset._klass.setup(dbset._klass)

## Opens the [SQLite] database, allowing for the usages of the [DbSet]s defined in this context.
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

## Closes the database when finished interacting with this instance.
func close_db() -> void:
	_db.close_db()


## Ensures that all tables defined as [DbSet] in this context, are properly created in the database.
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

## Forces the creation of all tables defined as [DbSet] in this context, are properly created, dropping
## the table if it already exists.
func force_create_tables() -> void:
	var props = get_property_list()
	for prop in props:
		if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if prop.type != TYPE_OBJECT or prop.class_name != "DbSet":
			continue
		var dbset: DbSet = get(prop.name)
		dbset.create_table(true)
