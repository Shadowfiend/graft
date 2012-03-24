graft = require('./graft').graft

pendingRequests = {}

padTo = (length, string) ->
  zeros = length - string.length

  zeroString = ''
  zeroString += '0' for i in [1..zeros]
  "#{zeroString}#{string}"

formEntryAdderFor = (ajaxId) ->
  (fieldName, handlerFn) ->
    holder = pendingRequests[ajaxId][fieldName] || []
    holder.push(handlerFn)
    pendingRequests[ajaxId][fieldName] = holder

graft.ajaxify = ($form) ->
  return unless $form.is('form')

  ajaxId = 'G' + padTo(18, parseInt('0x' + crypto.randomBytes(11).toString(16)).toString(36))

  $form
    .attr('action', "/graft/ajax/#{ajaxId}")
    .data('add-form-entry', formEntryAdderFor(ajaxId))
  pendingRequests[ajaxId] = {}

graft.handleAjax = -> (request, response, next) ->
  url = request.url.split('?')[0]
  match = url.match(/\/graft\/ajax\/([^/]+)/)
  
  if match and match[1] and pendingRequests[match[1]]
    handlers = pendingRequests[match[1]]

    for field, value of request.body
      if handlers[field]
        handler(value) for handler in handlers[field]

  next()

onsubmitLength = "[onsubmit]".length
graft.interceptors.push ($base, selector, generators) ->
  if selector.match(/\[onsubmit\]$/)
    $field = $base.find(selector.substring(0, selector.length - onsubmitLength))
    $form = $field.closest('form')
    addFormEntry = $form.data('add-form-entry')

    if addFormEntry
      addFormEntry($field.attr('name'), generators)
