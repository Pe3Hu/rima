class_name WeaponData
extends RefCounted

## Оружие: имя и текущая Mold. Логики ковки здесь нет.

signal mold_changed

var name: String = ""
var mold: MoldData


func init_with_mold(name_: String, mold_: MoldData) -> void:
	name = name_
	mold = mold_


func apply_mold(mold_: MoldData) -> void:
	mold = mold_
	mold_changed.emit()
