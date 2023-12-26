# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
@tool
extends HTTPRequest

const Request = preload("./request.gd")
const RequestCache = preload("./request_cache.gd")

signal cacheable_request_completed(result, response_code, headers, body)

var _request_cache: RequestCache


func _ready():
	use_threads = true
	_request_cache = get_tree().get_meta("glam").request_cache
	assert(_request_cache)


func request(
	url: String,
	custom_headers: PoolStringArray = PoolStringArray(),
	ssl_validate_domain := true,
	method = HTTPClient.METHOD_GET,
	request_data := ""
):
	var request = Request.new(url, custom_headers, method, request_data)
	var response = _request_cache.get_response(request)
	if response:
		call_deferred(
			"emit_signal",
			"cacheable_request_completed",
			response.result,
			response.response_code,
			response.headers,
			response.body
		)
		return OK
	else:
		request_completed.connect(self._on_request_completed.bind(request), CONNECT_ONE_SHOT)
		return super.request(url, custom_headers, ssl_validate_domain, method, request_data)


func _on_request_completed(result, response_code, headers, body, request: Request):
	_request_cache.store(request, result, response_code, headers, body)
	yield(get_tree(), "idle_frame")
	emit_signal("cacheable_request_completed", result, response_code, headers, body)
