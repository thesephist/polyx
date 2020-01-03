` ligature server `

std := load('../vendor/std')
log := std.log
f := std.format
readFile := std.readFile
writeFile := std.writeFile

http := load('../lib/http')
cli := load('../lib/cli')
mime := load('../lib/mime')
mimeForPath := mime.forPath

Pages := {
	index: load('pg/index')
	note: load('pg/note')
	new: load('pg/new')
	find: load('pg/find')
}

Port := 7282
Config := {
	dbPath: '.'
}

server := (http.new)()

addRoute := server.addRoute
addRoute('/find', params => (req, end) => req.method :: {
	'GET' -> (Pages.find.render)(Config.dbPath, params.q, html => end({
		status: 200
		headers: {
			'Content-Type': 'text/html'
		}
		body: html
	}))
	_ -> end({
		status: 405
		body: 'method not allowed'
	})
})
addRoute('/new', params => (req, end) => req.method :: {
	'GET' -> (Pages.new.render)(html => end({
		status: 200
		headers: {
			'Content-Type': 'text/html'
		}
		body: html
	}))
	_ -> end({
		status: 405
		body: 'method not allowed'
	})
})
addRoute('/note/:label', params => (req, end) => req.method :: {
	'GET' -> (Pages.note.render)(Config.dbPath, params.label, html => end({
		status: 200
		headers: {
			'Content-Type': 'text/html'
		}
		body: html
	}))
	'POST' -> (
		'create note'
		end({
			status: 501
			body: 'not implemented'
		})
	)
	'PUT' -> (
		'update note, effectively same as POST with dif resp code'
		end({
			status: 501
			body: 'not implemented'
		})
	)
	'DELETE' -> (
		'delete note'
		end({
			status: 501
			body: 'not implemented'
		})
	)
	_ -> end({
		status: 405
		body: 'method not allowed'
	})
})
addRoute('/static/*staticPath', params => (req, end) => req.method :: {
	'GET' -> (
		staticPath := 'static/' + params.staticPath
		readFile(staticPath, file => file :: {
			() -> end({
				status: 404
				body: 'file not found'
			})
			_ -> end({
				status: 200
				headers: {
					'Content-Type': mimeForPath(staticPath)
				}
				body: file
			})
		})
	)
	_ -> end({
		status: 405
		body: 'method not allowed'
	})
})
addRoute('/', _ => (req, end) => req.method :: {
	'GET' -> (Pages.index.render)(Config.dbPath, html => end({
		status: 200
		headers: {
			'Content-Type': 'text/html'
		}
		body: html
	}))
	_ -> end({
		status: 405
		body: 'method not allowed'
	})
})

given := (cli.parsed)()
given.verb :: {
	'serve' -> (
		given.opts.db :: {
			() -> ()
			_ -> Config.dbPath := given.opts.db
		}
		close := (server.start)(Port)
		log('Ligature server started')
	)
	_ -> (
		log(f('Command "{{ verb }}" not recognized', given))
		log('Ligature supports serve')
		log(given)
	)
}
