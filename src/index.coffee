url = require 'url'
express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
redis = require 'redis'
socketio = require 'socket.io'

#### Basic application initialization
# Create app instance.
app = express()

# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require "./config"
app.configure 'production', 'development', 'testing', ->
  config.setEnvironment app.settings.env

redis.debug_mode = false

app.disable('x-powered-by') # Sthealt!

#### View initialization 
# Add Connect Assets.
app.use assets()
# Set the public folder as static assets.
app.use express.static(process.cwd() + '/public')

app.use express.methodOverride()

# ## CORS middleware
# 
# see: http://stackoverflow.com/questions/7067966/how-to-allow-cors-in-express-nodejs
allowCrossDomain = (req, res, next) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Methods", "GET,PUT,POST,DELETE"
  res.header "Access-Control-Allow-Headers", "Content-Type, Authorization"
  
  # intercept OPTIONS method
  if "OPTIONS" is req.method
    res.send 200
  else
    next()

app.use allowCrossDomain

# Set View Engine.
app.set 'view engine', 'jade'

# [Body parser middleware](http://www.senchalabs.org/connect/middleware-bodyParser.html) parses JSON or XML bodies into `req.body` object
app.use express.bodyParser()

server = require("http").createServer(app)
# Define Port
server.port = process.env.PORT or process.env.VMC_APP_PORT or 3000

###
Redis/socket.io Specific
###

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


#### Finalization
# Initialize routes
routes = require './routes'
routes(app)



# Export server
module.exports = server
