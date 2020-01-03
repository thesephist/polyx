` note card component `

std := load('../../vendor/std')
f := std.format

Template := note => f('
<li>
	<a href="/note/{{ label }}" class="card">
		<div class="paper block">
			{{ firstLine }}
		</div>
		<div class="frost block light">
			{{ label }}
		</div>
	</a>
</li>
', note)
