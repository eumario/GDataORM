@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var cond: Condition
	var context := AppContext.new()
	print("Setting up Context...")
	context.setup()
	
	SQLiteObject.print_registered_classes()
	print("")
	
	SQLiteObject.print_data_structure()
	print("Connecting to database...")
	
	context.open_db("res://tests/db_test/test_database.db")
	print("Ensuring tables are created...")
	
	context.ensure_tables()
	print("Tables created, fetching user by username field...")
	
	cond = Condition.new().equal("username","eumario")
	var account: Account = context.accounts.find_one(cond)
	print("Account: ", account)
	
	print("User's Address info: ", account.address)
	print("User's Name: %s %s" % [account.address.first_name, account.address.last_name])
	
	print("Fetching user by id field...")
	cond = Condition.new().equal("id", 1)
	account = context.accounts.find_one(cond)
	print("Account: ", account)
	
	print("Fetching by invalid id...")
	cond = Condition.new().equal("id", 100)
	account = context.accounts.find_one(cond)
	print("Account: ", account)
	
	print("Fetching by LIKE '%ari%'...")
	cond = Condition.new().like("username", "%ari%")
	print("Condition: ", cond)
	account = context.accounts.find_one(cond)
	print("Account: ", account)
