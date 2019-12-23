std := load('../vendor/std')
json := load('../vendor/json')
f := std.format
log := std.log
readFile := std.readFile
writeFile := std.writeFile

http := load('../lib/http')

fs := load('fs')
sync := load('sync')
describe := fs.describe
flatten := fs.flatten
ensurePDE := fs.ensureParentDirExists

PORT := 7280

up := (remote, path) => readFile(path, file :: {
	() -> log('Failed to up: file read error for ' + path)
	_ -> req({
		method: 'POST',
		url: f('https://{{ remote }}/sync/{{ path }}', {
			remote: remote
			path: path
		})
		headers: {}
		body: file
	}, evt => evt.type :: {
		'error' -> log('Failed to up: request error ' + evt.message)
		'resp' -> evt.data.status :: {
			201 -> log('up success: ' + path)
			_ -> log('Failed to up: response code ' + string(evt.data.status))
		}
	})
})

down := (remote, path) => req({
	method: 'GET'
	url: f('https://{{ remote }}/sync/{{ path }}', {
		remote: remote
		path: path
	})
	headers: {}
	body: ''
}, evt => evt.type :: {
	'error' -> log('Failed to down: request error ' + evt.message)
	'resp' -> evt.data.status :: {
		200 -> (
			writeFile(path, evt.data.body, r => r :: {
				true -> log('down success: ' + path)
				_ -> log('Failed to down: write error ' + evt.message)
			})
		)
		_ -> log('Failed to down: response code ' + string(evt.data.status))
	}
})

server := (http.new)()

addRoute := server.addRoute
addRoute('/desc/*descPath', params => (_, end) => (
	descPath := params.descPath
	describe(descPath, desc => end({
		status: 200
		body: (json.ser)(desc)
	}))
))
addRoute('/sync/*downPath', params => (req, end) => req.method :: {
	'GET' -> (
		downPath := params.downPath
		readFile(downPath, file => file :: {
			() -> end({
				status: 404
				body: 'file not found'
			})
			_ -> end({
				status: 200
				headers: {
					'Content-Type': 'application/octet-stream'
				}
				body: file
			})
		})
	)
	'POST' -> (
		downPath := params.downPath
		ensurePDE(downPath, r => r :: {
			true -> writeFile(downPath, req.body, r => r :: {
				true -> end({
					status: 201
					body: ''
				})
				_ -> end({
					status: 500
					body: 'upload failed, could not write file'
				})
			})
			_ -> end({
				status: 500
				body: 'upload failed, could not create dir'
			})
		})
	)
	_ -> end({
		status: 400
		body: 'invalid request'
	})
})

(server.start)(PORT)
