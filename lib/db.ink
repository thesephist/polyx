` json database abstraction `

std := load('../vendor/std')
uuid := load('../vendor/uuid')
json := load('../vendor/json')

log := std.log
readFile := std.readFile
writeFile := std.writeFile
each := std.each
map := std.map
filter := std.filter
every := std.every
uuid := uuid.uuid
ser := json.ser
de := json.de

` reports whether properties of X satisfy attrs, which is
	a hash of keys to either exact values or predicate functions `
matches := (x, attrs) => every(map(
	keys(attrs)
	k => (
		v := attrs.(k)
		type(v) :: {
			'function' -> v(x.(k))
			_ -> x.(k) = v
		}
	)
))

` get-or-create a collection `
ensureCollection := db => name => db.data.(name) :: {
	() -> (
		db.data.(name) := []
		db.data.(name)
	)
	_ -> db.data.(name)
}

` create an instance of a collection `
create := db => (collection, attrs) => (
	coll := (db.ensureCollection)(collection)

	nxt := len(coll)
	coll.(nxt) := attrs

	` generate a uuid for every new model `
	x := coll.(nxt)
	x.id := uuid()

	(db.flush)()
	x
)

` update an instance of a collection `
update := db => (collection, attrs, delta) => (
	x := (db.get)(collection, attrs)
	each(keys(delta), k => x.(k) := delta.(k))
	(db.flush)()
	x
)

` retrieve the first matching instance of a collection `
get := db => (collection, attrs) => (
	coll := (db.ensureCollection)(collection)
	(sub := i => i :: {
		len(coll) -> ()
		_ -> matches(coll.(i), attrs) :: {
			true -> coll.(i)
			false -> sub(i + 1)
		}
	})(0)
)

` retrieve all matching instances of a collection `
where := db => (collection, attrs) => (
	coll := (db.ensureCollection)(collection)
	filter(coll, x => matches(x, attrs))
)

` remove all matching instances of a collection `
remove := db => (collection, attrs) => (
	coll := (db.ensureCollection)(collection)
	db.data.(collection) := filter(coll, x => ~matches(x, attrs))
	(db.flush)()
)

` instantiate a new database `
new := path => (
	instance := {
		data: {}
	}

	` define scoped methods `
	instance.flush := () => writeFile(
		path
		ser(instance.data)
		() => log('flushed db at ' + string(floor(time())))
	)
	instance.ensureCollection := ensureCollection(instance)
	instance.create := create(instance)
	instance.update := update(instance)
	instance.get := get(instance)
	instance.where := where(instance)
	instance.remove := remove(instance)

	readFile(
		path
		s => de(s) :: {
			` guard against failed reads, crash early `
			() -> (std.log)('Failed database read!')
			_ -> instance.data := de(s)
		}
	)

	instance
)
