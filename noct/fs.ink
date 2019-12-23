` filesystem abstractions `

std := load('../vendor/std')

log := std.log
each := std.each

` return a recursive description of a file/directory `
describe := (path, cb) => stat(path, evt => evt.type :: {
	'error' -> cb(())
	'data' -> evt.data.dir :: {
		false -> cb({
			name: evt.data.name
			len: evt.data.len
			mod: evt.data.mod
		})
		true -> dir(path, devt => (
			items := []
			devt.type :: {
				'error' -> cb(())
				'data' -> len(devt.data) :: {
					0 -> cb({
						name: evt.data.name
						items: items
					})
					_ -> each(devt.data, f => describe(path + '/' + f.name, desc => (
						items.len(items) := desc
						len(items) :: {
							len(devt.data) -> cb({
								name: evt.data.name
								items: items
							})
						}
					)))
				}
			}
		))
	}
})

` flatten the nested directory description
	into a single flat list of paths `
flatten := desc => (
	items := {}
	add := (path, mod) => items.(path) := mod
	flattenRec(desc, '', add)
	items
)

flattenRec := (desc, pathPrefix, add) => (
	desc.items :: {
		() -> add(pathPrefix + '/' + desc.name, desc.mod)
		_ -> each(desc.items, f => flattenRec(f, pathPrefix + '/' + desc.name, add))
	}
)
