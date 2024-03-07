###global Symbol###

###
  Module dependencies
###

parse = require('./parse')
defaultOptions = require('./options').default
flattenOptions = require('./options').flatten
isHtml = require('./utils').isHtml
_ = 
  extend: require('lodash/assignIn')
  bind: require('lodash/bind')
  forEach: require('lodash/forEach')
  defaults: require('lodash/defaults')

###
# The API
###

api = [
  require('./api/attributes')
  require('./api/traversing')
  require('./api/manipulation')
  require('./api/css')
  require('./api/forms')
]

###*
# Instance of cheerio. Methods are specified in the modules.
# Usage of this constructor is not recommended. Please use $.load instead.
#
# @class
# @hideconstructor
# @param {string|cheerio|node|node[]} selector - The new selection.
# @param {string|cheerio|node|node[]} [context] - Context of the selection.
# @param {string|cheerio|node|node[]} [root] - Sets the root node.
# @param {object} [options] - Options for the instance.
#
# @mixes attributes
# @mixes css
# @mixes forms
# @mixes manipulation
# @mixes traversing
###

Cheerio = 
module.exports = (selector, context, root, options) ->
  if !(this instanceof Cheerio)
    return new Cheerio(selector, context, root, options)
  @options = _.defaults(flattenOptions(options), @options, defaultOptions)
  # $(), $(null), $(undefined), $(false)
  if !selector
    return this
  if root
    if typeof root == 'string'
      root = parse(root, @options, false)
    @_root = Cheerio.call(this, root)
  # $($)
  if selector.cheerio
    return selector
  # $(dom)
  if isNode(selector)
    selector = [ selector ]
  # $([dom])
  if Array.isArray(selector)
    _.forEach selector, _.bind(((elem, idx) ->
      @[idx] = elem
      return
    ), this)
    @length = selector.length
    return this
  # $(<html>)
  if typeof selector == 'string' and isHtml(selector)
    return Cheerio.call(this, parse(selector, @options, false).children)
  # If we don't have a context, maybe we have a root, from loading
  if !context
    context = @_root
  else if typeof context == 'string'
    if isHtml(context)
      # $('li', '<ul>...</ul>')
      context = parse(context, @options, false)
      context = Cheerio.call(this, context)
    else
      # $('li', 'ul')
      selector = [
        context
        selector
      ].join(' ')
      context = @_root
  else if !context.cheerio
    # $('li', node), $('li', [nodes])
    context = Cheerio.call(this, context)
  # If we still don't have a context, return
  if !context
    return this
  # #id, .class, tag
  context.find selector

###
# Set a signature of the object
###

Cheerio::cheerio = '[cheerio object]'

###
# Make cheerio an array-like object
###

Cheerio::length = 0
Cheerio::splice = Array::splice

###
# Make a cheerio object
#
# @private
###

Cheerio::_make = (dom, context) ->
  cheerio = new (@constructor)(dom, context, @_root, @options)
  cheerio.prevObject = this
  cheerio

###*
# Retrieve all the DOM elements contained in the jQuery set as an array.
#
# @example
# $('li').toArray()
# //=> [ {...}, {...}, {...} ]
###

Cheerio::toArray = ->
  @get()

# Support for (const element of $(...)) iteration:
if typeof Symbol != 'undefined'
  Cheerio.prototype[Symbol.iterator] = Array.prototype[Symbol.iterator]
# Plug in the API
api.forEach (mod) ->
  _.extend Cheerio.prototype, mod
  return

isNode = (obj) ->
  obj.name or obj.type == 'text' or obj.type == 'comment'
