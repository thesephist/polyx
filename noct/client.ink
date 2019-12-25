#!/usr/bin/env ink

` noct client `

std := load('../vendor/std')
json := load('../vendor/json')
f := std.format
log := std.log
each := std.each
readFile := std.readFile
writeFile := std.writeFile

cli := load('../lib/cli')
queue := load('../lib/queue')

fs := load('fs')
sync := load('sync')
server := load('entry')
cleanPath := fs.cleanPath
describe := fs.describe
flatten := fs.flatten
ensurePDE := fs.ensureParentDirExists
diff := sync.diff

descRemote := (remote, path, cb) => req({
	method: 'GET'
	url: f('{{ remote }}/desc/{{ path }}', {
		remote: remote
		path: path
	})
}, evt => evt.type :: {
	'error' -> (
		log('Failed to desc: request error ' + evt.message)
		cb(())
	)
	'resp' -> evt.data.status :: {
		200 -> cb((json.de)(evt.data.body))
		_ -> (
			log('Failed to desc: response code ' + string(evt.data.status))
			cb(())
		)
	}
})

up := (remote, path, cb) => readFile(path, file => file :: {
	() -> log('Failed to up: file read error for ' + path)
	_ -> req({
		method: 'POST'
		url: f('{{ remote }}/sync/{{ path }}', {
			remote: remote
			path: path
		})
		body: file
	}, evt => evt.type :: {
		'error' -> log('Failed to up: request error ' + evt.message)
		'resp' -> evt.data.status :: {
			201 -> (
				log('up success: ' + path)
				cb()
			)
			_ -> log('Failed to up: response code ' + string(evt.data.status))
		}
	})
})

down := (remote, path, cb) => req({
	method: 'GET'
	url: f('{{ remote }}/sync/{{ path }}', {
		remote: remote
		path: path
	})
	body: ''
}, evt => evt.type :: {
	'error' -> log('Failed to down: request error ' + evt.message)
	'resp' -> evt.data.status :: {
		200 -> (
			ensurePDE(path, r => r :: {
				true -> writeFile(path, evt.data.body, r => r :: {
					true -> (
						log('down success: ' + path)
						cb()
					)
					_ -> log('Failed to down: write error ' + evt.message)
				})
				_ -> (
					log('Failed to down: could not mkdirp for ' + path)
				)
			})
		)
		_ -> log('Failed to down: response code ' + string(evt.data.status))
	}
})

` commands `
getPath := args => args.0 :: {
	() -> '.'
	_ -> args.0
}
withDiff := opts => args => cb => (
	descRemote(opts.remote, getPath(args), remoteDesc => (
		describe(getPath(args), getPath(args) + '/ignore.txt', localDesc => (
			cb(diff(flatten(localDesc), flatten(remoteDesc)))
		))
	))
)
desc := opts => args => (
	opts.remote :: {
		() -> describe(getPath(args), getPath(args) + '/ignore.txt', data => log(data))
		_ -> descRemote(opts.remote, getPath(args), data => log(data))
	}
)
plan := opts => args => (
	opts.remote :: {
		() -> log('Missing remote')
		_ -> withDiff(opts)(args)(df => (
			each(keys(df), path => log(f('{{ action }}: {{ path }}', {
					path: path
					action: df.(path) :: {
						0 -> 'up'
						1 -> 'down'
					}
			})))
		))
	}
)
sync := opts => args => (
	maxConcurrency := 6
	log(f('Syncing with {{ n }} workers', {n: maxConcurrency}))
	qu := (queue.new)(maxConcurrency) ` 6 concurrent connections `
	queueTask := qu.add

	opts.remote :: {
		() -> log('Missing remote')
		_ -> withDiff(opts)(args)(df => (
			each(keys(df), path => (
				fullPath := cleanPath(path) ` path starts with a / here `
				df.(path) :: {
					0 -> queueTask(cb => up(opts.remote, fullPath, cb))
					1 -> queueTask(cb => down(opts.remote, fullPath, cb))
				})
			)
		))
	}
)

` cli main: switch on given verb `
given := (cli.parsed)()
given.verb :: {
	'desc' -> desc(given.opts)(given.args)
	'plan' -> plan(given.opts)(given.args)
	'sync' -> sync(given.opts)(given.args)
	'serve' -> (server.start)()
	_ -> (
		log(f('Command "{{ verb }}" not recognized:', given))
		log(given)
	)
}

