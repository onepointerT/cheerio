cloneDeepWith = require('lodash/cloneDeepWith')
# HTML Tags
tags = 
  tag: true
  script: true
  style: true

###*
# Check if the DOM element is a tag.
#
# `isTag(type)` includes `<script>` and `<style>` tags.
#
# @param {node} type - DOM node to check.
#
# @private
###

exports.isTag = (type) ->
  if type.type
    type = type.type
  tags[type] or false

###*
# Convert a string to camel case notation.
#
# @param  {string} str - String to be converted.
# @returns {string}      String in camel case notation.
#
# @private
###

exports.camelCase = (str) ->
  str.replace /[_.-](\w|$)/g, (_, x) ->
    x.toUpperCase()

###*
# Convert a string from camel case to "CSS case", where word boundaries are
# described by hyphens ("-") and all characters are lower-case.
#
# @param  {string} str - String to be converted.
# @returns {string}      String in "CSS case".
#
# @private
###

exports.cssCase = (str) ->
  str.replace(/[A-Z]/g, '-$&').toLowerCase()

# Iterate over each DOM element without creating intermediary Cheerio
# instances.
#
# This is indented for use internally to avoid otherwise unnecessary memory
# pressure introduced by _make.

exports.domEach = (cheerio, fn) ->
  i = 0
  len = cheerio.length
  while i < len and fn.call(cheerio, i, cheerio[i]) != false
    ++i
  cheerio

###*
# Create a deep copy of the given DOM structure.
# Sets the parents of the copies of the passed nodes to `null`.
#
# @param {object} dom - The htmlparser2-compliant DOM structure.
# @private
###

exports.cloneDom = (dom) ->
  parents = if 'length' of dom then Array::map.call(dom, ((el) ->
    el.parent
  )) else [ dom.parent ]

  filterOutParent = (node) ->
    if parents.indexOf(node) > -1
      return null
    return

  cloneDeepWith dom, filterOutParent

###
# A simple way to check for HTML strings or ID strings
###

quickExpr = /^(?:[^#<]*(<[\w\W]+>)[^>]*$|#([\w-]*)$)/

###*
# Check if string is HTML.
#
# @param {string} str - String to check.
#
# @private
###

exports.isHtml = (str) ->
  # Faster than running regex, if str starts with `<` and ends with `>`, assume it's HTML
  if str.charAt(0) == '<' and str.charAt(str.length - 1) == '>' and str.length >= 3
    return true
  # Run the regex
  match = quickExpr.exec(str)
  ! !(match and match[1])
