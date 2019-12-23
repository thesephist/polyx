http := load('../lib/http')

fs := load('fs')
sync := load('sync')

PORT := 7280

server := (http.new)()

addRoute := server.addRoute
addRoute('/static', params => req => {status: 200, body: 'wat'})

(server.start)(PORT)
