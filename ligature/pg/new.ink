` /new `

std := load('../../vendor/std')
str := load('../../vendor/str')
f := std.format

HeadTemplate := load('head').Template

render := cb => (
	cb(Template())
)

Template := () => f('
{{ head }}

<body>
	<form action="/new" method="POST" class="noteEditForm">
		<header>
			<a href="/" class="title">&larr; ligature</a>
			<input type="submit" value="create" class="frost card block"/>
		</header>

		<div class="card">
			<div class="frost block light">label</div>
			<input type="text" name="label" class="paper block" placeholder="new-note" required autofocus>
		</div>
	</form>
</body>
', {
	head: HeadTemplate('new | ligature')
})
