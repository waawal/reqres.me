module.exports = (req, res) ->
  res.send
    subdomains: req.subdomains
    headers: req.headers
    query: req.query
    prams: req.params
    body: req.body