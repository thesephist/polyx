` command-line interface abstractions
	for [cmd] [verb] [options] form`

std := load('../vendor/std')
str := load('../vendor/str')

each := std.each
slice := std.slice
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
	rest := slice(as, 3, len(as))

	opts := {}
	args := []

	s := {
		lastOpt: ()
		onlyArgs: false
	}
	each(rest, part => [maybeOpt(part), s.lastOpt] :: {
		[(), ()] -> (
			` not opt, no prev opt `
			args.len(args) := part
		)
		[(), _] -> (
			` not opt, prev opt exists `
			opts.(s.lastOpt) := part
			s.lastOpt := ()
		)
		[_, ()] -> (
			` is opt, no prev opt `
			s.lastOpt := maybeOpt(part)
		)
		_ -> (
			` is opt, prev opt exists `
			opts.(s.lastOpt) := true
			s.lastOpt := maybeOpt(part)
		)
	})

	s.lastOpt :: {
		() -> ()
		_ -> opts.(s.lastOpt) := true
	}

	{
		verb: verb
		opts: opts
		args: args
	}
)
