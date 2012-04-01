#require.paths.unshift "#{__dirname}/../lib"

global.vows = require 'vows'
global.assert = require 'assert'
global.jsdom = require 'jsdom'
global.graft = require('../lib/graft').graft
global.eyes = require('eyes')

# Wrap any HTML in this so that jsdom can set up jquery properly.
global.htmlize = (body) ->
  """
  <html>
    <body>
      #{body}
    </body>
  </html>
  """

# Takes html, htmlizes it, sets up jsdom, passes the jquery object to the callback.
global.getjQuery = (html, callback) ->
  window = jsdom.jsdom(htmlize(html)).createWindow()

  jsdom.jQueryify window, "#{__dirname}/../lib/jquery-1.7.2.js", (window, jquery) ->
    callback jquery

# Takes html, pulls in jquery via getjQuery, and passes any error + the
# jqueryied version of the body tag to its callback.
global.jqueryify = (html, callback) ->
  getjQuery html, (jquery) ->
    callback null, jquery('body')

# Pass a this reference in a topic. This function will return a callback that
# will take html as its second parameter, then will jqueryify the html, and,
# once this is all finished, will call the topic callback.
#
# Errors are passed through if needed.
global.jqueryiedHtml = (callback) ->
  (errors, html) ->
    if errors?
      callback errors, html
    else
      jqueryify html, (error, jqueryified) ->
        callback errors, jqueryified

# Pass in a graft generator or generators and set a topic to the result of this
# function. It will invoke graft and jquery the results, passing the jqueryied
# objects to vows as a callback.
global.graftAndjQueryHtml = (graftGenerators) ->
  (html) ->
    graft htmlize(html), graftGenerators, jqueryiedHtml(this.callback)
    return

# Pass in a callback that will take the jquery object and set a topic to the
# result of this function. The resulting function will invoke the callbcak with
# jQuery and htmlize, take the results, and invoke this.callback with their
# jqueryified version.
global.withjQueryAndjQueryHtml = (callback) ->
  (html) ->
    graft.withjQuery htmlize(html), (errors, $, htmlize) =>
      jqueryiedHtml(this.callback)(errors, callback($, htmlize))

    return

