# Graft

**Proposition:** my view should be viewable as plain HTML without a browser while
I'm designing/styling it, and data should be bound on top of it as easily as
possible.

**Solution:** graft.

**Props to/superheavy inspiration from:** [Lift][].
**Also see:** A very similar library from the folks at [nodejitsu][], [weld][].
**Built on:** The awesomeness of [jsdom][] (also from the folks at nodejitsu).

[lift]: http://liftweb.net/
[nodejitsu]: http://nodejitsu.com/
[weld]: https://github.com/hij1nx/weld
[jsdom]: https://github.com/tmpvar/jsdom

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

If the graft call is invoked on an element with class 'template', it
will clone that element and remove the template class, add the resulting
element to the same container, and then return the new resulting element. If,
on the other hand, the graft call is invoked on an element without that class,
it will operate directly on the element and return it.

## Collections

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
each object in the array is passed to graft in turn, each with a new clone of
the matched element(s). Then, these elements are gathred up and put into the
DOM instead of the matched element. This means you provide an array of
functions, if you prefer, or an object, as above, or a string, etc.

The goodness is good, no?

## Easily Setting Attributes

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
        '.link[class+]': author.category
      })

## CoffeeScript

Graft is written in CoffeeScript (though a compiled JS version is included)
because CoffeeScript is kind of gorgeous. It also benefits from CoffeeScript's
prettiness in use. For example:

    $('ul')
      .graft 'li.template', authors.map (author) ->
          '.author, .link': author.name,
          '.link[class+]': author.category
          '.about-me':
            '.avatar[src]': avatarFor(author),
            '.description': author.description

## Node.js

For node.js, the module exports a function that lets you just pass in HTML or
the name of a file containing HTML and run with it. We can use it as follows:

    var graft = require('graft').graft;
    graft('<p>My <a href="place.html">HTML</a></p><div>magic</div>',
      {
        'p a[href]': 'http://google.com',
        'div': 'unicorns!'
      },
      function(errors, grafted) {
        response.send(grafted, { 'Content-Type': 'text/html' }, 200);
      });

