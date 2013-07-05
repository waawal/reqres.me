#### Routes
# We are setting up theese routes:
#
# GET, POST, PUT, DELETE methods are going to the same controller methods - we dont care.
# We are using method names to determine controller actions for clearness.

module.exports = (app) ->
  
  app.all '/*', (req, res, next) ->
    if not req.subdomains.length or (
      req.subdomains.length is 1 and req.subdomain[0] is 'www')
      routeMvc('index', req, res, next)
    else
      res.send subdomains: req.subdomains
    

# render the page based on controller
routeMvc = (controllerName, methodName, req, res, next) ->
  controllerName = 'index' if not controllerName?
  controller = null
  try
    controller = require "./controllers/" + controllerName
  catch e
    console.warn "controller not found: " + controllerName, e
    next()
    return
  controller req, res, next