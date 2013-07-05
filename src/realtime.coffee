exports.setup = (app, server)
  engineio = require 'engine.io'

  # Monkeypatching so we won't serve socket.io on all subdomains
  engineio.attach = (server, options) ->
    
    # normalize path
    check = (req) ->
      path is req.url.substr(0, path.length) and request.headers['host'] is app.get('host')
    engine = new engineio.Server(options)
    options = options or {}
    path = (options.path or "/engine.io").replace(/\/$/, "")
    destroyUpgrade = (if (options.destroyUpgrade isnt `undefined`) then options.destroyUpgrade else true)
    destroyUpgradeTimeout = options.destroyUpgradeTimeout or 1000
    path += "/"
    
    # cache and clean up listeners
    listeners = server.listeners("request").slice(0)
    server.removeAllListeners "request"
    server.on "close", engine.close.bind(engine)
    
    # add request handler
    server.on "request", (req, res) ->
      if check(req)
        debug "intercepting request for path \"%s\"", path
        engine.handleRequest req, res
      else
        for listener in listeners
          listener.call server, req, res

    if ~engine.transports.indexOf("websocket")
      server.on "upgrade", (req, socket, head) ->
        if check(req)
          engine.handleUpgrade req, socket, head
        else if false isnt options.destroyUpgrade
          
          # default node behavior is to disconnect when no handlers
          # but by adding a handler, we prevent that
          # and if no eio thing handles the upgrade
          # then the socket needs to die!
          setTimeout (->
            socket.end()  if socket.writable and socket.bytesWritten <= 0
          ), options.destroyUpgradeTimeout

    
    # flash policy file
    trns = engine.transports
    policy = options.policyFile
    if ~trns.indexOf("flashsocket") and false isnt policy
      server.on "connection", (socket) ->
        engine.handleSocket socket

    engine


  ###
  Redis/socket.io Specific
  ###

  url = require 'url'
  socketio = require 'socket.io'
  redis = require 'redis'
  redis.debug_mode = false

  io = socketio.listen(server)

  io.configure ->
    io.set "transports", ["xhr-polling"]
    io.set "polling duration", 10
    io.set 'log level', 1

  redisURL = url.parse app.get('PUBSUB_URL')

  subscriber = redis.createClient redisURL.port, redisURL.hostname, no_ready_check: true
  subscriber.auth redisURL.auth.split(":")[1]

  publisher = redis.createClient redisURL.port, redisURL.hostname, no_ready_check: true
  publisher.auth redisURL.auth.split(":")[1]

  subscriber.subscribe "instagram"
  subscriber.subscribe "tweet"

  subscriber.on "message", (channel, message) ->
    io.sockets.emit channel, message

  io.sockets.on "connection", (socket) ->
    publisher.get "latest_instagram", (err, reply) ->
      socket.emit 'instagram', reply
    publisher.get "latest_tweet", (err, reply) ->
      socket.emit 'tweet', reply
