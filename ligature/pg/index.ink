` /index.html `

std := load('../../vendor/std')
str := load('../../vendor/str')
log := std.log
f := std.format
each := std.each
map := std.map
cat := std.cat
split := str.split

HeadTemplate := load('head').Template

render := (dbPath, cb) => (
	` get all note labels `
	dir(dbPath, evt => evt :: {
		'error' -> cb('error finding notes')
		_ -> (
			notes := map(evt.data, fileInfo => {
				label: split(fileInfo.name, '.').0
				firstLine: 'first line: todo'
			})
			cb(Template(notes))
		)
	})
)

NoteCard := note => f('
<li>
	<a href="/note/{{ label }}" class="card">
		<div class="frost block">
			{{ label }}
		</div>
		<div class="paper block">
			{{ firstLine }}
		</div>
	</a>
</li>
', note)

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
