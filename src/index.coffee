path = require('path')
fs = require('fs')
{spawn} = require('child_process')
linestream = require('line-stream')


p = process.cwd()

while not fs.existsSync(path.join(p, 'package.json'))
  p = path.dirname(p)

phantomBin = path.join(p, 'node_modules/phantomjs/bin/phantomjs')
main = path.join(p, 'phantomjs/main.coffee')


class PhantomJS
  constructor: (@child) ->
    @pages = {}
    @requests = {}
    @requestId = 1


  createPage: (cb) ->
    createCb = (msg) =>
      rv = @pages[msg.pageId] = new Page(msg.pageId)
      cb(null, rv)

    @send(type: 'createPage', createCb)


  send: (msg, cb) ->
    id = @requestId++
    msg.requestId = id
    @requests[id] = cb
    msg = JSON.stringify(msg)
    @child.stdin.write("#{msg}\n", 'utf8')


  receive: (data) ->
    msg = JSON.parse(data)
    cb = @requests[msg.requestId]
    delete @requests[msg.requestId]
    cb(msg)


  close: (cb) ->
    @child.on('close', cb)
    @child.kill('SIGTERM')


class Page
  constructor: (@id) ->



phantomjs = (binPath, cb) ->
  if typeof binPath != 'string'
    if typeof binPath == 'function'
      cb = binPath
    binPath = phantomBin

  args = [main]
  opts = stdio: ['pipe', process.stdout, 'pipe']
  child = spawn(binPath, args, opts)
  instance = new PhantomJS(child)
  ready = false
  ls = linestream()
  child.stderr.pipe(ls)
  ls.on('data', (data) ->
    if not ready
      if data != 'ready'
        throw new Error('unexpected ready message')
      ready = true
      return cb(null, instance)
    instance.receive(data))
  child.on('error', (err) ->
    if not ready
      ready = true
      return cb(err)
    throw err)


module.exports = phantomjs
