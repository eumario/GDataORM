@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	print("Statements:")
	print(Condition.new().select("*").from("my_table").where() \
		.greater("id",100).also().lesser("id",150).to_string() + ";")
	
	print(Condition.new().select("*").from("my_table").where() \
		.between("id", 100,150).to_string() + ";")
	
	print(Condition.new().select("*").from("my_table").where() \
		.is_not().between("id", 10,50).to_string() + ";")
	
	print(Condition.new().greater("id", 300).also().lesser("health",-1))
	
	print(Condition.new().includes("id", Condition.new().select("id").from("banned").where() \
		.equal("banned", true)))
	
	print("End\n\n")
