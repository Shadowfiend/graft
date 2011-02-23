################################################################################
# Graft                                                                        #
# Templating that doesn't suck... for Node and the browser.                    #
#                                                                              #
# Copyright 2010 Antonio Salazar Cardozo                                       #
# Released under the terms of the MIT License.                                 #
################################################################################

jsdom = require('jsdom')

###
Proposition: my view should be viewable as plain HTML without a browser while
I'm designing/styling it, and data should be bound on top of it as easily as
possible.

Solution: graft.
Props to/superheavy inspiration from: Lift (http://liftweb.net/).

There are several possible usages:

  $('li.template')
    .graft('.author', authorName) // sets .author elements' text to authorName
    .graft('.author',
      $('a')
        .text(authorName)
        .href('link-to-author')) // sets .author elements' html to resulting anchor element
    .graft('.author',
      function($elt) {
        $elt.text(item.creatorName);
      }) // passes the selected elements in for mutation
    .graft('.author',
      {
        '.name': authorName,
        '.link': $('a').text(authorName).href('link-to-author')
      }) // does a graft on each of these sub-elements
    .graft(
      {
        '.author': authorName,
        '.link': $('a').text(authorName).href('link-to-author')
      }) // as above, but searches the top-level object instead of a sub-object

If the graft call is invoked on an element with class `template', it
will clone that element and remove the template class, add the resulting
element to the same container, and then return the new resulting element. If,
on the other hand, the graft call is invoked on an element without that class,
it will operate directly on the element and return it.

-------------
Collections
-------------

For collections of items, we take a similar tack. It would suck to have to use
a double-function for each collection (one for iteration and one for graft), so
we do some goodness:

  $('ul')
    .graft('li.template',
      authors.map(function(author) {
        return {
          '.author': author.name,
          '.link': $('a').text(author.name).href(linkFor(author)),
        }
      })

The mechanism is straightforward: if you pass an array as the second parameter,
the array is checked: if the objects inside it are Functions, each Function is
invoked in turn with a new clone of the matched element(s), then the results
are gathered up and put into the DOM in the matched elements' place. If the
objects inside it are plain-jane vanilla Objects, as above, then each of those
Objects is passed to graft for grafting purposes with a new clone of the
matched element(s), and again the results are gathered and dropped into the
DOM.

The goodness is good, no?

--------------------------
Easily setting attributes
--------------------------

Graft adds just a little bit of bam-bam-bam to selectors:

  $('li.template')
    .graft({
      '.author': author.name,
      '.link[href]': linkFor(author)
    })

This lets us set the href with zero effort. The downside is, the above selector
also means `elements with class link that have an attribute href'. I've found
that is fairly rarely used, but if you still want to use it, just put a space
at the end of the selector:

  $('li.template')
    .graft({
      '.author': author.name,
      '.link[href] ': function($elt) { /* do stuff with the link */ }
    })

We're not *quite* done yet, however. There is also a dash of goodness for
adding to an attribute (particularly handy for classes):

  $('li.template')
    .graft({
      '.author': author.name,
      '.link[class+] ': author.category
    })

###
addGraft = (jQuery) ->
  $ = jQuery
  $.fn.graft = (selector, generators) ->
    $original = $base = this
    if $original.is('.template')
      $base = $base.clone().removeClass('template')

    # If the selector is an object, it means we're grafting sub-selectors of
    # the top-level object.
    if typeof(selector) == 'object'
      $base.graft subselector, generator for subselector, generator of selector
    else
      # Functions get passed the result of the selector.
      if typeof(generators) == 'function'
        generators $base.find(selector)
      # Strings are text for replacing the text of the selector matches.
      else if typeof(generators) == 'string'
        $base.find(selector).text(generators)
      # If we get a jQuery object (identified by the selector property), we
      # replace the selector matches' html contents with that object's
      # contents.
      else if typeof(generators) == 'object' && generators.selector?
        $base.find(selector).html(generators)
      # If we get a non-jQuery object, we just run graft all the properties as
      # selectors with their values as generators.
      else if typeof(generators) == 'object'
        $base.find(selector).graft subselector, generator for subselector, generator of generators

    # If we are a template, append the result to the original template's
    # parent.
    if $original.is('.template')
      $original.parent().append $base

    $base

exports.graft = (html, generators, callback) ->
  window = jsdom.jsdom(html).createWindow()

  try
    jsdom.jQueryify window, "#{__dirname}/jquery-1.4.2.js", ->
      jquery = window.jQuery

      addGraft jquery
      jquery('html').graft generators

      callback null, "<html>#{jquery('html').html()}</html>"
  catch error
    callback error

