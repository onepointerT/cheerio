htmlparser2Adapter = require('parse5-htmlparser2-tree-adapter')

###*
# @alias static
# @mixin
# @ignore
###

###
# Helper function
###

render = (that, dom, options) ->
  if !dom
    if that._root and that._root.children
      dom = that._root.children
    else
      return ''
  else if typeof dom == 'string'
    dom = select(dom, that._root, options)
  if options.xmlMode or options._useHtmlParser2
    return serialize(dom, options)
  # `dom-serializer` passes over the special "root" node and renders the
  # node's children in its place. To mimic this behavior with `parse5`, an
  # equivalent operation must be applied to the input array.
  nodes = if 'length' of dom then dom else [ dom ]
  index = 0
  while index < nodes.length
    if nodes[index].type == 'root'
      nodes.splice.apply nodes, [
        index
        1
      ].concat(nodes[index].children)
    index += 1
  parse5.serialize { children: nodes }, treeAdapter: htmlparser2Adapter

isArrayLike = (item) ->
  if Array.isArray(item)
    return true
  if typeof item != 'object'
    return false
  if !Object::hasOwnProperty.call(item, 'length')
    return false
  if typeof item.length != 'number'
    return false
  if item.length < 0
    return false
  i = 0
  while i < item.length
    if !(i of item)
      return false
    i++
  true

exports = exports
# eslint-disable-line no-self-assign
# The preceeding statement is necessary for proper documentation generation.
serialize = require('dom-serializer')
defaultOptions = require('./options').default
flattenOptions = require('./options').flatten
select = require('css-select')
parse5 = require('parse5')
parse = require('./parse')
_ = 
  merge: require('lodash/merge')
  defaults: require('lodash/defaults')

###*
# Create a querying function, bound to a document created from the provided
# markup. Note that similar to web browser contexts, this operation may
# introduce `<html>`, `<head>`, and `<body>` elements. See the previous
# section titled "Loading" for usage information.
#
# @param {string} content - Markup to be loaded.
# @param {object} [options] - Options for the created instance.
# @param {boolean} [isDocument] - Allows parser to be switched to fragment mode.
#
###

exports.load = (content, options, isDocument) ->
  if content == null or content == undefined
    throw new Error('cheerio.load() expects a string')
  Cheerio = require('./cheerio')
  options = _.defaults(flattenOptions(options or {}), defaultOptions)
  if isDocument == undefined
    isDocument = true
  root = parse(content, options, isDocument)

  initialize = (selector, context, r, opts) ->
    if !(this instanceof initialize)
      return new initialize(selector, context, r, opts)
    opts = _.defaults(opts or {}, options)
    Cheerio.call this, selector, context, r or root, opts

  # Ensure that selections created by the "loaded" `initialize` function are
  # true Cheerio instances.
  initialize.prototype = Object.create(Cheerio.prototype)
  initialize::constructor = initialize
  # Mimic jQuery's prototype alias for plugin authors.
  initialize.fn = initialize.prototype
  # Keep a reference to the top-level scope so we can chain methods that implicitly
  # resolve selectors; e.g. $("<span>").(".bar"), which otherwise loses ._root
  initialize::_originalRoot = root
  # Add in the static methods
  _.merge initialize, exports
  # Add in the root
  initialize._root = root
  # store options
  initialize._options = options
  initialize

###*
# Renders the document.
#
# @param {string|cheerio|node} [dom] - Element to render.
# @param {object} [options] - Options for the renderer.
###

exports.html = (dom, options) ->
  # be flexible about parameters, sometimes we call html(),
  # with options as only parameter
  # check dom argument for dom element specific properties
  # assume there is no 'length' or 'type' properties in the options object
  if Object::toString.call(dom) == '[object Object]' and !options and !('length' of dom) and !('type' of dom)
    options = dom
    dom = undefined
  # sometimes $.html() used without preloading html
  # so fallback non existing options to the default ones
  options = _.defaults(flattenOptions(options or {}), @_options, defaultOptions)
  render this, dom, options

###*
# Render the document as XML.
#
# @param {string|cheerio|node} [dom] - Element to render.
###

exports.xml = (dom) ->
  options = _.defaults({ xml: true }, @_options)
  render this, dom, options

###*
# Render the document as text.
#
# @param {string|cheerio|node} [elems] - Elements to render.
###

exports.text = (elems) ->
  if !elems
    elems = @root()
  ret = ''
  len = elems.length
  elem = undefined
  i = 0
  while i < len
    elem = elems[i]
    if elem.type == 'text'
      ret += elem.data
    else if elem.children and elem.type != 'comment' and elem.tagName != 'script' and elem.tagName != 'style'
      ret += exports.text(elem.children)
    i++
  ret

###*
# Parses a string into an array of DOM nodes. The `context` argument has no
# meaning for Cheerio, but it is maintained for API compatibility with jQuery.
#
# @param {string} data - Markup that will be parsed.
# @param {any|boolean} [context] - Will be ignored. If it is a boolean it will be used as the value of `keepScripts`.
# @param {boolean} [keepScripts] - If false all scripts will be removed.
#
# @alias Cheerio.parseHTML
# @see {@link https://api.jquery.com/jQuery.parseHTML/}
###

exports.parseHTML = (data, context, keepScripts) ->
  parsed = undefined
  if !data or typeof data != 'string'
    return null
  if typeof context == 'boolean'
    keepScripts = context
  parsed = @load(data, defaultOptions, false)
  if !keepScripts
    parsed('script').remove()
  # The `children` array is used by Cheerio internally to group elements that
  # share the same parents. When nodes created through `parseHTML` are
  # inserted into previously-existing DOM structures, they will be removed
  # from the `children` array. The results of `parseHTML` should remain
  # constant across these operations, so a shallow copy should be returned.
  parsed.root()[0].children.slice()

###*
# Sometimes you need to work with the top-level root element. To query it, you
# can use `$.root()`.
#
# @alias Cheerio.root
#
# @example
# ```js
# $.root().append('<ul id="vegetables"></ul>').html();
# //=> <ul id="fruits">...</ul><ul id="vegetables"></ul>
# ```
###

exports.root = ->
  this @_root

###*
# Checks to see if the `contained` DOM element is a descendant of the
# `container` DOM element.
#
# @param {node} container - Potential parent node.
# @param {node} contained - Potential child node.
#
# @alias Cheerio.contains
# @see {@link https://api.jquery.com/jQuery.contains}
###

exports.contains = (container, contained) ->
  # According to the jQuery API, an element does not "contain" itself
  if contained == container
    return false
  # Step up the descendants, stopping when the root element is reached
  # (signaled by `.parent` returning a reference to the same object)
  while contained and contained != contained.parent
    contained = contained.parent
    if contained == container
      return true
  false

###*
# $.merge().
#
# @param {Array|cheerio} arr1 - First array.
# @param {Array|cheerio} arr2 - Second array.
#
# @alias Cheerio.merge
# @see {@link https://api.jquery.com/jQuery.merge}
###

exports.merge = (arr1, arr2) ->
  if !(isArrayLike(arr1) and isArrayLike(arr2))
    return
  newLength = arr1.length + arr2.length
  i = 0
  while i < arr2.length
    arr1[i + arr1.length] = arr2[i]
    i++
  arr1.length = newLength
  arr1
