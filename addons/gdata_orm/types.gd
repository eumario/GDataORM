extends Object
class_name Types

## The supported types of [SQLiteObject]
enum DataType {
	## A [bool] Value
	BOOL, 
	## An [int] Value
	INT, 
	## A [float] Value
	REAL, 
	## A Variable Length [String] Value
	STRING, 
	## A [Dictionary] Value
	DICTIONARY, 
	## An [Array] Value
	ARRAY,
	## A value of a built-in Godot DataType, or Object of a Custom Class.
	GODOT_DATATYPE, 
	## A Fixed-size [String] value, like [PackedStringArray]
	CHAR, 
	## A Binary value, like [PackedByteArray]
	BLOB 
}

const BaseTypes = {
	TYPE_BOOL: DataType.BOOL,
	TYPE_INT: DataType.INT,
	TYPE_FLOAT: DataType.REAL,
	TYPE_STRING: DataType.STRING,
	TYPE_DICTIONARY: DataType.DICTIONARY,
	TYPE_ARRAY: DataType.ARRAY,
}

const DEFINITION: Array[String] = [
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

## SQLite flags used for column definitions.
enum Flags {
	## No Flags Associated with this Column
	NONE = 1 << 0,
	## Column must not be Null.
	NOT_NULL = 1 << 1,
	## Column must be Unique
	UNIQUE = 1 << 2,
	## Column has a Default value.
	DEFAULT = 1 << 3,
	## Column is defined as a Primary Key for this table.
	PRIMARY_KEY = 1 << 4,
	## Column is defined as auto-incrementing.
	AUTO_INCREMENT = 1 << 5,
	## Column is a Foreign Key (See [SQLite] about Foreign Keys)
	FOREIGN_KEY = 1 << 6,
}
