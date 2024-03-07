assign = require('lodash/assign')

###
# Cheerio default options
###

exports.default =
  withDomLvl1: true
  normalizeWhitespace: false
  xml: false
  decodeEntities: true

exports.flatten = (options) ->
  if options and options.xml then assign({ xmlMode: true }, options.xml) else options
