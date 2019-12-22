#!/usr/bin/env ink

` nought, @thesephist's personal crm `

std := load('vendor/std')

log := std.log
f := std.format
each := std.each

auth := load('lib/auth')
allow? := auth.allow?

route := load('lib/route')
services := {
	statics: load('lib/routes/statics')
	apis: load('lib/routes/apis')
	errors: load('lib/routes/errors')
}

PORT := 9220

log('Nought starting...')

` attach routes `
router := (route.new)()
add := (url, handler) => (route.add)(router, url, handler)
add('/static/*staticPath', services.statics.handler)
add('/api/person', services.apis.allPersonHandler)
add('/api/person/:personID', services.apis.personHandler)
add('/api/event', services.apis.allEventHandler)
add('/api/event/:eventID', services.apis.eventHandler)
add('/', services.statics.indexHandler)
` catch-all handler for 404s `
(route.catch)(router, services.errors.handler)

` start http server `
close := listen('0.0.0.0:' + string(PORT), evt => evt.type :: {
	'error' -> log('server error: ' + evt.message)
	'req' -> (
		log(f('{{ method }}: {{ url }}', evt.data))

		` normalize path `
		url := trimQP(evt.data.url)

		` respond to file request `
		handle := (route.match)(router, url)
		[allow?(evt), evt.data.method] :: {
			[true, 'GET'] -> handle(evt)
			[true, 'POST'] -> handle(evt)
			[true, 'PUT'] -> handle(evt)
			[true, 'DELETE'] -> handle(evt)
			_ -> (
				` if other methods, just drop the request `
				log('  -> ' + evt.data.url + ' dropped')
				(evt.end)({
					status: 405
					headers: hdr({})
					body: 'method not allowed'
				})
			)
		}
	)
})

` prepare standard header `
hdr := attrs => (
	base := {
		'X-Served-By': 'ink-serve'
		'Content-Type': 'text/plain'
	}
	each(keys(attrs), k => base.(k) := attrs.(k))
	base
)

` trim query parameters `
trimQP := path => (
	max := len(path)
	(sub := (idx, acc) => idx :: {
		max -> path
		_ -> path.(idx) :: {
			'?' -> acc
			_ -> sub(idx + 1, acc + path.(idx))
		}
	})(0, '')
)
