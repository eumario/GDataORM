@tool
extends RefCounted
class_name Condition

enum CT {
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

func _single_op(op: CT) -> Dictionary:
	return {"type": op}

func _param_op(op: CT, param: Variant) -> Dictionary:
	return {"type": op, "param": param}

func _comparison_op(op: CT, column: Variant, value: Variant) -> Dictionary:
	return {"type": op, "column": column, "value": value}

func is_not() -> Condition:
	_conditions.append(_single_op(CT.NOT))
	return self

func equal(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.EQUAL, column, value))
	return self

func lesser(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.LESS_THAN, column, value))
	return self

func greater(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.GREATER_THAN, column, value))
	return self

func lesser_equal(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.LESS_THAN_EQUAL, column, value))
	return self

func greater_equal(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.GREATER_THAN_EQUAL, column, value))
	return self

func also() -> Condition:
	_conditions.append(_single_op(CT.AND))
	return self

func between(column: String, lower: Variant, upper: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.BETWEEN, column, [lower, upper]))
	return self

func includes(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.IN, column, value))
	return self

func like(column: String, value: Variant) -> Condition:
	_conditions.append(_comparison_op(CT.LIKE, column, value))
	return self

func otherwise() -> Condition:
	_conditions.append(_single_op(CT.OR))
	return self

func select(field: String) -> Condition:
	_conditions.append(_param_op(CT.SELECT, field))
	return self

func from(table: String) -> Condition:
	_conditions.append(_param_op(CT.FROM, table))
	return self

func where() -> Condition:
	_conditions.append(_single_op(CT.WHERE))
	return self

func end() -> Condition:
	_conditions.append(_single_op(CT.END))
	return self

func _to_string() -> String:
	var str = ""
	var pos := 0
	
	for cond in _conditions:
		match cond.type:
			#NOTE Single Operation _single_op()
			CT.NOT:
				if _conditions[pos+1].type == CT.BETWEEN:
					pos += 1
					continue
				str += "NOT "
			CT.AND:
				str += "AND "
			CT.OR:
				str += "OR "
			CT.WHERE:
				str += "WHERE "
			
			#NOTE Param Operation _param_op()
			CT.SELECT:
				var param = ""
				if cond.param is Array:
					param = ", ".join(cond.param)
				elif cond.param is String:
					param = cond.param
				else:
					assert(false, "SELECT statement only takes a String or Array parameters.")
				str += "SELECT %s " % param
			CT.FROM:
				str += "FROM %s " % cond.param
			
			#NOTE Comparison Operation _comparison_op()
			CT.EQUAL:
				str += "%s = %s " % [cond.column, cond.value]
			CT.LESS_THAN:
				str += "%s < %s " % [cond.column, cond.value]
			CT.GREATER_THAN:
				str += "%s > %s " % [cond.column, cond.value]
			CT.LESS_THAN_EQUAL:
				str += "%s <= %s " % [cond.column, cond.value]
			CT.GREATER_THAN_EQUAL:
				str += "%s >= %s " % [cond.column, cond.value]
			CT.BETWEEN:
				if _conditions[pos-1].type == CT.NOT:
					str += "%s NOT BETWEEN " % cond.column
				else:
					str += "%s BETWEEN " % cond.column
				str += "%s and %s" % cond.value
			CT.IN:
				if _conditions[pos-1].type == CT.NOT:
					str += "%s NOT IN " % cond.column
				else:
					str += "%s IN " % cond.column
				if cond.value is Condition:
					str += "(%s) " % cond.value.to_string()
				elif cond.value is Array:
					str += "(%s) " % ", ".join(cond.value)
				else:
					assert(false, "IN only takes Array of values or a Condition")
			CT.LIKE:
				str += "%s LIKE %s " % [cond.column, cond.value]
		pos += 1
	
	return str.strip_edges()
