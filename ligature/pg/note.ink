` /note/:label `

std := load('../../vendor/std')
str := load('../../vendor/str')
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
	<form action="/note/{{ label }}" method="POST" class="noteEditForm">
		<header>
			<a href="/" class="title">&larr; ligature</a>
			<a href="/new" class="newButton frost card block"
				style="margin-left: auto; margin-right: 12px">new</a>
			<input type="submit" value="save" class="saveButton frost card block"/>
		</header>

		<div class="noteEditor card">
			<div class="frost block light">{{ label }}</div>
			<textarea name="content" class="paper block" autofocus>{{ content }}</textarea>
		</div>
	</form>
	<script src="/static/js/ligature.js"></script>
</body>
', {
	head: HeadTemplate(label + ' | ligature')
	label: label
	content: escapeHTML(content)
})
