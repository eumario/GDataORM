@tool
extends Resource
class_name TestClass

enum Classes {
	Warrior,
	Rogue,
	Wizard,
	Cleric,
	Paladin
}

@export var id: int
@export var name: String
@export var klass: Classes
@export var inventory: Array
@export var stats: Dictionary[String, int]
@export var position: Vector2
@export var basic_attack: Skill
@export var magic_attack: Skill
