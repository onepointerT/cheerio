###*
# Methods for modifying the DOM structure.
#
# @alias manipulation
# @mixin
###

exports = exports
# eslint-disable-line no-self-assign
# The preceeding statement is necessary for proper documentation generation.
parse = require('../parse')
html = require('../static').html
text = require('../static').text
updateDOM = parse.update
evaluate = parse.evaluate
utils = require('../utils')
domEach = utils.domEach
cloneDom = utils.cloneDom
isHtml = utils.isHtml
slice = Array::slice
_ = 
  flatten: require('lodash/flatten')
  bind: require('lodash/bind')
  forEach: require('lodash/forEach')

###*
# Create an array of nodes, recursing into arrays and parsing strings if
# necessary.
#
# @param {cheerio|string|cheerio[]|string[]} [elem] - Elements to make an array of.
# @param {boolean} [clone] - Optionally clone nodes.
# @private
###

exports._makeDomArray = (elem, clone) ->
  if elem == null
    []
  else if elem.cheerio
    if clone then cloneDom(elem.get(), elem.options) else elem.get()
  else if Array.isArray(elem)
    _.flatten elem.map(((el) ->
      @_makeDomArray el, clone
    ), this)
  else if typeof elem == 'string'
    evaluate elem, @options, false
  else
    if clone then cloneDom([ elem ]) else [ elem ]

_insert = (concatenator) ->
  ->
    elems = slice.call(arguments)
    lastIdx = @length - 1
    domEach this, (i, el) ->
      dom = undefined
      domSrc = undefined
      if typeof elems[0] == 'function'
        domSrc = elems[0].call(el, i, html(el.children))
      else
        domSrc = elems
      dom = @_makeDomArray(domSrc, i < lastIdx)
      concatenator dom, el.children, el
      return

###
# Modify an array in-place, removing some number of elements and adding new
# elements directly following them.
#
# @param {Array} array Target array to splice.
# @param {Number} spliceIdx Index at which to begin changing the array.
# @param {Number} spliceCount Number of elements to remove from the array.
# @param {Array} newElems Elements to insert into the array.
#
# @private
###

uniqueSplice = (array, spliceIdx, spliceCount, newElems, parent) ->
  spliceArgs = [
    spliceIdx
    spliceCount
  ].concat(newElems)
  prev = array[spliceIdx - 1] or null
  next = array[spliceIdx] or null
  idx = undefined
  len = undefined
  prevIdx = undefined
  node = undefined
  oldParent = undefined
  # Before splicing in new elements, ensure they do not already appear in the
  # current array.
  idx = 0
  len = newElems.length
  while idx < len
    node = newElems[idx]
    oldParent = node.parent or node.root
    prevIdx = oldParent and oldParent.children.indexOf(newElems[idx])
    if oldParent and prevIdx > -1
      oldParent.children.splice prevIdx, 1
      if parent == oldParent and spliceIdx > prevIdx
        spliceArgs[0]--
    node.root = null
    node.parent = parent
    if node.prev
      node.prev.next = node.next or null
    if node.next
      node.next.prev = node.prev or null
    node.prev = newElems[idx - 1] or prev
    node.next = newElems[idx + 1] or next
    ++idx
  if prev
    prev.next = newElems[0]
  if next
    next.prev = newElems[newElems.length - 1]
  array.splice.apply array, spliceArgs

###*
# Insert every element in the set of matched elements to the end of the
# target.
#
# @param {string|cheerio} target - Element to append elements to.
#
# @example
#
# $('<li class="plum">Plum</li>').appendTo('#fruits')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //      <li class="plum">Plum</li>
# //    </ul>
#
# @see {@link http://api.jquery.com/appendTo/}
###

exports.appendTo = (target) ->
  if !target.cheerio
    target = @constructor.call(@constructor, target, null, @_originalRoot)
  target.append this
  this

###*
# Insert every element in the set of matched elements to the beginning of the
# target.
#
# @param {string|cheerio} target - Element to prepend elements to.
#
# @example
#
# $('<li class="plum">Plum</li>').prependTo('#fruits')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="plum">Plum</li>
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //    </ul>
#
# @see {@link http://api.jquery.com/prependTo/}
###

exports.prependTo = (target) ->
  if !target.cheerio
    target = @constructor.call(@constructor, target, null, @_originalRoot)
  target.prepend this
  this

###*
# Inserts content as the *last* child of each of the selected elements.
#
# @method
#
# @example
#
# $('ul').append('<li class="plum">Plum</li>')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //      <li class="plum">Plum</li>
# //    </ul>
#
# @see {@link http://api.jquery.com/append/}
###

exports.append = _insert((dom, children, parent) ->
  uniqueSplice children, children.length, 0, dom, parent
  return
)

###*
# Inserts content as the *first* child of each of the selected elements.
#
# @method
#
# @example
#
# $('ul').prepend('<li class="plum">Plum</li>')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="plum">Plum</li>
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //    </ul>
#
# @see {@link http://api.jquery.com/prepend/}
###

exports.prepend = _insert((dom, children, parent) ->
  uniqueSplice children, 0, 0, dom, parent
  return
)

###*
# The .wrap() function can take any string or object that could be passed to
# the $() factory function to specify a DOM structure. This structure may be
# nested several levels deep, but should contain only one inmost element. A
# copy of this structure will be wrapped around each of the elements in the
# set of matched elements. This method returns the original set of elements
# for chaining purposes.
#
# @param {cheerio} wrapper - The DOM structure to wrap around each element in the selection.
#
# @example
#
# const redFruit = $('<div class="red-fruit"></div>')
# $('.apple').wrap(redFruit)
#
# //=> <ul id="fruits">
# //     <div class="red-fruit">
# //      <li class="apple">Apple</li>
# //     </div>
# //     <li class="orange">Orange</li>
# //     <li class="plum">Plum</li>
# //   </ul>
#
# const healthy = $('<div class="healthy"></div>')
# $('li').wrap(healthy)
#
# //=> <ul id="fruits">
# //     <div class="healthy">
# //       <li class="apple">Apple</li>
# //     </div>
# //     <div class="healthy">
# //       <li class="orange">Orange</li>
# //     </div>
# //     <div class="healthy">
# //        <li class="plum">Plum</li>
# //     </div>
# //   </ul>
#
# @see {@link http://api.jquery.com/wrap/}
###

exports.wrap = (wrapper) ->
  wrapperFn = typeof wrapper == 'function' and wrapper
  lastIdx = @length - 1
  _.forEach this, _.bind(((el, i) ->
    parent = el.parent or el.root
    siblings = parent.children
    wrapperDom = undefined
    elInsertLocation = undefined
    j = undefined
    index = undefined
    if !parent
      return
    if wrapperFn
      wrapper = wrapperFn.call(el, i)
    if typeof wrapper == 'string' and !isHtml(wrapper)
      wrapper = @parents().last().find(wrapper).clone()
    wrapperDom = @_makeDomArray(wrapper, i < lastIdx).slice(0, 1)
    elInsertLocation = wrapperDom[0]
    # Find the deepest child. Only consider the first tag child of each node
    # (ignore text); stop if no children are found.
    j = 0
    while elInsertLocation and elInsertLocation.children
      if j >= elInsertLocation.children.length
        break
      if elInsertLocation.children[j].type == 'tag'
        elInsertLocation = elInsertLocation.children[j]
        j = 0
      else
        j++
    index = siblings.indexOf(el)
    updateDOM [ el ], elInsertLocation
    # The previous operation removed the current element from the `siblings`
    # array, so the `dom` array can be inserted without removing any
    # additional elements.
    uniqueSplice siblings, index, 0, wrapperDom, parent
    return
  ), this)
  this

###*
# Insert content next to each element in the set of matched elements.
#
# @example
#
# $('.apple').after('<li class="plum">Plum</li>')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="apple">Apple</li>
# //      <li class="plum">Plum</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //    </ul>
#
# @see {@link http://api.jquery.com/after/}
###

exports.after = ->
  elems = slice.call(arguments)
  lastIdx = @length - 1
  domEach this, (i, el) ->
    parent = el.parent or el.root
    if !parent
      return
    siblings = parent.children
    index = siblings.indexOf(el)
    domSrc = undefined
    dom = undefined
    # If not found, move on
    if index < 0
      return
    if typeof elems[0] == 'function'
      domSrc = elems[0].call(el, i, html(el.children))
    else
      domSrc = elems
    dom = @_makeDomArray(domSrc, i < lastIdx)
    # Add element after `this` element
    uniqueSplice siblings, index + 1, 0, dom, parent
    return
  this

###*
# Insert every element in the set of matched elements after the target.
#
# @example
#
# $('<li class="plum">Plum</li>').insertAfter('.apple')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="apple">Apple</li>
# //      <li class="plum">Plum</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //    </ul>
#
# @param {string|cheerio} target - Element to insert elements after.
#
# @see {@link http://api.jquery.com/insertAfter/}
###

exports.insertAfter = (target) ->
  clones = []
  self = this
  if typeof target == 'string'
    target = @constructor.call(@constructor, target, null, @_originalRoot)
  target = @_makeDomArray(target)
  self.remove()
  domEach target, (i, el) ->
    clonedSelf = self._makeDomArray(self.clone())
    parent = el.parent or el.root
    if !parent
      return
    siblings = parent.children
    index = siblings.indexOf(el)
    # If not found, move on
    if index < 0
      return
    # Add cloned `this` element(s) after target element
    uniqueSplice siblings, index + 1, 0, clonedSelf, parent
    clones.push clonedSelf
    return
  @constructor.call @constructor, @_makeDomArray(clones)

###*
# Insert content previous to each element in the set of matched elements.
#
# @example
#
# $('.apple').before('<li class="plum">Plum</li>')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="plum">Plum</li>
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //    </ul>
#
# @see {@link http://api.jquery.com/before/}
###

exports.before = ->
  elems = slice.call(arguments)
  lastIdx = @length - 1
  domEach this, (i, el) ->
    parent = el.parent or el.root
    if !parent
      return
    siblings = parent.children
    index = siblings.indexOf(el)
    domSrc = undefined
    dom = undefined
    # If not found, move on
    if index < 0
      return
    if typeof elems[0] == 'function'
      domSrc = elems[0].call(el, i, html(el.children))
    else
      domSrc = elems
    dom = @_makeDomArray(domSrc, i < lastIdx)
    # Add element before `el` element
    uniqueSplice siblings, index, 0, dom, parent
    return
  this

###*
# Insert every element in the set of matched elements before the target.
#
# @example
#
# $('<li class="plum">Plum</li>').insertBefore('.apple')
# $.html()
# //=>  <ul id="fruits">
# //      <li class="plum">Plum</li>
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //      <li class="pear">Pear</li>
# //    </ul>
#
# @param {string|cheerio} target - Element to insert elements before.
#
# @see {@link http://api.jquery.com/insertBefore/}
###

exports.insertBefore = (target) ->
  clones = []
  self = this
  if typeof target == 'string'
    target = @constructor.call(@constructor, target, null, @_originalRoot)
  target = @_makeDomArray(target)
  self.remove()
  domEach target, (i, el) ->
    clonedSelf = self._makeDomArray(self.clone())
    parent = el.parent or el.root
    if !parent
      return
    siblings = parent.children
    index = siblings.indexOf(el)
    # If not found, move on
    if index < 0
      return
    # Add cloned `this` element(s) after target element
    uniqueSplice siblings, index, 0, clonedSelf, parent
    clones.push clonedSelf
    return
  @constructor.call @constructor, @_makeDomArray(clones)

###*
# Removes the set of matched elements from the DOM and all their children.
# `selector` filters the set of matched elements to be removed.
#
# @example
#
# $('.pear').remove()
# $.html()
# //=>  <ul id="fruits">
# //      <li class="apple">Apple</li>
# //      <li class="orange">Orange</li>
# //    </ul>
#
# @param {string} [selector] - Optional selector for elements to remove.
#
# @see {@link http://api.jquery.com/remove/}
###

exports.remove = (selector) ->
  elems = this
  # Filter if we have selector
  if selector
    elems = elems.filter(selector)
  domEach elems, (i, el) ->
    parent = el.parent or el.root
    if !parent
      return
    siblings = parent.children
    index = siblings.indexOf(el)
    if index < 0
      return
    siblings.splice index, 1
    if el.prev
      el.prev.next = el.next
    if el.next
      el.next.prev = el.prev
    el.prev = el.next = el.parent = el.root = null
    return
  this

###*
# Replaces matched elements with `content`.
#
# @example
#
# const plum = $('<li class="plum">Plum</li>')
# $('.pear').replaceWith(plum)
# $.html()
# //=> <ul id="fruits">
# //     <li class="apple">Apple</li>
# //     <li class="orange">Orange</li>
# //     <li class="plum">Plum</li>
# //   </ul>
#
# @param {cheerio|Function} content - Replacement for matched elements.
#
# @see {@link http://api.jquery.com/replaceWith/}
###

exports.replaceWith = (content) ->
  self = this
  domEach this, (i, el) ->
    parent = el.parent or el.root
    if !parent
      return
    siblings = parent.children
    dom = self._makeDomArray(if typeof content == 'function' then content.call(el, i, el) else content)
    index = undefined
    # In the case that `dom` contains nodes that already exist in other
    # structures, ensure those nodes are properly removed.
    updateDOM dom, null
    index = siblings.indexOf(el)
    # Completely remove old element
    uniqueSplice siblings, index, 1, dom, parent
    el.parent = el.prev = el.next = el.root = null
    return
  this

###*
# Empties an element, removing all its children.
#
# @example
#
# $('ul').empty()
# $.html()
# //=>  <ul id="fruits"></ul>
#
# @see {@link http://api.jquery.com/empty/}
###

exports.empty = ->
  domEach this, (i, el) ->
    _.forEach el.children, (child) ->
      child.next = child.prev = child.parent = null
      return
    el.children.length = 0
    return
  this

###*
# Gets an HTML content string from the first selected element. If `htmlString`
# is specified, each selected element's content is replaced by the new
# content.
#
# @param {string} str - If specified used to replace selection's contents.
#
# @example
#
# $('.orange').html()
# //=> Orange
#
# $('#fruits').html('<li class="mango">Mango</li>').html()
# //=> <li class="mango">Mango</li>
#
# @see {@link http://api.jquery.com/html/}
###

exports.html = (str) ->
  if str == undefined
    if !@[0] or !@[0].children
      return null
    return html(@[0].children, @options)
  opts = @options
  domEach this, (i, el) ->
    _.forEach el.children, (child) ->
      child.next = child.prev = child.parent = null
      return
    content = if str.cheerio then str.clone().get() else evaluate('' + str, opts, false)
    updateDOM content, el
    return
  this

exports.toString = ->
  html this, @options

###*
# Get the combined text contents of each element in the set of matched
# elements, including their descendants. If `textString` is specified, each
# selected element's content is replaced by the new text content.
#
# @param {string} [str] - If specified replacement for the selected element's contents.
#
# @example
#
# $('.orange').text()
# //=> Orange
#
# $('ul').text()
# //=>  Apple
# //    Orange
# //    Pear
#
# @see {@link http://api.jquery.com/text/}
###

exports.text = (str) ->
  # If `str` is undefined, act as a "getter"
  if str == undefined
    return text(this)
  else if typeof str == 'function'
    # Function support
    self = this
    return domEach(this, (i, el) ->
      exports.text.call self._make(el), str.call(el, i, text([ el ]))
    )
  opts = @options
  # Append text node to each selected elements
  domEach this, (i, el) ->
    _.forEach el.children, (child) ->
      child.next = child.prev = child.parent = null
      return
    textNode = evaluate(' ', opts)[0]
    textNode.data = str
    updateDOM textNode, el
    return
  this

###*
# Clone the cheerio object.
#
# @example
#
# const moreFruit = $('#fruits').clone()
#
# @see {@link http://api.jquery.com/clone/}
###

exports.clone = ->
  @_make cloneDom(@get(), @options)
