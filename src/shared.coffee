exports.events = ['onAlert', 'onCallback', 'onClosing', 'onConfirm',
  'onConsoleMessage', 'onError', 'onFilePicker', 'onInitialized',
  'onLoadFinished', 'onLoadStarted', 'onNavigationRequested',
  'onPageCreated', 'onPrompt', 'onResourceRequested', 'onResourceReceived',
  'onResourceError', 'onUrlChanged'
]


exports.methods = [
  'addCookie', 'clearCookies', 'close', 'deleteCookie',
  'evaluateJavaScript', 'go', 'goBack', 'goForward', 'openUrl', 'injectJs',
  'reload', 'render', 'renderBase64', 'sendEvent', 'setContent', 'uploadFile'
]


exports.asyncMethods = [
  'includeJs', 'injectJs', 'open'
]
