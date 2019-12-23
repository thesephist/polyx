` noct client `

std := load('std')
f := std.format
log := std.log
readFile := std.readFile
writeFile := std.writeFile

cli := load('../lib/cli')

fs := load('fs')
sync := load('sync')
describe := fs.describe
flatten := fs.flatten
diff := sync.diff

desc := (remote, path, cb) => req({
	method: 'GET'
	url: f('https://{{ remote }}/desc/{{ path }}', {
		remote: remote
		path: path
	})
}, evt => evt.type :: {
	'error' -> (
		log('Failed to desc: request error ' + evt.message)
		cb(())
	)
	'resp' -> evt.data.status :: {
		200 -> cb(evt.data.body)
		_ -> (
			log('Failed to desc: response code ' + string(evt.data.status))
			cb(())
		)
	}
})

up := (remote, path) => readFile(path, file :: {
	() -> log('Failed to up: file read error for ' + path)
	_ -> req({
		method: 'POST'
		url: f('https://{{ remote }}/sync/{{ path }}', {
			remote: remote
			path: path
		})
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

` commands `
plan := opts => args => (
	` TODO: print sync plan `
)
sync := opts => args => (
	` TODO: perform sync `
)
