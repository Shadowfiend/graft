vows = require 'vows'
assert = require 'assert'
jsdom = require 'jsdom'
graft = require('graft').graft
eyes = require('eyes')

jqueryify = (html, callback) ->
  window = jsdom.jsdom(html).createWindow()
  jsdom.jQueryify window, "#{__dirname}/../lib/jquery-1.4.2.js", (window, jquery) ->
    jquery = window.jQuery

    callback null, jquery('body')

# Pass a this reference in a topic. This function will return a callback that
# will take html as its second parameter, then will jqueryify the html, and,
# once this is all finished, will call the topic callback.
#
# Errors are passed through if needed.
jqueryiedHtml = (vow) ->
  (errors, html) ->
    if errors?
      vow.callback errors, html
    else
      jqueryify html, (error, jquery) ->
        vow.callback errors, jquery

# Wrap any HTML in this so that jsdom can set up jquery properly.
htmlize = (body) ->
  """
  <html>
    <body>
      #{body}
    </body>
  </html>
  """

# Pass in a graft generator or generators and set a topic to this. It will
# invoke graft and jquery the results, passing the jqueryied objects to vows as
# a callback.
graftAndjQueryHtml = (graftGenerators) ->
  (html) ->
    graft html, graftGenerators, jqueryiedHtml(this)
    return

vows
  .describe('Grafting plain HTML templates')
  .addBatch(
    'Given an HTML template':
      topic: htmlize("""
        <div class="item">Whazak</div>
        <a class="link" href="booyan">Whazam</a>
        """)

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
  ).export module
