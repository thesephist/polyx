` command-line interface abstractions
	for [cmd] [verb] [options] form`

std := load('std')

sliceList := std.sliceList

parsed := () => (
	as := args()

	verb := as.2
	opts := sliceList(as, 3, len(as))

	{
		verb: verb
		opts: opts
	}
)
