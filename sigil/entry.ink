http := load('../lib/http')

PORT := 7282

server := (http.new)()

addRoute := server.addRoute
`` addRoute('/static', staticHandler)

(server.start)(PORT)
