` ligature server `

std := load('../vendor/std')
str := load('../vendor/str')
log := std.log
f := std.format
reduce := std.reduce
cat := std.cat
readFile := std.readFile
writeFile := std.writeFile
letter? := str.letter?
digit? := str.digit?
trimPrefix := str.trimPrefix

http := load('../lib/http')
cli := load('../lib/cli')
mime := load('../lib/mime')
percent := load('../lib/percent')
mimeForPath := mime.forPath
pctDecode := percent.decode

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
	'POST' -> (
		cleanNoteLabel := label => reduce(
			label
			(acc, c) => (letter?(c) | digit?(c) | c = '-') :: {
				true -> acc + c
				false -> acc + '-'
			}
			''
		)

		label := pctDecode(cleanNoteLabel(trimPrefix(req.body, 'label=')))
		path := Config.dbPath + '/' + label + '.md'

		readFile(path, file => file :: {
			() -> writeFile(path, '', r => r :: {
				true -> (Pages.note.render)(Config.dbPath, label, html => end({
					status: 200
					headers: {
						'Content-Type': 'text/html'
					}
					body: html
				}))
				_ -> end({
					status: 500
					body: 'error creating note'
				})
			})
			_ -> end({
				status: 401
				body: f('{{ label }} already exists', {label: label})
			})
		})
	)
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
		label := params.label
		content := pctDecode(trimPrefix(req.body, 'content='))
		path := Config.dbPath + '/' + label + '.md'
		readFile(path, file => file :: {
			() -> end({
				status: 401
				body: f('{{ label }} does not exist', {label: label})
			})
			_ -> writeFile(path, content, r => r :: {
				true -> (Pages.note.render)(Config.dbPath, label, html => end({
					status: 200
					headers: {
						'Content-Type': 'text/html'
					}
					body: html
				}))
				_ -> end({
					status: 500
					body: 'error saving note'
				})
			})
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
