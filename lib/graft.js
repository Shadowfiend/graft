(function() {
  var addGraft, jsdom;
  var __hasProp = Object.prototype.hasOwnProperty;
  jsdom = require('jsdom');
  /*
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

  */
  addGraft = function(jQuery) {
    var $;
    $ = jQuery;
    return ($.fn.graft = function(selector, generators) {
      var $base, $original, _ref, attribute, generator, match, strippedSelector, subselector;
      $original = ($base = this);
      if ($original.is('.template')) {
        $base = $base.clone().removeClass('template');
      }
      if (typeof selector === 'object') {
        _ref = selector;
        for (subselector in _ref) {
          if (!__hasProp.call(_ref, subselector)) continue;
          generator = _ref[subselector];
          $base.graft(subselector, generator);
        }
      } else {
        switch (typeof generators) {
          case 'function':
            generators($base.find(selector));
            break;
          case 'string' || 'number':
            match = null;
            if (match = /(.*)\[([^\]]+)\]$/.exec(selector)) {
              _ref = match.slice(1);
              strippedSelector = _ref[0];
              attribute = _ref[1];
              if (attribute[-1] === '+') {
                attribute = attribute.slice(0, -1 + 1);
                $base.find(strippedSelector).each(function(elt) {
                  return $(elt).attr(attribute, "" + ($(elt).attr(attribute)) + " " + (generators));
                });
              } else {
                $base.find(strippedSelector).attr(attribute, generators);
              }
            } else {
              $base.find(selector).text(generators);
            }
            break;
          case 'object':
            if (typeof (_ref = generators.selector) !== "undefined" && _ref !== null) {
              $base.find(selector).html(generators);
            } else if (typeof (_ref = generators.map) !== "undefined" && _ref !== null) {
              generators.map(function(generator) {
                var generatorType;
                generatorType = typeof generator;
                if (generatorType === 'object') {
                  return ($base = $base.clone().graft(generator));
                } else if (generatorType === 'string' || generatorType === 'number') {
                  return ($base = $base.clone().text(generator));
                } else if (generatorType === 'function') {
                  return ($base = $base.each(generator));
                }
              });
            } else {
              _ref = generators;
              for (subselector in _ref) {
                if (!__hasProp.call(_ref, subselector)) continue;
                generator = _ref[subselector];
                $base.find(selector).graft(subselector, generator);
              }
            }
            break;
        }
      }
      if ($original.is('.template')) {
        $original.parent().append($base);
      }
      return $base;
    });
  };
  exports.graft = function(html, generators, callback) {
    var window;
    window = jsdom.jsdom(html).createWindow();
    try {
      return jsdom.jQueryify(window, "" + (__dirname) + "/jquery-1.5.0.js", function() {
        var jquery;
        jquery = window.jQuery;
        addGraft(jquery);
        jquery('html').graft(generators);
        return callback(null, "<html>" + (jquery('html').html()) + "</html>");
      });
    } catch (error) {
      return callback(error);
    }
  };
}).call(this);
