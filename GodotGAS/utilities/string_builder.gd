## A simple string builder utility class.
##
## @meta_addon: GodotGAS 1.0.5
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

extends RefCounted

const GodotGasProjectSettings: = preload("uid://c7w4dgy6upgcd")
const StringBuilder: = preload("uid://d1bffm2o6kir")

const DEFAULT_NEW_LINE: = "\n"

## When `true`, empty lines will not be indented.
var trim_whitespace: = true
var new_line: = DEFAULT_NEW_LINE
var current_indent: = ""
var appended_indent: = "\t" 
var string_length: = 0:
	set = set_string_length, get = get_string_length
var num_strings_appended: = 0:
	set = set_num_strings_appended, get = get_num_strings_appended

var override_appended_indent: = false
var override_trim_whitespace: = false
var override_new_line: = false

var _raw_strings_length: = 0
var _num_raw_strings_appended: = 0
var _data: = []
var _builders: Array[StringBuilder] = []


func set_string_length(_value: int) -> void:
	pass


func get_string_length() -> int:
	var processed_string_length: = _raw_strings_length + (current_indent.length() * num_strings_appended)
	# Counting the new line strings.
	processed_string_length += new_line.length() * (_data.size() - 1)
	for builder in _builders:
		processed_string_length += builder.string_length
	return processed_string_length


func set_num_strings_appended(_value: int) -> void:
	pass


func get_num_strings_appended() -> int:
	return _num_raw_strings_appended + _builders.reduce(
		func(accumulator: int, builder: StringBuilder) -> int:
			return accumulator + builder.num_strings_appended,
		0,
	)



## Appends a simple `String` as a line to the `StringBuilder`.
func append_line(string: String) -> StringBuilder:
	_data.push_back(string)
	_raw_strings_length += string.length()
	_num_raw_strings_appended += 1
	
	return self


## Appends a `StringBuilder` to the current `StringBuilder`. It can make indent text really easy.
func append_builder(string_builder: StringBuilder) -> StringBuilder:
	assert(string_builder != null)

	_data.push_back(string_builder)
	_builders.push_back(string_builder)

	return self


## Like `append_builder`, but appends instead a new `StringBuilder` and returns it.
func append_builder_b() -> StringBuilder:
	var new_builder: = StringBuilder.new() 
	append_builder(new_builder)

	return new_builder


func append_indent(builder: StringBuilder, indent_count: = 1, options: Dictionary[String, Variant] = {}) -> StringBuilder:
	_append_indent(builder, indent_count, options)
	return self

## Appends a new `StringBuilder` with the indent specified, returns it afterwards.
## `options` is a dictionary with the following keys:
##  - `"builder_indent"` (`String`): The indent to apply to the returned builder.
##                                   Defaults to the value of the `appended_indent` property.
##  - `"trim_whitespace"` (`bool`):  Will trim whitespace if set to `true`.
##                                   Defaults to the value of the `trim_whitespace` property.
func append_indent_b(indent_count: = 1, options: Dictionary[String, Variant] = {}) -> StringBuilder:
	var new_builder: = StringBuilder.new()
	_append_indent(new_builder, indent_count, options)
	return new_builder


func _append_indent(
		builder: StringBuilder,
		indent_count: int,
		options: Dictionary[String, Variant],
) -> void:
	var builder_indent: = options.get("builder_indent", appended_indent)
	builder.current_indent = builder_indent.repeat(indent_count)
	append_builder(builder)



func append_empty_line(count: int = 1) -> StringBuilder:
	assert(count >= 0)

	match count:
		0:
			pass
		1:
			append_line("")
		_:
			for _i in range(count):
				append_line("")
	
	return self


## Returns a `StringBuilder` instance as string. 
## `options` is a dictionary with the following keys:
##  - `"ensure_final_newline"` (`bool`):  Ensures that a final newline is present.
##                                        Defaults to `false`.
func as_string(options: = {}) -> String:	
	if string_length == 0:
		return ""	

	var ensure_final_newline: = options.get("ensure_final_newline", false)
	var render: = _render_as_string("") 

	if ensure_final_newline and not render.ends_with("\n"):
		render += "\n"

	return render


func _render_as_string(
		super_indent: = "",
		target_appended_indent: = appended_indent,
		target_trim_whitespace: = trim_whitespace,
		target_new_line: = new_line,
) -> String:
	var current_new_line: = new_line \
		if override_new_line \
		else target_new_line
	return current_new_line.join(
		_data.map(
			func(value: Variant) -> String:	
				return _data_to_string(
					value,
					super_indent,
					target_appended_indent,
					target_trim_whitespace,
					current_new_line,
				),
		)
	)
	


func _data_to_string(
		value: Variant,
		super_indent: String,
		target_appended_indent: String,
		target_trim_whitespace: bool,
		current_new_line: String,
) -> String:
	var string_trim_whitespace: = trim_whitespace \
		if override_trim_whitespace \
		else target_trim_whitespace
	if value is StringBuilder:
		return value._render_as_string(
			super_indent + current_indent,
			appended_indent if override_appended_indent else target_appended_indent,
			string_trim_whitespace,
			current_new_line,
		)
	elif typeof(value) == TYPE_STRING:
		var value_as_string: String = value
		if string_trim_whitespace and value_as_string.is_empty():
			return ""
		return super_indent + current_indent + value_as_string
	return ""
