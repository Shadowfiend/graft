graft = require('./graft').graft
rbytes = require('rbytes')

padTo = (length, string) ->
  zeros = length - string.length

  zeroString = ''
  zeroString += '0' for i in [1..zeros]
  "#{zeroString}#{string}"

graft.ajaxify = ($form) ->
  return unless $form.is('form')

  ajaxId = padTo(18, parseInt('0x' + rbytes.randomBytes(11).toHex()).toString(36))

  $form.attr 'action', "/graft/ajax/G#{ajaxId}"

