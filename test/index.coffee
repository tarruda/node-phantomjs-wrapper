http = require('http')
path = require('path')
phantomjs = require('../src')


suite =
  '*suiteSetup': (done) ->
    i = 1

    @server = http.createServer((req, res) =>
      res.writeHead(200, 'Content-Type': 'text/plain')
      res.end((i++).toString()))

    @server.listen(0, '127.0.0.1', =>
      @port = @server.address().port
      phantomjs((err, phantom) =>
        @phantom = phantom
        done()))


  '*suiteTeardown': (done) ->
    @phantom.close(=>
      @server.close(=>
        done()))


  '*setup': (done) ->
    @phantom.createPage((err, page) =>
      @page = page
      done())


  '*teardown': (done) ->
    @page.close(done)


  'create pages': (done) ->
    expect(@page.id).to.eql(0)
    @phantom.createPage((err, page) =>
      expect(page.id).to.eql(1)
      page.close(done))


  'open urls': (done) ->
    @page.open("http://127.0.0.1:#{@port}", (err) =>
      @page.get('plainText', (err, val) =>
        expect(val).to.eql('1')
        done()))


  'evaluate and callback': (done) ->
    @page.open("http://127.0.0.1:#{@port}", (err) =>
      @page.get('plainText', (err, val) =>
        expect(val).to.eql('2')
        @page.on('callback', (msg) =>
          expect(msg).to.deep.eql(name: 'msg')
          done())
        @page.evaluateJavaScript(
          '(function() { callPhantom({name: "msg"}) })', -> )))


run(suite)
