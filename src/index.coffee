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


instances = []


process.on('exit', ->
  for instance in instances
    instance.close(-> )
)


class PhantomJS extends EventEmitter
  constructor: (@child) ->
    instances.push(this)
    @pages = {}
    @port = null
    @closed = false


  createPage: (cb) ->
    if @closed then throw new Error('phantomjs instance already closed')
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

    req.on('error', (e) =>
      if e.message.match(/ECONNREFUSED|ECONNRESET/)
        return # ignore, probably phantom timed out
      throw e
    )

    req.end(data, 'utf8')


  receive: (data) ->
    msg = JSON.parse(data)
    if msg.type == 'phantomTimeout'
      return @close(-> )
    page = @pages[msg.pageId]
    event = msg.event.slice(2)
    event = event.charAt(0).toLowerCase() + event.slice(1)
    if event == 'error'
      msg.args[0] = new Error(msg.args[0])
    page.emit(event, msg.args...)


  close: (cb) ->
    @closed = true
    @emit('closed')
    @child.on('close', cb)
    @child.kill('SIGTERM')
    idx = instances.indexOf(this)
    instances.splice(idx, 1)


class Page extends EventEmitter
  constructor: (@id, @phantomjs) ->

  for method in shared.methods.concat(shared.asyncMethods)
    do (method) =>
      this::[method] = (args...) ->
        cb = null

        callback = (msg) ->
          if cb
            cb.apply(null, msg.args)

        if typeof args[args.length - 1] == 'function'
          cb = args.pop()

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
      if typeof cb == 'function'
        cb.apply(null, msg.args)

    @phantomjs.send(
      type: 'pageMessage'
      pageId: @id
      pageMessageType: 'setProperty'
      val: val
      name: name, callback)


phantomjs = (options, cb) ->
  timeout = 20000
  debug = false
  binPath = phantomBin

  if options
    if typeof options == 'function'
      cb = option
    else
      if options.timeout
        timeout = options.timeout
      if options.binPath
        binPath = options.binPath
      debug = options.debug

  options = JSON.stringify(timeout: timeout, debug: debug)
  args = [main]
  stdout = 'ignore'
  if debug
    stdout = process.stdout
  opts = stdio: ['pipe', stdout, 'pipe']
  child = spawn(binPath, args, opts)
  child.stdin.write("#{options}\n", 'utf8')
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
