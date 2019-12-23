` sync operations `

std := load('../vendor/std')

log := std.log
each := std.each

fs := load('fs')

` generate a sycn plan from a list of
	paths and stats `
diff := (local, remote) => (
	` key: action, where 0 = push up, 1 = pull down `
	plan := []
	each(keys(local), lpath => remote.(lpath) :: {
		() -> plan.(lpath) := 0
	})
	each(keys(remote), rpath => local.(rpath) :: {
		() -> plan.(rpath) := 1
	})
	plan
)

