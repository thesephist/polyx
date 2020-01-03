` /note/:label `

std := load('../../vendor/std')
str := load('../../vendor/str')
log := std.log
f := std.format
readFile := std.readFile

escape := load('../../lib/escape')
escapeHTML := escape.html

HeadTemplate := load('head').Template

render := (dbPath, label, cb) => (
	readFile(dbPath + '/' + label + '.md', file => file :: {
		() -> cb('error finding note')
		_ -> cb(Template(label, file))
	})
)

Template := (label, content) => f('
{{ head }}

<body>
	<form action="/note/{{ label }}" method="PUT" class="noteEditForm">
		<header>
			<a href="/" class="title">&larr; ligature</a>
			<input type="submit" value="save" class="frost card block"/>
		</header>

		<div class="noteEditor card">
			<div class="frost block">{{ label }}</div>
			<textarea name="content" class="paper block" autofocus>{{ content }}</textarea>
		</div>
	</form>
</body>
', {
	head: HeadTemplate(label + ' | ligature')
	label: label
	content: escapeHTML(content)
})
