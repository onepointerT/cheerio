###*
# @alias css
# @mixin
###

###*
# Set styles of all elements.
#
# @param {object} el - Element to set style of.
# @param {string|object} prop - Name of property.
# @param {string} val - Value to set property to.
# @param {number} [idx] - Optional index within the selection.
# @returns {self}
# @private
###

setCss = (el, prop, val, idx) ->
  if 'string' == typeof prop
    styles = getCss(el)
    if typeof val == 'function'
      val = val.call(el, idx, styles[prop])
    if val == ''
      delete styles[prop]
    else if val != null
      styles[prop] = val
    el.attribs.style = stringify(styles)
  else if 'object' == typeof prop
    Object.keys(prop).forEach (k) ->
      setCss el, k, prop[k]
      return
  return

###*
# Get parsed styles of the first element.
#
# @param {node} el - Element to get styles from.
# @param {string} prop - Name of the prop.
# @returns {object}
# @private
###

getCss = (el, prop) ->
  if !el or !el.attribs
    return undefined
  styles = parse(el.attribs.style)
  if typeof prop == 'string'
    styles[prop]
  else if Array.isArray(prop)
    _.pick styles, prop
  else
    styles

###*
# Stringify `obj` to styles.
#
# @param {object} obj - Object to stringify.
# @returns {object}
# @private
###

stringify = (obj) ->
  Object.keys(obj or {}).reduce ((str, prop) ->
    str += '' + (if str then ' ' else '') + prop + ': ' + obj[prop] + ';'
  ), ''

###*
# Parse `styles`.
#
# @param {string} styles - Styles to be parsed.
# @returns {object}
# @private
###

parse = (styles) ->
  styles = (styles or '').trim()
  if !styles
    return {}
  styles.split(';').reduce ((obj, str) ->
    n = str.indexOf(':')
    # skip if there is no :, or if it is the first/last character
    if n < 1 or n == str.length - 1
      return obj
    obj[str.slice(0, n).trim()] = str.slice(n + 1).trim()
    obj
  ), {}

exports = exports
# eslint-disable-line no-self-assign
# The preceeding statement is necessary for proper documentation generation.
domEach = require('../utils').domEach
_ = pick: require('lodash/pick')
toString = Object::toString

###*
# Get the value of a style property for the first element in the set of
# matched elements or set one or more CSS properties for every matched
# element.
#
# @param {string|object} prop - The name of the property.
# @param {string} [val] - If specified the new value.
# @returns {self}
#
# @see {@link http://api.jquery.com/css/}
###

exports.css = (prop, val) ->
  if arguments.length == 2 or toString.call(prop) == '[object Object]'
    domEach this, (idx, el) ->
      setCss el, prop, val, idx
      return
  else
    getCss @[0], prop
