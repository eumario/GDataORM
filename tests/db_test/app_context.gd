@tool
extends Context
class_name AppContext

var accounts: DbSet
var addresses: DbSet

func _init() -> void:
	accounts = DbSet.new(Account)
	addresses = DbSet.new(Address)
