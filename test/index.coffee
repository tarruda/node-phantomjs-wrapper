http = require('http')
path = require('path')
phantomjs = require('../src')


suite =
  '*suiteSetup': (done) ->
    i = 1

    @server = http.createServer((req, res) =>
      if req.url == '/reloadcb'
        res.writeHead(200, 'Content-Type': 'text/html')
        return res.end(
          """
          <html>
            <body>
              <script>
                callPhantom('hi');
              </script>
            </body>
          </html>
          """
        )
      res.writeHead(200, 'Content-Type': 'text/plain')
      res.end((i++).toString()))

    @server.listen(0, '127.0.0.1', =>
      @port = @server.address().port
      phantomjs(debug: false, timeout: 5000, (err, phantom) =>
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
        @page.evaluateJavaScript('(function() { callPhantom({name: "msg"}) })')
      )
    )


  'inject and callback': (done) ->
    @page.open("http://127.0.0.1:#{@port}", (err) =>
      @page.get('plainText', (err, val) =>
        expect(val).to.eql('3')
        @page.on('callback', (msg) =>
          expect(msg).to.deep.eql('Injected script!')
          done())
        injectPath = path.resolve(path.join(__dirname, '../../test/inject.js'))
        @page.injectJs(injectPath, -> )))


  'reload': (done) ->
    i = 0
    @page.on('callback', (msg) =>
      i++
      expect(msg).to.eql('hi')
      if i == 3
        done()
    )
    @page.open("http://127.0.0.1:#{@port}/reloadcb", (err) =>
      # @page.reload(=> @page.reload(-> )))
      @page.reload(=> @page.reload())
    )


run(suite)
