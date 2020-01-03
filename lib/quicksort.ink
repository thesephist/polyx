` quicksort adopted from https://en.wikipedia.org/wiki/Quicksort `

std := load('../vendor/std')
clone := std.clone
map := std.map

` main recursive quicksort routine `
quicksort := (list, values, lo, hi) => lo < hi :: {
	true -> (
		p := partition(list, values, lo, hi)
		quicksort(list, values, lo, p - 1)
		quicksort(list, values, p + 1, hi)
	)
}

` Lomuto partition scheme `
partition := (list, values, lo, hi) => (
	` arbitrarily pick last value as pivot `
	pivot := values.(hi)
	acc := {
		i: lo
	}

	loop := j => j :: {
		hi -> ()
		_ -> (
			values.(j) < pivot :: {
				true -> (
					swap(list, values, acc.i, j)
					acc.i := acc.i + 1
				)
			}
			loop(j + 1)
		)
	}
	
	loop(lo)

	swap(list, values, acc.i, hi)
	acc.i
)

` swap two places in a given list `
swap := (list, values, i, j) => (
	last := {
		i: list.(i)
		j: list.(j)
	}
	vlast := {
		i: values.(i)
		j: values.(j)
	}
	list.(i) := last.j
	list.(j) := last.i
	values.(i) := vlast.j
	values.(j) := vlast.i
)

` top-level sorting function for QuickSort `
sortInPlace := (list, predicate) => (
	quicksort(list, map(list, predicate), 0, len(list) - 1)
	list
)
sort := (list, predicate) => sortInPlace(clone(list, predicate))
