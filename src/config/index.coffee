#### Config file
# Sets application config parameters depending on `env` name
exports.setEnvironment = (env) ->
  console.log "set app environment: #{env}"
  switch(env)
    when "development"
      exports.DEBUG_LOG = true
      exports.DEBUG_WARN = true
      exports.DEBUG_ERROR = true
      exports.DEBUG_CLIENT = true
      exports.KEY_STORE_URL = "redis://redis:redis@localhost:6379/"
      exports.PUBSUB_URL = "redis://redis:redis@localhost:6379/"
      exports.host = ['localhost']

    when "testing"
      exports.DEBUG_LOG = true
      exports.DEBUG_WARN = true
      exports.DEBUG_ERROR = true
      exports.DEBUG_CLIENT = true
      exports.KEY_STORE_URL = "redis://redis:redis@localhost:6379/"
      exports.PUBSUB_URL = "redis://redis:redis@localhost:6379/"
      exports.host = ['localhost']

    when "production"
      exports.DEBUG_LOG = false
      exports.DEBUG_WARN = false
      exports.DEBUG_ERROR = true
      exports.DEBUG_CLIENT = false
      exports.KEY_STORE_URL = process.env.REDISCLOUD_URL
      exports.PUBSUB_URL = process.env.REDISTOGO_URL
      exports.host = ['www.reqres.me', 'reqres.me']
    else
      console.log "environment #{env} not found"
