exports.setup = (app, server) ->
  debug = require('debug')('socket.io:server')
  engineio = require 'engine.io'


  # Monkeypatching so we won't serve socket.io on all subdomains
  engineio.attach = (server, options) ->
    
    # normalize path
    check = (req) ->
      console.log app.get('host'), 'is the host'
      path is req.url.substr(0, path.length) and request.headers['host'] in app.get('host')
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

  engineio.listen = (port, options, fn) ->
    if "function" is typeof options
      fn = options
      options = {}
    server = http.createServer((req, res) ->
      res.writeHead 501
      res.end "Not Implemented"
    )
    server.listen port, fn
    
    # create engine server
    engine = engineio.attach(server, options)
    engine.httpServer = server
    engine

  socketio = require 'socket.io'
  engine = engineio

  socketio.listen = (srv, opts) ->
    if "function" is typeof srv
      msg = "You are trying to attach socket.io to an express" + "request handler function. Please pass a http.Server instance."
      throw new Error(msg)
    if "number" is typeof srv
      debug "creating http server and binding to %d", srv
      port = srv
      srv = http.Server((req, res) ->
        res.writeHead 404
        res.end()
      )
      srv.listen port
    
    # set engine.io path to `/socket.io`
    opts = opts or {}
    opts.path = opts.path or "/socket.io"
    
    # initialize engine
    debug "creating engine.io instance with opts %j", opts
    eio = engine.attach(srv, opts)
    
    # attach static file serving
    @serve srv  if @_static
    
    # bind to engine events
    @bind eio
    this

  ###
  Redis/socket.io Specific
  ###
  
  io = socketio.listen(server)
  io.configure ->
    io.set "transports", ["xhr-polling"]
    io.set "polling duration", 10
    io.set 'log level', 1

  io.sockets.on "connection", (socket) ->  
    socket.emit 'connect', 'yolo'

  url = require 'url'
  redis = require 'redis'
  redis.debug_mode = false

createRedisService = (serviceUrl) ->
  redisURL = url.parse app.get(serviceUrl)
  client = redis.createClient redisURL.port, redisURL.hostname, no_ready_check: true
  client.auth redisURL.auth.split(":")[1]
  return client

createPubSubConnection = ->
  createRedisService('PUBSUB_URL')

createRedisConnection = ->
  createRedisService('KEY_STORE_URL')

exports.pubsub = (app) ->
  #subscriber.subscribe "instagram"
  #subscriber.subscribe "tweet"
  #subscriber.on "message", (channel, message) ->
  #  io.sockets.emit channel, message