` note card component `

std := load('../../vendor/std')
f := std.format

Template := note => (
	note.firstLine :: {
		'' -> note.firstLine := '(empty)'
	}
	f('
	<li>
		<a href="/note/{{ label }}" class="noteCard card" data-mod="{{ mod }}">
			<div class="paper block">
				{{ firstLine }}
			</div>
			<div class="noteMeta frost block light">
				<div>{{ label }}</div>
				<div class="modDate"></div>
			</div>
		</a>
	</li>
	', note)
)
