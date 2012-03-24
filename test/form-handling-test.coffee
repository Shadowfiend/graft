require './test-helpers.coffee'

require '../lib/graft-forms'

vows
  .describe('Grafting forms')
  .addBatch(
    'Given an HTML template with a form':
      topic: ["""
        <form>
          <label for="name">Name: </label> <input id="name" name="name" class="name" />
          <label for="phone">Phone: </label> <input id="phone" name="phone" class="phone" />
        </form>
        """, {}]

      'when you AJAXify dat sucka':
        topic: ([html, dataHolder]) ->
          graftAndjQueryHtml(
            'form': graft.ajaxify
            'form input[name=name][onsubmit]': (name) -> dataHolder.name = name
          ).call(this, html)

          return

        'then the form should have an action generated': (errors, $html) ->
          assert.match $html.find('form').attr('action'), /^\/graft\/ajax\/G[0-9a-z]{18}$/

        'and the form is submitted':
          topic: ($html, [html, dataHolder]) ->
            action = $html.find('form').attr('action')

            graft.handleAjax()({ url: action, body: { name: 'magic' } }, {}, ->)

            dataHolder

          'then the callbacks should be triggered': (errors, dataHolder) ->
            assert.equal dataHolder.name, 'magic'

  ).export module

