# Just renders index.jade

exports.index = (req, res) ->
    res.send
      headers: req.headers
      query: req.query
      prams: req.params
      body: req.body
      