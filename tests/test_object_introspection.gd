@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var obj = TestClass.new()
	for prop in obj.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var type := get_type(prop.type, prop.hint, prop.class_name)
			var prop_info := {
				"name": prop.name,
				"type": type,
			}
			print("Name: {name} - Type: {type}".format(prop_info))

func get_type(type: Variant.Type, hint: PropertyHint, klass: String) -> String:
	var type_string: String = ""
	match type:
		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				type_string = "Enumeration"
			else:
				type_string = "Integer"
		TYPE_FLOAT:
			type_string = "Float"
		TYPE_BOOL:
			type_string = "Boolean"
		TYPE_STRING:
			type_string = "String"
		TYPE_ARRAY:
			type_string = "Array"
		TYPE_DICTIONARY:
			type_string = "Dictionary"
		TYPE_OBJECT:
			type_string = klass
		_:
			type_string = "Godot Type"
	return type_string
