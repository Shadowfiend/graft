require.paths.unshift "#{__dirname}/../lib"

vows = require 'vows'
assert = require 'assert'
jsdom = require 'jsdom'
graft = require('graft')
eyes = require('eyes')

# Wrap any HTML in this so that jsdom can set up jquery properly.
htmlize = (body) ->
  """
  <html>
    <body>
      #{body}
    </body>
  </html>
  """

# Takes html, htmlizes it, sets up jsdom, passes the jquery object to the callback.
getjQuery = (html, callback) ->
  window = jsdom.jsdom(htmlize(html)).createWindow()

  jsdom.jQueryify window, "#{__dirname}/../lib/jquery-1.5.js", (window, jquery) ->
    callback jquery

# Takes html, pulls in jquery via getjQuery, and passes any error + the
# jqueryied version of the body tag to its callback.
jqueryify = (html, callback) ->
  getjQuery html, (jquery) ->
    callback null, jquery('body')

# Pass a this reference in a topic. This function will return a callback that
# will take html as its second parameter, then will jqueryify the html, and,
# once this is all finished, will call the topic callback.
#
# Errors are passed through if needed.
jqueryiedHtml = (callback) ->
  (errors, html) ->
    if errors?
      callback errors, html
    else
      jqueryify html, (error, jqueryified) ->
        callback errors, jqueryified

# Pass in a graft generator or generators and set a topic to the result of this
# function. It will invoke graft and jquery the results, passing the jqueryied
# objects to vows as a callback.
graftAndjQueryHtml = (graftGenerators) ->
  (html) ->
    graft.graft htmlize(html), graftGenerators, jqueryiedHtml(this.callback)
    return

# Pass in a callback that will take the jquery object and set a topic to the
# result of this function. The resulting function will invoke the callbcak with
# jQuery and htmlize, take the results, and invoke this.callback with their
# jqueryified version.
withjQueryAndjQueryHtml = (callback) ->
  (html) ->
    graft.withjQuery htmlize(html), (errors, $, htmlize) =>
      jqueryiedHtml(this.callback)(errors, callback($, htmlize))

    return

vows
  .describe('Grafting plain HTML templates')
  .addBatch(
    'Given an HTML template':
      topic: """
        <div class="item">Whazak</div>
        <a class="link" href="booyan">Whazam</a>
        <div class="nested">
          <span class="magic">Boom</span>
        </div>
        """

      'when you graft plain text to an element':
        topic: graftAndjQueryHtml('.item': 'booyan')

        "then that element's text will be set": (errors, $html) ->
          assert.isNull errors
          assert.equal $html.find('.item').text(), 'booyan'

      'when you graft plain text to an attribute':
        topic: graftAndjQueryHtml('.link[href]': '/magic')

        "then that element's attribute will be set": (errors, $html) ->
          assert.isNull errors
          assert.equal $html.find('.link').attr('href'), '/magic'

        "and that element's text will not be set": (errors, $html) ->
          assert.notEqual $html.find('.link').text(), '/magic'

      'when you graft plain text to add to an attribute':
        topic: graftAndjQueryHtml('.item[class+]': 'info')

        "then that element's attribute will have a space and the text appended": (errors, $html) ->
          assert.isNull errors
          assert.equal $html.find('.item').attr('class'), 'item info'

      'when you graft jQueryied HTML to an element':
        topic:
          withjQueryAndjQueryHtml ($, htmlize) =>
            $('html').graft '.magic': $('<a>').text('author').addClass('magic').attr('href', 'link')

            htmlize()

        'then the given element should be replaced with the jQueryied HTML': (errors, $html) ->
          assert.isNull errors

          assert.length $html.find('a.magic'), 1
          assert.equal $html.find('a.magic').text(), 'author'
          assert.equal $html.find('a.magic').attr('href'), 'link'

      'when you graft with a nested object':
        topic: graftAndjQueryHtml(
          '.nested':
            'span': 'hi',
            'span [class]': 'boom'
        )

        "then the nested object should be used to graft the matched element": (errors, $html) ->
          assert.isNull errors

          assert.equal $html.find('.nested span').text(), 'hi'
          assert.equal $html.find('.nested span').attr('class'), 'boom'
  ).export module
