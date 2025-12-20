@tool
extends Resource
class_name DbSet
## A Central point for fetching/storing [SQLiteObject]s in a Database.
##
## DbSet is used to create a link between [SQLiteObject]s and the tables they are stored in.  Functions for
## inserting, fetching, and removing [SQLiteObject]s in a database, along with support functions for checking
## if a table exists, and creating tables.[br][br]
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

var _klass: GDScript
var _db: SQLite

## Create an instance of DbSet, specifying the [SQLiteObject] inherited class that represents
## the table that this set should interact with.
func _init(h_klass: GDScript) -> void:
	_klass = h_klass

## Set the [SQLite] database handle for this [DbSet].  This is handled internally by [method Context.setup],
## but you can also set a custom database handle for this DbSet.
func set_db(db_conn: SQLite) -> void:
	_db = db_conn

## Creates the backing table for the [SQLiteObject] inherited backing class for the object.
func create_table(drop_if_exists: bool) -> void:
	SQLiteObject._create_table(_db, _klass, drop_if_exists)

## Check to see if the table exists or not.
func table_exists() -> bool:
	return SQLiteObject._table_exists(_db, _klass)

## Check's the [SQLite] database to see if the ID exists in the database.  Require's [method SQLiteObject.set_column_flags]
## being called assigning a column as a Primary Key.
func has_id(id: Variant) -> bool:
	return SQLiteObject._has_id(_db, _klass, id)

## Searches the [SQLite] database for an object that matches the [Condition] as given.  Returns the
## [SQLiteObject] instance if found, otherwise returns null if it found nothing.
func find_one(conditions: Condition) -> SQLiteObject:
	return SQLiteObject._find_one(_db, _klass, conditions)

## Searches the [SQLite] database for any matching object that matches the [Condition] given. Returns
## an Array of [SQLiteObject]s that was found, otherwise returns an Empty array if nothing is found.
func find_many(conditions: Condition) -> Array:
	return SQLiteObject._find_many(_db, _klass, conditions)

## Returns all saved [SQLiteObject]s stored in the [SQLite] database.
func all() -> Array:
	return SQLiteObject._all(_db, _klass)

## Stores a [SQLiteObject] in the [SQLite] database.  Until this is called, an [SQLiteObject] is not
## saved in the database, and [method SQLiteObject.save] will not work.  Using this method will
## automatically save the data to the Database when executed.[br][br]
## [b][color=red]NOTE:[/color][/b] [SQLiteObject]s defined with an Auto-Increment Primary key, will
## set their primary key variable once this method is run automatically for you.  If the primary
## key is not set after calling this method, then it was not saved to the database.
func append(obj: SQLiteObject) -> void:
	assert(obj.get_script() == _klass, "Attempting to add an SQLiteObject of %s to table of type %s!" % 
		[obj.get_script().get_global_name(), _klass.get_global_name()]
	)
	obj._db = _db
	obj.save()

## Removes a [SQLiteObject] from the [SQLite] database.  This function calls [method SQLiteObject.delete]
## function to remove it from the database.  You can use either method to remove the object from the database.
func erase(obj: SQLiteObject) -> void:
	assert(obj.get_script() == _klass, "Attempting to remove an SQLiteObject of %s to table of type %s!" % 
		[obj.get_script().get_global_name(), _klass.get_global_name()]
	)
	obj._db = _db
	obj.delete()
