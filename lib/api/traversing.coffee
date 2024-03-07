###*
# Methods for traversing the DOM structure.
#
# @alias traversing
# @mixin
###

traverseParents = (self, elem, selector, limit) ->
  elems = []
  while elem and elems.length < limit
    if !selector or exports.filter.call([ elem ], selector, self).length
      elems.push elem
    elem = elem.parent
  elems

exports = exports
# eslint-disable-line no-self-assign
# The preceeding statement is necessary for proper documentation generation.
select = require('css-select')
utils = require('../utils')
domEach = utils.domEach
uniqueSort = require('htmlparser2').DomUtils.uniqueSort
isTag = utils.isTag
_ = 
  bind: require('lodash/bind')
  forEach: require('lodash/forEach')
  reject: require('lodash/reject')
  filter: require('lodash/filter')
  reduce: require('lodash/reduce')

###*
# Get the descendants of each element in the current set of matched elements,
# filtered by a selector, jQuery object, or element.
#
# @example
#
# $('#fruits').find('li').length
# //=> 3
# $('#fruits').find($('.apple')).length
# //=> 1
#
# @param {string|cheerio|node} selectorOrHaystack  - Element to look for.
#
# @see {@link http://api.jquery.com/find/}
###

exports.find = (selectorOrHaystack) ->
  elems = _.reduce(this, ((memo, elem) ->
    memo.concat _.filter(elem.children, isTag)
  ), [])
  contains = @constructor.contains
  haystack = undefined
  if selectorOrHaystack and typeof selectorOrHaystack != 'string'
    if selectorOrHaystack.cheerio
      haystack = selectorOrHaystack.get()
    else
      haystack = [ selectorOrHaystack ]
    return @_make(haystack.filter(((elem) ->
      idx = undefined
      len = undefined
      idx = 0
      len = @length
      while idx < len
        if contains(@[idx], elem)
          return true
        ++idx
      return
    ), this))
  options = 
    __proto__: @options
    context: @toArray()
  @_make select(selectorOrHaystack, elems, options)

###*
# Get the parent of each element in the current set of matched elements,
# optionally filtered by a selector.
#
# @example
#
# $('.pear').parent().attr('id')
# //=> fruits
#
# @param {string} [selector] - If specified filter for parent.
#
# @see {@link http://api.jquery.com/parent/}
###

exports.parent = (selector) ->
  set = []
  domEach this, (idx, elem) ->
    parentElem = elem.parent
    if parentElem and set.indexOf(parentElem) < 0
      set.push parentElem
    return
  if arguments.length
    set = exports.filter.call(set, selector, this)
  @_make set

###*
# Get a set of parents filtered by `selector` of each element in the current
# set of match elements.
#
# @example
#
# $('.orange').parents().length
# // => 2
# $('.orange').parents('#fruits').length
# // => 1
#
# @param {string} [selector] - If specified filter for parents.
#
# @see {@link http://api.jquery.com/parents/}
###

exports.parents = (selector) ->
  parentNodes = []
  # When multiple DOM elements are in the original set, the resulting set will
  # be in *reverse* order of the original elements as well, with duplicates
  # removed.
  @get().reverse().forEach ((elem) ->
    traverseParents(this, elem.parent, selector, Infinity).forEach (node) ->
      if parentNodes.indexOf(node) == -1
        parentNodes.push node
      return
    return
  ), this
  @_make parentNodes

###*
# Get the ancestors of each element in the current set of matched elements, up
# to but not including the element matched by the selector, DOM node, or
# cheerio object.
#
# @example
#
# $('.orange').parentsUntil('#food').length
# // => 1
#
# @param {string|node|cheerio} selector - Selector for element to stop at.
# @param {string|Function} [filter] - Optional filter for parents.
#
# @see {@link http://api.jquery.com/parentsUntil/}
###

exports.parentsUntil = (selector, filter) ->
  parentNodes = []
  untilNode = undefined
  untilNodes = undefined
  if typeof selector == 'string'
    untilNode = select(selector, @parents().toArray(), @options)[0]
  else if selector and selector.cheerio
    untilNodes = selector.toArray()
  else if selector
    untilNode = selector
  # When multiple DOM elements are in the original set, the resulting set will
  # be in *reverse* order of the original elements as well, with duplicates
  # removed.
  @toArray().reverse().forEach ((elem) ->
    while elem = elem.parent
      if untilNode and elem != untilNode or untilNodes and untilNodes.indexOf(elem) == -1 or !untilNode and !untilNodes
        if isTag(elem) and parentNodes.indexOf(elem) == -1
          parentNodes.push elem
      else
        break
    return
  ), this
  @_make if filter then select(filter, parentNodes, @options) else parentNodes

###*
# For each element in the set, get the first element that matches the selector
# by testing the element itself and traversing up through its ancestors in
# the DOM tree.
#
# @example
#
# $('.orange').closest()
# // => []
# $('.orange').closest('.apple')
# // => []
# $('.orange').closest('li')
# // => [<li class="orange">Orange</li>]
# $('.orange').closest('#fruits')
# // => [<ul id="fruits"> ... </ul>]
#
# @param {string} [selector] - Selector for the element to find.
#
# @see {@link http://api.jquery.com/closest/}
###

exports.closest = (selector) ->
  set = []
  if !selector
    return @_make(set)
  domEach this, ((idx, elem) ->
    closestElem = traverseParents(this, elem, selector, 1)[0]
    # Do not add duplicate elements to the set
    if closestElem and set.indexOf(closestElem) < 0
      set.push closestElem
    return
  ).bind(this)
  @_make set

###*
# Gets the next sibling of the first selected element, optionally filtered by
# a selector.
#
# @example
#
# $('.apple').next().hasClass('orange')
# //=> true
#
# @param {string} [selector] - If specified filter for sibling.
#
# @see {@link http://api.jquery.com/next/}
###

exports.next = (selector) ->
  if !@[0]
    return this
  elems = []
  _.forEach this, (elem) ->
    while elem = elem.next
      if isTag(elem)
        elems.push elem
        return
    return
  if selector then exports.filter.call(elems, selector, this) else @_make(elems)

###*
# Gets all the following siblings of the first selected element, optionally
# filtered by a selector.
#
# @example
#
# $('.apple').nextAll()
# //=> [<li class="orange">Orange</li>, <li class="pear">Pear</li>]
# $('.apple').nextAll('.orange')
# //=> [<li class="orange">Orange</li>]
#
# @param {string} [selector] - If specified filter for siblings.
#
# @see {@link http://api.jquery.com/nextAll/}
###

exports.nextAll = (selector) ->
  if !@[0]
    return this
  elems = []
  _.forEach this, (elem) ->
    while elem = elem.next
      if isTag(elem) and elems.indexOf(elem) == -1
        elems.push elem
    return
  if selector then exports.filter.call(elems, selector, this) else @_make(elems)

###*
# Gets all the following siblings up to but not including the element matched
# by the selector, optionally filtered by another selector.
#
# @example
#
# $('.apple').nextUntil('.pear')
# //=> [<li class="orange">Orange</li>]
#
# @param {string|cheerio|node} selector - Selector for element to stop at.
# @param {string} [filterSelector]  - If specified filter for siblings.
#
# @see {@link http://api.jquery.com/nextUntil/}
###

exports.nextUntil = (selector, filterSelector) ->
  if !@[0]
    return this
  elems = []
  untilNode = undefined
  untilNodes = undefined
  if typeof selector == 'string'
    untilNode = select(selector, @nextAll().get(), @options)[0]
  else if selector and selector.cheerio
    untilNodes = selector.get()
  else if selector
    untilNode = selector
  _.forEach this, (elem) ->
    while elem = elem.next
      if untilNode and elem != untilNode or untilNodes and untilNodes.indexOf(elem) == -1 or !untilNode and !untilNodes
        if isTag(elem) and elems.indexOf(elem) == -1
          elems.push elem
      else
        break
    return
  if filterSelector then exports.filter.call(elems, filterSelector, this) else @_make(elems)

###*
# Gets the previous sibling of the first selected element optionally filtered
# by a selector.
#
# @example
#
# $('.orange').prev().hasClass('apple')
# //=> true
#
# @param {string} [selector]  - If specified filter for siblings.
#
# @see {@link http://api.jquery.com/prev/}
###

exports.prev = (selector) ->
  if !@[0]
    return this
  elems = []
  _.forEach this, (elem) ->
    while elem = elem.prev
      if isTag(elem)
        elems.push elem
        return
    return
  if selector then exports.filter.call(elems, selector, this) else @_make(elems)

###*
# Gets all the preceding siblings of the first selected element, optionally
# filtered by a selector.
#
# @example
#
# $('.pear').prevAll()
# //=> [<li class="orange">Orange</li>, <li class="apple">Apple</li>]
# $('.pear').prevAll('.orange')
# //=> [<li class="orange">Orange</li>]
#
# @param {string} [selector]  - If specified filter for siblings.
#
# @see {@link http://api.jquery.com/prevAll/}
###

exports.prevAll = (selector) ->
  if !@[0]
    return this
  elems = []
  _.forEach this, (elem) ->
    while elem = elem.prev
      if isTag(elem) and elems.indexOf(elem) == -1
        elems.push elem
    return
  if selector then exports.filter.call(elems, selector, this) else @_make(elems)

###*
# Gets all the preceding siblings up to but not including the element matched
# by the selector, optionally filtered by another selector.
#
# @example
#
# $('.pear').prevUntil('.apple')
# //=> [<li class="orange">Orange</li>]
#
# @param {string|cheerio|node} selector - Selector for element to stop at.
# @param {string} [filterSelector]  - If specified filter for siblings.
#
# @see {@link http://api.jquery.com/prevUntil/}
###

exports.prevUntil = (selector, filterSelector) ->
  if !@[0]
    return this
  elems = []
  untilNode = undefined
  untilNodes = undefined
  if typeof selector == 'string'
    untilNode = select(selector, @prevAll().get(), @options)[0]
  else if selector and selector.cheerio
    untilNodes = selector.get()
  else if selector
    untilNode = selector
  _.forEach this, (elem) ->
    while elem = elem.prev
      if untilNode and elem != untilNode or untilNodes and untilNodes.indexOf(elem) == -1 or !untilNode and !untilNodes
        if isTag(elem) and elems.indexOf(elem) == -1
          elems.push elem
      else
        break
    return
  if filterSelector then exports.filter.call(elems, filterSelector, this) else @_make(elems)

###*
# Gets the first selected element's siblings, excluding itself.
#
# @example
#
# $('.pear').siblings().length
# //=> 2
#
# $('.pear').siblings('.orange').length
# //=> 1
#
# @param {string} [selector]  - If specified filter for siblings.
#
# @see {@link http://api.jquery.com/siblings/}
###

exports.siblings = (selector) ->
  parent = @parent()
  elems = _.filter(if parent then parent.children() else @siblingsAndMe(), _.bind(((elem) ->
    isTag(elem) and !@is(elem)
  ), this))
  if selector != undefined
    exports.filter.call elems, selector, this
  else
    @_make elems

###*
# Gets the children of the first selected element.
#
# @example
#
# $('#fruits').children().length
# //=> 3
#
# $('#fruits').children('.pear').text()
# //=> Pear
#
# @param {string} [selector]  - If specified filter for children.
#
# @see {@link http://api.jquery.com/children/}
###

exports.children = (selector) ->
  elems = _.reduce(this, ((memo, elem) ->
    memo.concat _.filter(elem.children, isTag)
  ), [])
  if selector == undefined
    return @_make(elems)
  exports.filter.call elems, selector, this

###*
# Gets the children of each element in the set of matched elements, including
# text and comment nodes.
#
# @example
#
# $('#fruits').contents().length
# //=> 3
#
# @see {@link http://api.jquery.com/contents/}
###

exports.contents = ->
  @_make _.reduce(this, ((all, elem) ->
    all.push.apply all, elem.children
    all
  ), [])

###*
# Iterates over a cheerio object, executing a function for each matched
# element. When the callback is fired, the function is fired in the context of
# the DOM element, so `this` refers to the current element, which is
# equivalent to the function parameter `element`. To break out of the `each`
# loop early, return with `false`.
#
# @example
#
# const fruits = [];
#
# $('li').each(function(i, elem) {
#   fruits[i] = $(this).text();
# });
#
# fruits.join(', ');
# //=> Apple, Orange, Pear
#
# @param {Function} fn  - Function to execute.
#
# @see {@link http://api.jquery.com/each/}
###

exports.each = (fn) ->
  i = 0
  len = @length
  while i < len and fn.call(@[i], i, @[i]) != false
    ++i
  this

###*
# Pass each element in the current matched set through a function, producing a
# new Cheerio object containing the return values. The function can return an
# individual data item or an array of data items to be inserted into the
# resulting set. If an array is returned, the elements inside the array are
# inserted into the set. If the function returns null or undefined, no element
# will be inserted.
#
# @example
#
# $('li').map(function(i, el) {
#   // this === el
#   return $(this).text();
# }).get().join(' ');
# //=> "apple orange pear"
#
# @param {Function} fn  - Function to execute.
#
# @see {@link http://api.jquery.com/map/}
###

exports.map = (fn) ->
  @_make _.reduce(this, ((memo, el, i) ->
    val = fn.call(el, i, el)
    if val == null then memo else memo.concat(val)
  ), [])

makeFilterMethod = (filterFn) ->
  (match, container) ->
    testFn = undefined
    container = container or this
    if typeof match == 'string'
      testFn = select.compile(match, container.options)
    else if typeof match == 'function'

      testFn = (el, i) ->
        match.call el, i, el

    else if match.cheerio
      testFn = match.is.bind(match)
    else

      testFn = (el) ->
        match == el

    container._make filterFn(this, testFn)

###*
# Iterates over a cheerio object, reducing the set of selector elements to
# those that match the selector or pass the function's test. When a Cheerio
# selection is specified, return only the elements contained in that
# selection. When an element is specified, return only that element (if it is
# contained in the original selection). If using the function method, the
# function is executed in the context of the selected element, so `this`
# refers to the current element.
#
# @method
#
# @example <caption>Selector</caption>
#
# $('li').filter('.orange').attr('class');
# //=> orange
#
# @example <caption>Function</caption>
#
# $('li').filter(function(i, el) {
#   // this === el
#   return $(this).attr('class') === 'orange';
# }).attr('class')
# //=> orange
#
# @see {@link http://api.jquery.com/filter/}
###

exports.filter = makeFilterMethod(_.filter)

###*
# Remove elements from the set of matched elements. Given a jQuery object that
# represents a set of DOM elements, the `.not()` method constructs a new
# jQuery object from a subset of the matching elements. The supplied selector
# is tested against each element; the elements that don't match the selector
# will be included in the result. The `.not()` method can take a function as
# its argument in the same way that `.filter()` does. Elements for which the
# function returns true are excluded from the filtered set; all other elements
# are included.
#
# @method
#
# @example <caption>Selector</caption>
#
# $('li').not('.apple').length;
# //=> 2
#
# @example <caption>Function</caption>
#
# $('li').not(function(i, el) {
#   // this === el
#   return $(this).attr('class') === 'orange';
# }).length;
# //=> 2
#
# @see {@link http://api.jquery.com/not/}
###

exports.not = makeFilterMethod(_.reject)

###*
# Filters the set of matched elements to only those which have the given DOM
# element as a descendant or which have a descendant that matches the given
# selector. Equivalent to `.filter(':has(selector)')`.
#
# @example <caption>Selector</caption>
#
# $('ul').has('.pear').attr('id');
# //=> fruits
#
# @example <caption>Element</caption>
#
# $('ul').has($('.pear')[0]).attr('id');
# //=> fruits
#
# @param {string|cheerio|node} selectorOrHaystack  - Element to look for.
#
# @see {@link http://api.jquery.com/has/}
###

exports.has = (selectorOrHaystack) ->
  that = this
  exports.filter.call this, ->
    that._make(this).find(selectorOrHaystack).length > 0

###*
# Will select the first element of a cheerio object.
#
# @example
#
# $('#fruits').children().first().text()
# //=> Apple
#
# @see {@link http://api.jquery.com/first/}
###

exports.first = ->
  if @length > 1 then @_make(@[0]) else this

###*
# Will select the last element of a cheerio object.
#
# @example
#
# $('#fruits').children().last().text()
# //=> Pear
#
# @see {@link http://api.jquery.com/last/}
###

exports.last = ->
  if @length > 1 then @_make(@[@length - 1]) else this

###*
# Reduce the set of matched elements to the one at the specified index. Use
# `.eq(-i)` to count backwards from the last selected element.
#
# @example
#
# $('li').eq(0).text()
# //=> Apple
#
# $('li').eq(-1).text()
# //=> Pear
#
# @param {number} i - Index of the element to select.
#
# @see {@link http://api.jquery.com/eq/}
###

exports.eq = (i) ->
  i = +i
  # Use the first identity optimization if possible
  if i == 0 and @length <= 1
    return this
  if i < 0
    i = @length + i
  if @[i] then @_make(@[i]) else @_make([])

###*
# Retrieve the DOM elements matched by the Cheerio object. If an index is
# specified, retrieve one of the elements matched by the Cheerio object.
#
# @example
#
# $('li').get(0).tagName
# //=> li
#
# If no index is specified, retrieve all elements matched by the Cheerio object:
#
# @example
#
# $('li').get().length
# //=> 3
#
# @param {number} [i] - Element to retrieve.
#
# @see {@link http://api.jquery.com/get/}
###

exports.get = (i) ->
  if i == null
    Array::slice.call this
  else
    @[if i < 0 then @length + i else i]

###*
# Search for a given element from among the matched elements.
#
# @example
#
# $('.pear').index()
# //=> 2
# $('.orange').index('li')
# //=> 1
# $('.apple').index($('#fruit, li'))
# //=> 1
#
# @param {string|cheerio|node} [selectorOrNeedle]  - Element to look for.
#
# @see {@link http://api.jquery.com/index/}
###

exports.index = (selectorOrNeedle) ->
  $haystack = undefined
  needle = undefined
  if arguments.length == 0
    $haystack = @parent().children()
    needle = @[0]
  else if typeof selectorOrNeedle == 'string'
    $haystack = @_make(selectorOrNeedle)
    needle = @[0]
  else
    $haystack = this
    needle = if selectorOrNeedle.cheerio then selectorOrNeedle[0] else selectorOrNeedle
  $haystack.get().indexOf needle

###*
# Gets the elements matching the specified range.
#
# @example
#
# $('li').slice(1).eq(0).text()
# //=> 'Orange'
#
# $('li').slice(1, 2).length
# //=> 1
#
# @see {@link http://api.jquery.com/slice/}
###

exports.slice = ->
  @_make [].slice.apply(this, arguments)

###*
# End the most recent filtering operation in the current chain and return the
# set of matched elements to its previous state.
#
# @example
#
# $('li').eq(0).end().length
# //=> 3
#
# @see {@link http://api.jquery.com/end/}
###

exports.end = ->
  @prevObject or @_make([])

###*
# Add elements to the set of matched elements.
#
# @example
#
# $('.apple').add('.orange').length
# //=> 2
#
# @param {string|cheerio} other - Elements to add.
# @param {cheerio} [context] - Optionally the context of the new selection.
#
# @see {@link http://api.jquery.com/add/}
###

exports.add = (other, context) ->
  selection = @_make(other, context)
  contents = uniqueSort(selection.get().concat(@get()))
  i = 0
  while i < contents.length
    selection[i] = contents[i]
    ++i
  selection.length = contents.length
  selection

###*
# Add the previous set of elements on the stack to the current set, optionally
# filtered by a selector.
#
# @example
#
# $('li').eq(0).addBack('.orange').length
# //=> 2
#
# @param {string} selector - Selector for the elements to add.
#
# @see {@link http://api.jquery.com/addBack/}
###

exports.addBack = (selector) ->
  @add if arguments.length then @prevObject.filter(selector) else @prevObject
