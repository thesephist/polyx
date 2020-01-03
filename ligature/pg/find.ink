` /find?q=search%20term `

std := load('../../vendor/std')
str := load('../../vendor/str')
f := std.format
each := std.each
map := std.map
filter := std.filter
cat := std.cat
readFile := std.readFile
split := str.split
replace := str.replace
trimPrefix := str.trimPrefix

quicksort := load('../../lib/quicksort')
sortInPlace := quicksort.sortInPlace

HeadTemplate := load('head').Template
NoteCard := load('card').Template

` we delegate the search code to grep (or in the future perhaps some other optimized
	file searcher like fgrep/ag) to be fast, and keep ligature's codebase small `
render := (dbPath, query, cb) => exec('sh', ['-c', f('grep -sil "{{ query }}" {{ dbPath }}/*', {
	query: replace(query, '"', '\\"')
	dbPath: dbPath
})], '', evt => evt.type :: {
	'error' -> cb('error finding notes: ' + evt.message)
	_ -> (
		fileList := evt.data
		fileNames := map(split(evt.data, char(10)), path => trimPrefix(path, dbPath + '/'))
		fileNames := filter(fileNames, s => ~(s = ''))
		` key it into a map to make it an indexed set `
		fileNameKeyed := {}
		each(fileNames, p => fileNameKeyed.(p) := true)

		` to get note metadata, we'll stat all notes, then
			filter the list down to matched notes `
		dir(dbPath, evt => evt.type :: {
			'error' -> cb('error finding notes')
			_ -> (
				sortInPlace(evt.data, fstat => ~(fstat.mod))
				matchedFiles := filter(evt.data, info => fileNameKeyed.(info.name))

				notes := map(matchedFiles, fileInfo => {
					label: split(fileInfo.name, '.').0
					firstLine: '...?'
				})

				` below is a modified version of pg/index.ink `
				s := {
					count: 0
					total: len(notes)
				}
				each(notes, n => readFile(dbPath + '/' + n.label + '.md', file => (
					file :: {
						() -> n.firstLine := 'error reading...'
						` hand-rolled efficient code to only trim file to
							the first line (first newline character) `
						_ -> n.firstLine := (sub := (acc, i) => file.(i) :: {
							() -> acc
							char(10) -> acc
							_ -> (
								acc + file.(i)
								sub(acc + file.(i), i + 1)
							)
						})('', 0)
					}

					s.count := s.count + 1
					s.count :: {
						(s.total) -> cb(Template(notes, query))
					}
				)))
			)
		})
	)
})

Template := (notes, query) => f('
{{ head }}

<body>
	<header>
		<a href="/" class="title">ligature</a>
		<form action="/find" method="GET" class="searchBar card">
			<input type="text" name="q" placeholder="search..." class="searchInput paper block" value="{{ query }}"/>
			<input type="submit" value="find" class="frost block"/>
		</form>
		<a href="/new" class="newButton frost card block">new</a>
	</header>

	<ul class="noteList">
		{{ noteCards }}
	</ul>
</body>
', {
	head: HeadTemplate(f('find "{{ query }}" | ligature', {query: query}))
	noteCards: cat(map(notes, NoteCard), '')
	query: query
})
