` url router `

std := load('../vendor/std')
str := load('../vendor/str')

slice := std.slice
sliceList := std.sliceList
cat := std.cat
filter := std.filter
split := str.split

new := () => []

add := (router, pattern, handler) => router.len(router) := [pattern, handler]
catch := (router, handler) => add(router, '', handler)

splitPath := url => filter(split(url, '/'), s => ~(s = ''))

` if path matches pattern, return a hash of matched params.
	else, return () `
matchPath := (pattern, path) => (
	desired := splitPath(pattern)
	actual := splitPath(path)

	max := len(desired)
	params := {}
	findMatchingParams := (sub := i => i :: {
		max -> params
		_ -> (
			desiredPart := (desired.(i) :: {
				() -> ''
				_ -> desired.(i)
			})
			actualPart := (actual.(i) :: {
				() -> ''
				_ -> actual.(i)
			})

			desiredPart.0 :: {
				':' -> (
					params.(slice(desiredPart, 1, len(desiredPart))) := actualPart
					sub(i + 1)
				)
				'*' -> (
					params.(slice(desiredPart, 1, len(desiredPart))) := cat(sliceList(actual, i, len(actual)), '/')
					params
				)
				_ -> desiredPart :: {
					actualPart -> sub(i + 1)
					_ -> ()
				}
			}
		)
	})

	[len(desired) < len(actual) | len(desired) = len(actual), pattern] :: {
		` '' is used as a catch-all pattern `
		[_, ''] -> params
		[true, _] -> findMatchingParams(0)
		_ -> ()
	}
)

` returns the proper handler curried with url params `
match := (router, path) => (sub := i => i :: {
	len(router) -> req => (req.end)({
		status: 200
		headers: {}
		body: 'dropped route. you should never see this in production.'
	})
	_ -> (
		result := matchPath(router.(i).0, path)
		result :: {
			() -> sub(i + 1)
			_ -> (router.(i).1)(result)
		}
	)
})(0)
