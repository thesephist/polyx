` filesystem abstractions `

std := load('../vendor/std')
str := load('../vendor/str')
json := load('../vendor/json')

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
writeFile := std.writeFile

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

IgnoreFilePath := '/ignore.txt'
withIncludePredicate := (rootPath, cb) => (
	readFile(rootPath + IgnoreFilePath, file => file :: {
		() -> cb(() => true)
		_ -> (
			ignoreFiles := {}

			file := replace(file, char(13), '') ` remove \r's `
			lines := split(file, char(10))
			names := filter(lines, s => ~(s = ''))
			each(names, s => ignoreFiles.(s) := true)

			cb(s => ignoreFiles.(s) = ())
		)
	})
)

` hash cache is a performance optimization to cache checksums
	keyed by the string 'mod + path' for every encountered path on each run.

	hash cache relies on the fact that for a file to change its hash, it must
	also necessarily have a different modified timestamp. This is true in all
	practical cases, excluding some serious filesystem black magic. `
HashFilePath := '/.noctCache.json'
withPathHashWithQueue := qu => (path, cb) => (
	(qu.add)(done => exec('shasum', [path], '', e => e.type :: {
		'error' -> (
			log('Failed to hash: ' + e.message)
			cb('')
		)
		` shasum outputs "{{ hash }} {{ path }}".
			we only take the first 8 characters of the SHA1,
			which should be collision-free enough `
		_ -> cb(slice(e.data, 0, 8))
	})
))
withGetHash := (rootPath, cb) => (
	` withPathHash spins up child processes, which need to be queued
		to not get killed by the system. We limit to 12 child procs `
	withPathHash := withPathHashWithQueue((queue.new)(12))

	cache := {}
	` cached? callback if there is no cache `
	noCacheCallback := (path, mod, hcb) => withPathHash(path, hash => (
		cache.(string(mod) + path) := hash
		hcb(hash)
	))

	readFile(rootPath + HashFilePath, file => file :: {
		() -> (
			log('Hash cache not found, hashing from scratch')
			cb(noCacheCallback)
		)
		_ -> (
			prevCache := (json.de)(file)
			prevCache :: {
				() -> (
					log('Could not decode hash cache, hashing from scratch')
					cb(noCacheCallback)
				)
				_ -> cb((path, mod, hcb) => (
					key := string(mod) + path
					prevCache.(key) :: {
						() -> withPathHash(path, hash => (
							cache.(key) := hash
							hcb(hash)
						))
						_ -> (
							cache.(key) := prevCache.(key)
							hcb(prevCache.(key))
						)
					}
				))
			}
		)
	})

	() => writeFile(rootPath + HashFilePath, (json.ser)(cache), r => r :: {
		true -> log('Cache flushed to disk: ' + rootPath + HashFilePath)
		_ -> log('Cache write failed! Cache may be outdated or corrupt')
	})
)

` return a recursive description of a file/directory `
describe := (path, rootPath, cb) => (
	` all filesystem actions start at describe, so if we
		cleanPath here, it covers all cases `
	path := cleanPath(path)
	rootPath := cleanPath(rootPath)

	withIncludePredicate(rootPath, include? => (
		flush := withGetHash(rootPath, getHash => (
			describeWithQueue(path, include?, getHash, data => (
				flush()
				cb(data)
			))
		))
	))
)

describeWithQueue := (path, include?, getHash, cb) => stat(path, evt => [evt.type, evt.data] :: {
	['error', _] -> cb({})
	['data', ()] -> cb({})
	['data', _] -> evt.data.dir :: {
		false -> getHash(path, evt.data.mod, hash => cb({
			name: evt.data.name
			len: evt.data.len
			mod: evt.data.mod
			hash: hash
		}))
		true -> dir(path, dirEvt => (
			items := []
			dirEvt.type :: {
				'error' -> cb({})
				'data' -> len(dirEvt.data) :: {
					0 -> cb({
						name: evt.data.name
						items: items
					})
					_ -> (
						s := {found: 0}
						cbIfDone := () => (
							s.found := s.found + 1
							s.found :: {
								len(dirEvt.data) -> cb({
									name: evt.data.name
									items: items
								})
							}
						)
						each(dirEvt.data, f => include?(f.name) :: {
							true -> describeWithQueue(
								path + '/' + f.name
								include?
								getHash
								desc => (
									items.len(items) := desc
									cbIfDone()
								)
							)
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
