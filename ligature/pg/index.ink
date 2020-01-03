` /index.html `

std := load('../../vendor/std')
str := load('../../vendor/str')
f := std.format
each := std.each
map := std.map
cat := std.cat
split := str.split
readFile := std.readFile

quicksort := load('../../lib/quicksort')
sortInPlace := quicksort.sortInPlace

HeadTemplate := load('head').Template
NoteCard := load('card').Template

render := (dbPath, cb) => dir(dbPath, evt => evt.type :: {
	'error' -> cb('error finding notes')
	_ -> (
		` notes are sorted by date last modified (reverse chron) `
		sortInPlace(evt.data, fstat => ~(fstat.mod))

		notes := map(evt.data, fileInfo => {
			label: split(fileInfo.name, '.').0
			firstLine: '...?'
		})

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
				(s.total) -> cb(Template(notes))
			}
		)))
	)
})

Template := notes => f('
{{ head }}

<body>
	<header>
		<a href="/" class="title">ligature</a>
		<form action="/find" method="GET" class="searchBar card">
			<input type="text" name="q" placeholder="search..." class="searchInput paper block"/>
			<input type="submit" value="find" class="frost block"/>
		</form>
		<a href="/new" class="newButton frost card block">new</a>
	</header>

	<ul class="noteList">
		{{ noteCards }}
	</ul>
</body>
', {
	head: HeadTemplate('ligature')
	noteCards: cat(map(notes, NoteCard), '')
})
