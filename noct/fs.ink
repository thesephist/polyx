` filesystem abstractions `

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
cat := std.cat
each := std.each
filter := std.filter
range := std.range
slice := std.slice
sliceList := std.sliceList
split := str.split
replace := str.replace
readFile := std.readFile

queue := load('../lib/queue')

` prevent climbing out of root directory of noct service `
cleanPath := path => (
	path := replace(path, '/../', '/')
	path := replace(path, '/./', '/')
	path := (path.0 :: {
		'/' -> slice(path, 1, len(path))
		_ -> path
	})
	path.(len(path) - 1) :: {
		'/' -> slice(path, 0, len(path) - 1)
		_ -> path
	}
)

` return a recursive description of a file/directory `
describe := (path, ignoreFilePath, cb) => (
	` all filesystem actions start at describe, so if we
		cleanPath here, it covers all cases `
	path := cleanPath(path)
	qu := (queue.new)(12) ` 12 concurrent child processes `

	readFile(ignoreFilePath, file => file :: {
		() -> describeWithQueue(path, qu, cb, () => true)
		_ -> (
			ignoreFiles := {}

			file := replace(file, char(13), '') ` remove \r's `
			lines := split(file, char(10))
			names := filter(lines, s => ~(s = ''))
			each(names, s => ignoreFiles.(s) := true)

			describeWithQueue(path, qu, cb, s => ignoreFiles.(s) = ())
		)
	})
)

describeWithQueue := (path, qu, cb, include?) => stat(path, evt => [evt.type, evt.data] :: {
	['error', _] -> cb({})
	['data', ()] -> cb({})
	['data', _] -> evt.data.dir :: {
		false -> (qu.add)(qcb => exec('shasum', [path], '', e => (
			e.type :: {
				'error' -> (
					log(e.message)
					cb({})
				)
				_ -> cb({
					name: evt.data.name
					len: evt.data.len
					mod: evt.data.mod
					hash: split(e.data, ' ').0
				})
			}
			qcb()
		)))
		true -> dir(path, devt => (
			items := []
			devt.type :: {
				'error' -> cb({})
				'data' -> len(devt.data) :: {
					0 -> cb({
						name: evt.data.name
						items: items
					})
					_ -> (
						s := {found: 0}
						cbIfDone := () => (
							s.found := s.found + 1
							s.found :: {
								len(devt.data) -> cb({
									name: evt.data.name
									items: items
								})
							}
						)
						each(devt.data, f => include?(f.name) :: {
							true -> describeWithQueue(path + '/' + f.name, qu, desc => (
								items.len(items) := desc
								cbIfDone()
							), include?)
							_ -> cbIfDone()
						})
					)
				}
			}
		))
	}
})

` flatten the nested directory description
	into a single flat list of paths `
flatten := desc => desc :: {
	{} -> {}
	_ -> (
		items := {}
		` to generate a sync plan, all paths should be absolute relative to 
			the root dir of describe() `
		trimPath := path => slice(path, len(desc.name) + 1, len(path))
		add := (path, mod, hash, size) => items.trimPath(path) := {
			mod: mod
			hash: hash
			size: size
		}
		flattenRec(desc, '', add)
		items
	)
}

flattenRec := (desc, pathPrefix, add) => (
	desc.items :: {
		() -> add(pathPrefix + '/' + desc.name, desc.mod, desc.hash, desc.len)
		_ -> each(desc.items, f => flattenRec(f, pathPrefix + '/' + desc.name, add))
	}
)

ensureParentDirExists := (path, cb) => (
	` path is clean and of the form a/b/c.ext, we want a/b `
	parts := split(path, '/')
	len(parts) :: {
		1 -> cb(true) ` no dirs need be created `
		_ -> (
			parentDir := cat(sliceList(parts, 0, len(parts) - 1), '/')
			make(parentDir, evt => evt.type :: {
				'error' -> cb(())
				_ -> cb(true)
			})
		)
	}
)
