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
    .graft({
      '.author': author.name,
      '.link[href]': linkFor(author) // sets the href attribute
      '.link[class+] ': author.category // adds the category to the class attribute
      '.other-link[target] ': 'EXTERNAL' // targets other-links with a target attribute (note space at the end)
      '.other-link[target=_blank]': 'new window' // targets other-links with a target attribute _blank
    })

If the graft call is invoked on an element with class `template', it
will clone that element and remove the template class, add the resulting
element to the same container, and then return the new resulting element. If,
on the other hand, the graft call is invoked on an element without that class,
it will operate directly on the element and return it.

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

###
addGraft = (jQuery) ->
  $ = jQuery
  $.fn.graft = (selector, generators) ->
    $original = $base = this
    if $original.is('.template')
      $base = $base.clone().removeClass('template')

    # If the selector is an object, it means we're grafting sub-selectors of
    # the top-level object.
    if typeof selector == 'object'
      $base.graft subselector, generator for subselector, generator of selector
    else
      switch typeof generators
        # Functions get passed the result of the selector.
        when 'function'
          generators $base.find(selector)
        # Strings are text for replacing the text of the selector matches.
        when 'string' or 'number'
          match = null
          if match = /(.*)\[([^\]]+)\]$/.exec(selector)
            [strippedSelector, attribute] = match[1..]

            if attribute[-1] == '+'
              attribute = attribute[0..-1]

              $base
                .find(strippedSelector)
                .each (elt) -> $(elt).attr(attribute, "#{$(elt).attr(attribute)} #{generators}")
            else
              $base.find(strippedSelector).attr(attribute, generators)
          else
            $base.find(selector).text(generators)
        when 'object'
          # If we get a jQuery object (identified by the selector property), we
          # replace the selector matches' html contents with that object's
          # contents.
          if generators.selector?
            $base.find(selector).html(generators)
          # If we get an array, identified by a map property, we iterate
          # through it, grafting its components to clones of the base, then
          # returning them as one group.
          # FIXME This will cause issues in older browsers.
          else if generators.map?
            generators.map (generator) ->
              generatorType = typeof generator
              if generatorType == 'object'
                $base = $base.clone().graft generator
              else if generatorType == 'string' || generatorType == 'number'
                $base = $base.clone().text generator
              else if generatorType == 'function'
                $base = $base.each generator

          # If we get a non-jQuery object, we just run graft all the properties as
          # selectors with their values as generators.
          else
            $base.find(selector).graft subselector, generator for subselector, generator of generators

    # If we are a template, append the result to the original template's
    # parent.
    if $original.is('.template')
      $original.parent().append $base

    $base

exports.graft = (html, generators, callback) ->
  window = jsdom.jsdom(html).createWindow()

  try
    jsdom.jQueryify window, "#{__dirname}/jquery-1.5.0.js", ->
      jquery = window.jQuery

      addGraft jquery
      jquery('html').graft generators

      callback null, "<html>#{jquery('html').html()}</html>"
  catch error
    callback error

