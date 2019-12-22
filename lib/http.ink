` http server abstraction `

std := load('../vendor/std')

log := std.log
f := std.format
each := std.each

auth := load('auth')
allow? := auth.allow?

route := load('route')

new := () => (
	router := (route.new)()
	(route.catch)(router, req => {
		status: 404
		body: 'service not found'
	})

	start := port => listen('0.0.0.0:' + string(port), evt => evt.type :: {
		'error' -> log('server start error: ' + evt.message)
		'req' -> (
			log(f('{{ method }}: {{ url }}', evt.data))
			url := trimQP(evt.data.url)

			handleWithHeaders := evt => (
				handler := (route.match)(router, url)
				resp := handler(evt)

				resp.headers := hdr(resp.headers :: {
					() -> {}
					_ -> resp.headers
				})
				(evt.end)(resp)
			)
			[allow?(evt.data), evt.data.method] :: {
				[true, 'GET'] -> handleWithHeaders(evt.data)
				[true, 'POST'] -> handleWithHeaders(evt.data)
				[true, 'PUT'] -> handleWithHeaders(evt.data)
				[true, 'DELETE'] -> handleWithHeaders(evt.data)
				_ -> (evt.end)({
					status: 405
					headers: hdr({})
					body: 'method not allowed'
				})
			}
		)
	})

	{
		addRoute: (url, handler) => (route.add)(router, url, handler)
		start: start
	}
)

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
