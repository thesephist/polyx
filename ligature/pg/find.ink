` /find?q=search%20term `

std := load('../../vendor/std')
str := load('../../vendor/str')
log := std.log
f := std.format
each := std.each
map := std.map
filter := std.filter
cat := std.cat
split := str.split
replace := str.replace
trimPrefix := str.trimPrefix

HeadTemplate := load('head').Template

render := (dbPath, query, cb) => (
	exec('sh', ['-c', f('grep -sil "{{ query }}" {{ dbPath }}/*', {
		query: replace(query, '"', '\\"')
		dbPath: dbPath
	})], '', evt => evt.type :: {
		'error' -> cb('error finding notes: ' + evt.message)
		_ -> (
			fileList := evt.data
			filePaths := map(split(evt.data, char(10)), path => trimPrefix(path, dbPath + '/'))
			filePaths := filter(filePaths, s => ~(s = ''))
			notes := map(filePaths, fileName => {
				label: split(fileName, '.').0
				firstLine: 'first line: todo'
			})
			cb(Template(notes, query))
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
