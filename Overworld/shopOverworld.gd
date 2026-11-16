extends Area2D
class_name Shop

@export var shopName := ""
@export var items: Array[Item] = []

@onready var shopScene = preload("res://UI/shopMenu.gd")

func interact():
	ShopMenu.newShop(self)
