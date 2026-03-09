extends RefCounted
class_name Migrator

var _db: SQLite

func _init(path: String, db: SQLite = null) -> void:
	if db == null:
		_db = SQLite.new()
		_db.path = path
		if not _db.open_db():
			push_error("Migration Error: Attempted to open database, but failed to open!")
			_db = null
			return
	else:
		_db = db

func _log(msg: String) -> void:
	if ProjectSettings.get_setting(Types.DEBUG_MIGRATION):
		print("[Migrator]: %s" % msg)

func _table_exists(name: String) -> bool:
	_db.query_with_bindings("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", [name])
	return not _db.query_result.is_empty()

func _get_last_version() -> Dictionary:
	_db.query("SELECT * FROM migrations;")
	return _db.query_result[0]

func _update_last_version(num: int, last_file: String) -> void:
	_log("Updating version to %d..." % num)
	var last_version := _get_last_version()
	var res := _db.update_rows("migrations", "numeric_version=%s" % last_version.numeric_version, {"numeric_version": num, "last_file": last_file})
	assert(res, "Failed to update Migrations stamp.")

func _ensure_migrations_table() -> void:
	if not _table_exists("migrations"):
		_log("No migrations table found, creating migration table schema...")
		_db.create_table("migrations", {
			"numeric_version": {
				"data_type": "int",
			},
			"last_file": {
				"data_type": "text",
				"not_null": true,
			}
		})
		_db.insert_row("migrations", {"numeric_version": 0, "last_file": "none"})

func apply_migrations(to_level: int = -1, to_date: String = "") -> void:
	_log("Migration ensuring Migrations table exists...")
	_ensure_migrations_table()
	var last := _get_last_version()
	_log("Last Migration: Version: %d Migration File: %s" % [last.numeric_version, last.last_file])
	var files = Array(DirAccess.get_files_at(ProjectSettings.get_setting(Types.FOLDER_SETTING)))
	var migration_scripts: Array[String] = []
	migration_scripts.assign(files.filter(func(x: String): return x.ends_with(".gd")))
	_log("Found %d migration(s) available." % [migration_scripts.size()])
	if last.last_file != "none":
		assert(migration_scripts[last.numeric_version-1] == last.last_file, "Migration error, last migration script, does not match!")
	
	_log("Determining Migration direction...")
	if to_level == -1 and to_date == "":
		to_level = migration_scripts.size()
	elif to_level == -1 and to_date != "":
		to_level = migration_scripts.find_custom(func(x: String): return x.begins_with(to_date))
		assert(to_level != -1, "Migration error, date time stamp doesn't exist!")
		to_level += 1
	
	if to_level == last.numeric_version:
		_log("Migrations are current, no migrations ran.")
		return
	
	if to_level > last.numeric_version and to_level <= migration_scripts.size():
		_log("Running Migration up to version: %d" % to_level)
		# We are Upgrading
		for i in range(last.numeric_version, to_level):
			_run_script(migration_scripts[i], "up")
			_update_last_version(i+1, migration_scripts[i])
	elif to_level < last.numeric_version and to_level < 0:
		assert(false, "Migration error, cannot downgrade to a version before the first migration!")
	else:
		_log("Running Migration down to version: %d" % to_level)
		for i in range(last.numeric_version, to_level, -1):
			_run_script(migration_scripts[i-1], "down")
			if i-2 < 0:
				_update_last_version(0, "none")
			else:
				_update_last_version(i-1, migration_scripts[i-2])
	
	_log("Migration completed.  Now at version %d" % [to_level])

func _run_script(script: String, direction: String) -> void:
	var file_path: String = ProjectSettings.get_setting(Types.FOLDER_SETTING).path_join(script)
	_log("Running migration %s on file '%s'" % [direction, file_path])
	var ms: GDScript = load(file_path)
	var mig: Migration = ms.new(_db)
	mig.apply(direction)
	mig = null
