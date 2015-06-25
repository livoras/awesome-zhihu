dev:
	nodemon client.coffee
spec:
	nodemon --exec "mocha test/*.coffee"
