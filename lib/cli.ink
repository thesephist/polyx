` command-line interface abstractions
	for [cmd] [verb] [options] form`

std := load('../vendor/std')
str := load('../vendor/str')

each := std.each
slice := std.slice
sliceList := std.sliceList
hasPrefix? := str.hasPrefix?

maybeOpt := part => true :: {
	hasPrefix?(part, '--') -> slice(part, 2, len(part))
	hasPrefix?(part, '-') -> slice(part, 1, len(part))
	_ -> ()
}

`
Supports:
	-opt val
	--opt val
	-opt=val
	--opt val
all other values are considered args
`
parsed := () => (
	as := args()

	verb := as.2
	rest := sliceList(as, 3, len(as))

	opts := {}
	args := []

	s := {
		lastOpt: ()
	}
	each(rest, part => [maybeOpt(part), s.lastOpt] :: {
		[false, ()] -> ()
		[false, _] -> ()
		[_, ()] -> ()
		_ -> ()
	})

	{
		verb: verb
		opts: opts
		args: args
	}
)

(std.log)(parsed())
