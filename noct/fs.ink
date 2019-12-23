` filesystem abstractions `

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
cat := std.cat
each := std.each
range := std.range
slice := std.slice
sliceList := std.sliceList
split := str.split

` return a recursive description of a file/directory `
describe := (path, cb) => stat(path, evt => evt.type :: {
	'error' -> cb(())
	'data' -> evt.data.dir :: {
        ` TODO: doing this massively in parallel causes UNIX
            too many open files error, queue it `
        false -> exec('shasum', [path], '', e => e .type :: {
            'error' -> (log(e.message), cb(()))
            _ -> cb({
                name: evt.data.name
                len: evt.data.len
                mod: evt.data.mod
                hash: split(e.data, ' ').0
            })
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
	` to generate a sync plan, all paths should be absolute relative to 
		the root dir of describe() `
	trimPath := path => slice(path, len(desc.name) + 1, len(path))
	add := (path, mod, hash) => items.trimPath(path) := {mod: mod, hash: hash}
	flattenRec(desc, '', add)
	items
)

flattenRec := (desc, pathPrefix, add) => (
	desc.items :: {
		() -> add(pathPrefix + '/' + desc.name, desc.mod, desc.hash)
		_ -> each(desc.items, f => flattenRec(f, pathPrefix + '/' + desc.name, add))
	}
)

ensureParentDirExists := (path, cb) => (
    ` path is of the form a/b/c.ext `
    parts := split(path, '/')
    parentDir := cat(sliceList(parts, 0, len(parts) - 1))
    (std.log)(parentDir)
    make(parentDir, evt => evt.type :: {
        'error' -> cb(())
        _ -> cb(true)
    })
)
