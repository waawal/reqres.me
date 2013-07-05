express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'


#### Basic application initialization
# Create app instance.
app = express()

# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require "./config"
app.configure 'production', 'development', 'testing', ->
  config.setEnvironment app.settings.env

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

realtime = require './realtime'
realtime.setup(app, server)

#### Finalization
# Initialize routes
routes = require './routes'
routes(app)



# Export server
module.exports = server
