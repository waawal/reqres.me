express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
subdomains = require('express-subdomains')

#### Basic application initialization
# Create app instance.
app = express()


# Define Port
app.port = process.env.PORT or process.env.VMC_APP_PORT or 3000


# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require "./config"
app.configure 'production', 'development', 'testing', ->
  config.setEnvironment app.settings.env


#### View initialization 
# Add Connect Assets.
app.use assets()
# Set the public folder as static assets.
app.use express.static(process.cwd() + '/public')
# Express Session
#store = new express.session.MemoryStore
#app.use express.cookieParser()
#app.use express.session(
#  secret: 'shhh'
#  store: store
#) 

# Set View Engine.
app.set 'view engine', 'jade'

# [Body parser middleware](http://www.senchalabs.org/connect/middleware-bodyParser.html) parses JSON or XML bodies into `req.body` object
app.use express.bodyParser()
app.use(subdomains.middleware)


#### Finalization
# Initialize routes
routes = require './routes'
routes(app)

# Export application object
module.exports = app
