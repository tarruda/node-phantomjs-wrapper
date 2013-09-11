system = require('system')
webpage = require('webpage')
shared = require('./shared')


log = (msg) ->
  system.stdout.writeLine(msg)


pages = []


class Page

  methods = {}

  for method in shared.methods
    methods[method] = true

  asyncMethods = {}

  for method in shared.asyncMethods
    asyncMethods[method] = true


  constructor: (requestId) ->
    @id = pages.length
    @page = webpage.create()
    pages.push(this)
    send(type: 'pageCreate', pageId: @id, requestId: requestId)
    for event in shared.events
      do (event) =>
        @page[event] = (args...) =>
          send(type: 'pageEvent', pageId: @id, event: event, args: args)


  getProperty: (requestId, name) ->
    val = @page[name]
    send(type: 'pagePropertyGet', requestId: requestId)


  setProperty: (requestId, name, val) ->
    msg = type: 'pagePropertySet', requestId: requestId

    try
      @page[name] = val
      msg.status = 'ok'
    catch e
      msg.status = 'error'
      msg.error = e.message

    send(msg)


  callMethod: (requestId, name, args) ->
    cb = (args...) =>
      if args[0] then args[0] = args[0].message
      send(type: 'pageMethodCallback', requestId: requestId, args: args)

    if name of methods
      try
        rv = @page[name].apply(@page, args)
        cb(null, rv)
      catch e
        cb(e)
    else if name of asyncMethods
      args.unshift(cb)
      @page[name].apply(@page, args)


  send: (message) ->
    switch message.pageMessageType
      when 'callMethod'
        @callMethod(message.requestId, message.name, message.args)
      when 'getProperty'
        @getProperty(message.requestId, message.name)
      when 'setProperty'
        @setProperty(message.requestId, message.name, message.val)



send = (message) ->
  message = JSON.stringify(message)
  system.stderr.write(message + '\n')


read = ->
  message = system.stdin.readLine()

  try
    return JSON.parse(message)
  catch e
    log("#{e.message}(#{message})")
    phantom.exit()


system.stderr.writeLine('ready')


while 1
  message = read()

  switch message.type
    when 'createPage'
      new Page(message.requestId)
    when 'pageMessage'
      pages[message.pageId].send(message)
