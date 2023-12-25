@tool
extends RefCounted


# Strip all non-alphanumeric characters, replacing ' ' and '.' with '_'.
static func alphanumeric(string: String) -> String:
	var result := ""

	var regex: RegEx
	if Engine.has_meta("_glam_alphanumeric_regex"):
		regex = Engine.get_meta("_glam_alphanumeric_regex")
	else:
		regex = RegEx.new()
		regex.compile("[\\w\\. -]")
		Engine.set_meta("_glam_alphanumeric_regex", regex)

	var matches = regex.search_all(string)
	for m in matches:
		result += m.get_string()
	result = result.replace(" ", "_")
	result = result.replace(".", "_")

	return result
