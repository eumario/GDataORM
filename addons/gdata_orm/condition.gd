@tool
extends RefCounted
class_name Condition
## A programatically way to define Conditions.
##
## Condition is a way to define SQL Statements to be used with GDataORM.  You can create
## full SQL Statements, or Simple conditions to be used when fetching data from the [SQLite]
## database.[br][br]
##
## [b]Example:[/b]
## [codeblock]
## var fetch_like_mar: Condition = Condition.new().select("*").from("my_table").where() \
##     .like("name", "Mar%")
## var fetch_gold: Condition = Condition.new().select(["gold"]).from("inventories").where() \
##     .greater("gold",0)
## var low_health: Condition = Condition.new().lesser("health",5)
## var mid_health: Condition = Condition.new().between("health",25,75)
## var full_health: Condition = Condition.new().greater_equal("health",100)
## [/codeblock]

enum _CT {
	NOT,
	EQUAL,
	LESS_THAN,
	GREATER_THAN,
	LESS_THAN_EQUAL,
	GREATER_THAN_EQUAL,
	AND,
	BETWEEN,
	IN,
	LIKE,
	OR,
	SELECT,
	FROM,
	WHERE,
	END,
}

var _conditions: Array = []

func _single_op(op: _CT) -> Dictionary:
	return {"type": op}

func _param_op(op: _CT, param: Variant) -> Dictionary:
	return {"type": op, "param": param}

func _comparison_op(op: _CT, column: Variant, value: Variant) -> Dictionary:
	return {"type": op, "column": column, "value": value}

## Binary operator to invert true and false in a statement.
func is_not() -> Condition:
	_conditions.append(_single_op(_CT.NOT))
	return self

## Evaluates the equality of a [param column] value and the [param value] given.
func equal(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.EQUAL, column, value))
	return self

## Evaluates the [param column] value to be lesser than [param value] given.
func lesser(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.LESS_THAN, column, value))
	return self

## Evaluates the [param column] value to be greater than [param value] given.
func greater(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.GREATER_THAN, column, value))
	return self

## Evaluates the [param column] value to be lesser than or equal to [param value] given.
func lesser_equal(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.LESS_THAN_EQUAL, column, value))
	return self

## Evaluates the [param column] value to be greater than or equal to [param value] given.
func greater_equal(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.GREATER_THAN_EQUAL, column, value))
	return self

## Binary operator for AND'ing two evaluation values together.
func also() -> Condition:
	_conditions.append(_single_op(_CT.AND))
	return self

## Evaluates the [param column] value to be between [param lower]'s value and [param upper]'s value.
func between(column: String, lower: Variant, upper: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.BETWEEN, column, [lower, upper]))
	return self

## Evaluates the [param column] to see if [param value] is included in it.  You can pass an array
## of values to this, or use a [Condition] to fetch data from another table.
func includes(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.IN, column, value))
	return self

## Evaluates the [param column] to see if [param value] matches the given string.  This utilizes
## [SQLite]'s LIKE statement, which means that you can use wildcard operators '%' and '_' in the
## pattern string.[br][br]
## [b]Wildcard Patterns:[/b][br]
## - '%' match any 1 or more characters in a pattern, EG: "Mar%" will return "Mario", "Mark", "Margin" etc etc.[br]
## - '_' match only 1 wildcard character before moving to the next.  EG: "h_nt" will return "hunt", "hint", or
## "__pple" will return "topple", "supple", "tipple"[br]
## [b][color=red]NOTE:[/color][/b] [SQLite]'s engine is case-insensitive, so [code]"A" LIKE "a"[/code] will return true, but
## unicode characters that are not in the ASCII range, so [code]"Ä" LIKE "ä"[/code] will return false.
func like(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(_CT.LIKE, column, value))
	return self

## Binary operator for OR'ing two evaluations together.
func otherwise() -> Condition:
	_conditions.append(_single_op(_CT.OR))
	return self

func select(field: String) -> Condition:
	_conditions.append(_param_op(_CT.SELECT, field))
	return self

func from(table: String) -> Condition:
	_conditions.append(_param_op(_CT.FROM, table))
	return self

func where() -> Condition:
	_conditions.append(_single_op(_CT.WHERE))
	return self

func end() -> Condition:
	_conditions.append(_single_op(_CT.END))
	return self

func _to_string() -> String:
	var str = ""
	var pos := 0
	
	for cond in _conditions:
		match cond.type:
			#NOTE Single Operation _single_op()
			_CT.NOT:
				if _conditions[pos+1].type == _CT.BETWEEN:
					pos += 1
					continue
				str += "NOT "
			_CT.AND:
				str += "AND "
			_CT.OR:
				str += "OR "
			_CT.WHERE:
				str += "WHERE "
			
			#NOTE Param Operation _param_op()
			_CT.SELECT:
				var param = ""
				if cond.param is Array:
					param = ", ".join(cond.param)
				elif cond.param is String:
					param = cond.param
				else:
					assert(false, "SELECT statement only takes a String or Array parameters.")
				str += "SELECT %s " % param
			_CT.FROM:
				str += "FROM %s " % cond.param
			
			#NOTE Comparison Operation _comparison_op()
			_CT.EQUAL:
				str += "%s = %s " % [cond.column, cond.value]
			_CT.LESS_THAN:
				str += "%s < %s " % [cond.column, cond.value]
			_CT.GREATER_THAN:
				str += "%s > %s " % [cond.column, cond.value]
			_CT.LESS_THAN_EQUAL:
				str += "%s <= %s " % [cond.column, cond.value]
			_CT.GREATER_THAN_EQUAL:
				str += "%s >= %s " % [cond.column, cond.value]
			_CT.BETWEEN:
				if _conditions[pos-1].type == _CT.NOT:
					str += "%s NOT BETWEEN " % cond.column
				else:
					str += "%s BETWEEN " % cond.column
				str += "%s and %s" % cond.value
			_CT.IN:
				if _conditions[pos-1].type == _CT.NOT:
					str += "%s NOT IN " % cond.column
				else:
					str += "%s IN " % cond.column
				if cond.value is Condition:
					str += "(%s) " % cond.value.to_string()
				elif cond.value is Array:
					str += "(%s) " % ", ".join(cond.value)
				else:
					assert(false, "IN only takes Array of values or a Condition")
			_CT.LIKE:
				str += "%s LIKE %s " % [cond.column, cond.value]
		pos += 1
	
	return str.strip_edges()
