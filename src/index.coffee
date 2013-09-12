path = require('path')
http = require('http')
fs = require('fs')
require('coffee-script')
{spawn} = require('child_process')
{EventEmitter} = require('events')
linestream = require('line-stream')
shared = require('./shared')

p = __dirname

while not fs.existsSync(path.join(p, 'package.json'))
  p = path.dirname(p)

phantomBin = path.join(p, 'node_modules/phantomjs/bin/phantomjs')
main = path.join(p, 'phantomjs/main.coffee')


class PhantomJS
  constructor: (@child) ->
    @pages = {}
    @port = null


  createPage: (cb) ->
    createCb = (msg) =>
      rv = @pages[msg.pageId] = new Page(msg.pageId, this)
      cb(null, rv)

    @send(type: 'createPage', createCb)


  send: (msg, cb) ->
    data = JSON.stringify(msg)
    json = ''
    url = "http://#{@address}"
    opts =
      hostname: '127.0.0.1'
      port: @port
      path: '/'
      method: 'POST'
      headers:
        'Content-Length': data.length
        'Content-Type': 'application/json'

    req = http.request(opts, (res) =>
      res.setEncoding('utf8')
      res.on('data', (data) =>
        json += data)
      res.on('end', =>
        cb(JSON.parse(json))))

    req.end(data, 'utf8')


  receive: (data) ->
    msg = JSON.parse(data)
    page = @pages[msg.pageId]
    event = msg.event.slice(2)
    event = event.charAt(0).toLowerCase() + event.slice(1)
    if event == 'error'
      msg.args[0] = new Error(msg.args[0])
    page.emit(event, msg.args...)


  close: (cb) ->
    @child.on('close', cb)
    @child.kill('SIGTERM')


class Page extends EventEmitter
  constructor: (@id, @phantomjs) ->


  for method in shared.methods.concat(shared.asyncMethods)
    do (method) =>
      this::[method] = (args..., cb) ->
        callback = (msg) ->
          cb.apply(null, msg.args)

        if @closed
          throw new Error('page already closed')

        if method == 'close'
          @closed = true

        @phantomjs.send(
          type: 'pageMessage'
          pageId: @id
          pageMessageType: 'callMethod'
          name: method
          args: args, callback)


  get: (name, cb) ->
    callback = (msg) ->
      cb.apply(null, msg.args)

    @phantomjs.send(
      type: 'pageMessage'
      pageId: @id
      pageMessageType: 'getProperty'
      name: name, callback)


  set: (name, val, cb) ->
    callback = (msg) ->
      cb.apply(null, msg.args)

    @phantomjs.send(
      type: 'pageMessage'
      pageId: @id
      pageMessageType: 'setProperty'
      val: val
      name: name, callback)


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
    if not instance.port
      instance.port = data
      return cb(null, instance)
    instance.receive(data))
  child.on('error', (err) ->
    if not ready
      ready = true
      return cb(err)
    throw err)


module.exports = phantomjs
