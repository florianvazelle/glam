extends "res://addons/gut/test.gd"

const Strings := preload("res://addons/glam/util/strings.gd")


func test_alphanumeric():
	assert_eq(Strings.alphanumeric("ABCDEFG_123"), "ABCDEFG_123")
	assert_eq(Strings.alphanumeric("abcdefg_123"), "abcdefg_123")
	assert_eq(
		Strings.alphanumeric("Bricks 075 (Dirty) - really.mp3"), "Bricks_075_Dirty_-_really_mp3"
	)
