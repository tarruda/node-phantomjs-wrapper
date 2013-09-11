phantomjs = require('../src')


suite =
  '*suiteSetup': (done) ->
    phantomjs((err, phantom) =>
      @phantom = phantom
      done())


  '*suiteTeardown': (done) ->
    @phantom.close(=> done())


  '*setup': (done) ->
    @phantom.createPage((err, page) =>
      @page = page
      done())


  '*teardown': (done) ->
    done()


  'create pages': (done) ->
    expect(@page.id).to.eql(0)
    @phantom.createPage((err, page) =>
      expect(page.id).to.eql(1)
      done())


run(suite)
