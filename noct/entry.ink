` noct server `

std := load('../vendor/std')
json := load('../vendor/json')
log := std.log
readFile := std.readFile
writeFile := std.writeFile

http := load('../lib/http')
cli := load('../lib/cli')

fs := load('fs')
sync := load('sync')
cleanPath := fs.cleanPath
describe := fs.describe
flatten := fs.flatten
ensurePDE := fs.ensureParentDirExists

PORT := 7280

given := (cli.parsed)()
givenPath := (given.args.0 :: {
	() -> '.'
	_ -> given.args.0
})
ROOTFS := cleanPath(givenPath)

server := (http.new)()

addRoute := server.addRoute
addRoute('/desc/*descPath', params => (_, end) => (
	descPath := ROOTFS + '/' + cleanPath(params.descPath)
	describe(descPath, ROOTFS + '/ignore.txt', desc => end({
		status: 200
		body: (json.ser)(desc)
	}))
))
addRoute('/desc/', _ => (_, end) => (
	describe(ROOTFS, ROOTFS + '/ignore.txt', desc => end({
		status: 200
		body: (json.ser)(desc)
	}))
))
addRoute('/sync/*downPath', params => (req, end) => req.method :: {
	'GET' -> (
		downPath := ROOTFS + '/' + cleanPath(params.downPath)
		readFile(downPath, file => file :: {
			() -> end({
				status: 404
				body: 'file not found'
			})
			_ -> end({
				status: 200
				headers: {
					'Content-Type': 'application/octet-stream'
				}
				body: file
			})
		})
	)
	'POST' -> (
		downPath := ROOTFS + '/' + cleanPath(params.downPath)
		ensurePDE(downPath, r => r :: {
			true -> writeFile(downPath, req.body, r => r :: {
				true -> end({
					status: 201
					body: ''
				})
				_ -> end({
					status: 500
					body: 'upload failed, could not write file'
				})
			})
			_ -> end({
				status: 500
				body: 'upload failed, could not create dir'
			})
		})
	)
	_ -> end({
		status: 400
		body: 'invalid request'
	})
})

(server.start)(PORT)
