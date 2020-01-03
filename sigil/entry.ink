http := load('../lib/http')

PORT := 7283

server := (http.new)()

addRoute := server.addRoute
`` addRoute('/static', staticHandler)

(server.start)(PORT)
