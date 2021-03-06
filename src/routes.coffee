#### Routes
# We are setting up theese routes:
#
# GET, POST, PUT, DELETE methods are going to the same controller methods - we dont care.
# We are using method names to determine controller actions for clearness.

module.exports = (app) ->
  
  app.all '/*', (req, res, next) ->
    if not req.subdomains.length or (
      req.subdomains.length is 1 and req.subdomains[0] is 'www')
      routeMvc('index', req, res, next)
    else
      switch req.subdomains[0]
        when 'req' then routeMvc('req', req, res, next)
        when 'res' then routeMvc('res', req, res, next)
        else routeMvc('reqres', req, res, next)
    

# render the page based on controller
routeMvc = (controllerName, req, res, next) ->
  try
    controller = require "./controllers/" + controllerName
  catch e
    console.warn "controller not found: " + controllerName, e
    next()
    return
  controller req, res, next