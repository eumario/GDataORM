@tool
extends EditorScript

func _run() -> void:
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
	print("Tables created, creating account and address")
	
	var account = Account.new()
	account.username = "eumario"
	account.password = "test123"
	context.accounts.append(account)
	
	var address = Address.new()
	address.first_name = "Mario"
	address.last_name = "Steele"
	context.addresses.append(address)
	account.address = address
	account.save()
	print("Account and Address saved to database.")
	
	print("Done")
