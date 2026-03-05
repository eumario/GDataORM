@tool
extends EditorPlugin

var migrations_submenu: PopupMenu
var mi_create_initial: int = 1000
var mi_create_migration: int = 1001

const USE_NUMBER_SETTING: String = "application/GData_ORM/migration/use_number"
const FOLDER_SETTING: String = "application/GData_ORM/migration/folder"
const INITIAL_MIGRATION_TEMPLATE: String = r"extends Migration

func _up() -> void:
	var table: Migration.TableDef
%s

func _down() -> void:
%s
"
const MIGRATION_TEMPLATE: String = r"extends Migration

func _up() -> void:
	# Insert upgrade instructions to modify database structure below
	pass

func _down() -> void:
	# Insert downgrade instructions to modify database structure below.
	pass
"

func _enter_tree() -> void:
	_init_settings()
	migrations_submenu = PopupMenu.new()
	migrations_submenu.add_item("Create Initial Migration", mi_create_initial)
	migrations_submenu.add_item("Create new Migration", mi_create_migration)
	add_tool_submenu_item("Migrations", migrations_submenu)
	migrations_submenu.id_pressed.connect(_handle_migrations)


func _exit_tree() -> void:
	remove_tool_menu_item("Migrations")
	migrations_submenu.queue_free()

func _handle_migrations(id: int) -> void:
	match id:
		mi_create_initial:
			if _create_initial_migration():
				EditorInterface.get_resource_filesystem().scan()
		mi_create_migration:
			_prompt_migration_name()

func _init_settings() -> void:
	if not ProjectSettings.has_setting(USE_NUMBER_SETTING):
		ProjectSettings.set_setting(USE_NUMBER_SETTING, true)
		ProjectSettings.add_property_info({
			"name": USE_NUMBER_SETTING,
			"type": TYPE_BOOL,
		})
	
	if not ProjectSettings.has_setting(FOLDER_SETTING):
		ProjectSettings.set_setting(FOLDER_SETTING, "res://migrations")
		ProjectSettings.add_property_info({
			"name": FOLDER_SETTING,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
		})

func _create_initial_migration() -> bool:
	# Prepare our Definitions, so we can create the migration.
	SQLiteObject._tables = {}
	SQLiteObject._registry = {}
	for klass_def in ProjectSettings.get_global_class_list():
		if klass_def.base == &"SQLiteObject":
			var klass = load(klass_def.path)
			klass.setup(klass)
	
	var up: String = ""
	var down: String = ""
	
	for table in SQLiteObject._tables:
		up += "\n\t# Create Table %s\n" % SQLiteObject._tables[table].table_name
		up += "\ttable = create_table(\"%s\")\n" % SQLiteObject._tables[table].table_name
		down += "\n\t# Drop Table %s\n" % SQLiteObject._tables[table].table_name
		down += "\tdrop_table(\"%s\")\n" % SQLiteObject._tables[table].table_name
		for column in SQLiteObject._tables[table].columns:
			var flags: Array[String] = []
			var type: Types.DataType = SQLiteObject._tables[table].types[column]
			var extra: Dictionary = {}
			var def := SQLiteObject._tables[table].columns[column]
			if def.has(&"primary_key"): flags.append("Types.Flags.PRIMARY_KEY")
			if def.has(&"unique"): flags.append("Types.Flags.UNIQUE")
			if def.has(&"not_null"): flags.append("Types.Flags.NOT_NULL")
			if def.has(&"default"): 
				flags.append("Types.Flags.DEFAULT")
				extra["default"] = def.default
			if def.has(&"foreign_key"):
				flags.append("Types.Flags.FOREIGN_KEY")
				extra["foreign_key"] = def.foreign_key
			up += "\ttable.add_column(\"%s\", %s, %s, %s)\n" % [
				column,
				"Types.DataType.%s" % Types.DataType.find_key(type),
				" | ".join(flags) if flags.size() > 0 else "Types.Flags.NONE",
				JSON.stringify(extra)
			]
	
	if up == "":
		push_error("Unable to find any SQLiteObject's defined")
		return false
	
	var fname: String
	if ProjectSettings.get_setting(USE_NUMBER_SETTING):
		fname = "001_initial.gd"
	else:
		var dt = Time.get_datetime_dict_from_system()
		fname = "%04d%02d%02d_%02d_%02d_initial.gd" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
	
	_write_template(fname, INITIAL_MIGRATION_TEMPLATE, up, down)
	return true

func _prompt_migration_name() -> void:
	var dlg := Window.new()
	var vb := VBoxContainer.new()
	var lbl := Label.new()
	var le := LineEdit.new()
	var hb := HBoxContainer.new()
	var ok := Button.new()
	var cancel := Button.new()
	lbl.text = "Please enter a name to identify this migration:"
	ok.text = "Ok"
	cancel.text = "Cancel"
	hb.alignment = BoxContainer.ALIGNMENT_END
	if OS.get_name() == "Windows":
		hb.add_child(ok)
		hb.add_child(cancel)
	else:
		hb.add_child(cancel)
		hb.add_child(ok)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(lbl)
	vb.add_child(le)
	vb.add_child(hb)
	dlg.add_child(vb)
	dlg.title = "New Migration Name"
	dlg.size = Vector2i(320,100)
	dlg.unresizable = true
	dlg.close_requested.connect(dlg.queue_free)
	ok.pressed.connect(func():
		_create_migration(le.text)
		dlg.queue_free()
	)
	cancel.pressed.connect(dlg.queue_free)
	EditorInterface.popup_dialog_centered(dlg)

func _create_migration(name: String) -> void:
	var fname: String
	if ProjectSettings.get_setting(USE_NUMBER_SETTING):
		var files := Array(DirAccess.get_files_at(ProjectSettings.get_setting(FOLDER_SETTING)))
		files = files.filter(func(x: String): return x.ends_with(".gd"))
		var i := files.size() + 1
		fname = "%03d_%s.gd" % [i, name.to_snake_case()]
	else:
		var dt := Time.get_datetime_dict_from_system()
		fname = "%04d%02d%02d_%02d_%02d_%s.gd" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, name.to_snake_case()]
	
	if _write_template(fname, MIGRATION_TEMPLATE):
		EditorInterface.get_resource_filesystem().scan()

func _write_template(fname: String, tmpl: String, up: String = "", down: String = "") -> bool:
	var path: String = ProjectSettings.get_setting(FOLDER_SETTING).path_join(fname)
	if not DirAccess.dir_exists_absolute(ProjectSettings.get_setting(FOLDER_SETTING)):
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.get_setting(FOLDER_SETTING)) != OK:
			push_error("Unable to create folder: %s" % [ProjectSettings.get_setting(FOLDER_SETTING)])
			return false
	
	var fh := FileAccess.open(path, FileAccess.WRITE)
	if not fh:
		push_error("Failed to create migration at '%s'" % [path])
		push_error("Reason: %s" % FileAccess.get_open_error())
		return false
	if up == "" and down == "":
		fh.store_string(tmpl)
	else:
		fh.store_string(tmpl % [up, down])
	fh.close()
	return true
