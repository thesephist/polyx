` sync operations `

std := load('../vendor/std')

each := std.each

fs := load('fs')

` generate a sycn plan from a list of
	paths and stats `
diff := (local, remote) => (
	` key: action, where 0 = push up, 1 = pull down `
	plan := []
	each(keys(local), lpath => remote.(lpath) :: {
		() -> plan.(lpath) := 0
		_ -> local.(lpath).hash :: {
			(remote.(lpath).hash) -> ()
			_ -> local.(lpath).mod > remote.(lpath).mod :: {
				true -> plan.(lpath) := 0
				false -> plan.(lpath) := 1
			}
		}
	})
	each(keys(remote), rpath => local.(rpath) :: {
		() -> plan.(rpath) := 1
	})
	plan
)
