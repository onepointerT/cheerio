###*
# Methods for getting and modifying attributes.
#
# @alias attributes
# @mixin
###

exports = exports
# eslint-disable-line no-self-assign
# The preceeding statement is necessary for proper documentation generation.
text = require('../static').text
utils = require('../utils')
isTag = utils.isTag
domEach = utils.domEach
hasOwn = Object::hasOwnProperty
camelCase = utils.camelCase
cssCase = utils.cssCase
rspace = /\s+/
dataAttrPrefix = 'data-'
_ = 
  forEach: require('lodash/forEach')
  extend: require('lodash/assignIn')
  some: require('lodash/some')
primitives = 
  null: null
  true: true
  false: false
rboolean = /^(?:autofocus|autoplay|async|checked|controls|defer|disabled|hidden|loop|multiple|open|readonly|required|scoped|selected)$/i
rbrace = /^(?:\{[\w\W]*\}|\[[\w\W]*\])$/

getAttr = (elem, name) ->
  if !elem or !isTag(elem)
    return
  if !elem.attribs
    elem.attribs = {}
  # Return the entire attribs object if no attribute specified
  if !name
    return elem.attribs
  if hasOwn.call(elem.attribs, name)
    # Get the (decoded) attribute
    return if rboolean.test(name) then name else elem.attribs[name]
  # Mimic the DOM and return text content as value for `option's`
  if elem.name == 'option' and name == 'value'
    return text(elem.children)
  # Mimic DOM with default value for radios/checkboxes
  if elem.name == 'input' and (elem.attribs.type == 'radio' or elem.attribs.type == 'checkbox') and name == 'value'
    return 'on'
  return

setAttr = (el, name, value) ->
  if value == null
    removeAttribute el, name
  else
    el.attribs[name] = value + ''
  return

###*
# Method for getting and setting attributes. Gets the attribute value for only
# the first element in the matched set. If you set an attribute's value to
# `null`, you remove that attribute. You may also pass a `map` and `function`
# like jQuery.
#
# @example
#
# $('ul').attr('id')
# //=> fruits
#
# $('.apple').attr('id', 'favorite').html()
# //=> <li class="apple" id="favorite">Apple</li>
#
# @param {string} name - Name of the attribute.
# @param {string} [value] - If specified sets the value of the attribute.
#
# @see {@link http://api.jquery.com/attr/}
###

exports.attr = (name, value) ->
  # Set the value (with attr map support)
  if typeof name == 'object' or value != undefined
    if typeof value == 'function'
      return domEach(this, (i, el) ->
        setAttr el, name, value.call(el, i, el.attribs[name])
        return
      )
    return domEach(this, (i, el) ->
      if !isTag(el)
        return
      if typeof name == 'object'
        _.forEach name, (objValue, objName) ->
          setAttr el, objName, objValue
          return
      else
        setAttr el, name, value
      return
    )
  getAttr @[0], name

getProp = (el, name) ->
  if !el or !isTag(el)
    return
  if name of el then el[name] else if rboolean.test(name) then getAttr(el, name) != undefined else getAttr(el, name)

setProp = (el, name, value) ->
  el[name] = if rboolean.test(name) then ! !value else value
  return

###*
# Method for getting and setting properties. Gets the property value for only
# the first element in the matched set.
#
# @example
#
# $('input[type="checkbox"]').prop('checked')
# //=> false
#
# $('input[type="checkbox"]').prop('checked', true).val()
# //=> ok
#
# @param {string} name - Name of the property.
# @param {any} [value] - If specified set the property to this.
#
# @see {@link http://api.jquery.com/prop/}
###

exports.prop = (name, value) ->
  i = 0
  property = undefined
  if typeof name == 'string' and value == undefined
    switch name
      when 'style'
        property = @css()
        _.forEach property, (v, p) ->
          property[i++] = p
          return
        property.length = i
      when 'tagName', 'nodeName'
        property = @[0].name.toUpperCase()
      when 'outerHTML'
        property = @clone().wrap('<container />').parent().html()
      else
        property = getProp(@[0], name)
    return property
  if typeof name == 'object' or value != undefined
    if typeof value == 'function'
      return domEach(this, (j, el) ->
        setProp el, name, value.call(el, j, getProp(el, name))
        return
      )
    return domEach(this, (__, el) ->
      if !isTag(el)
        return
      if typeof name == 'object'
        _.forEach name, (val, key) ->
          setProp el, key, val
          return
      else
        setProp el, name, value
      return
    )
  return

setData = (el, name, value) ->
  if !el.data
    el.data = {}
  if typeof name == 'object'
    return _.extend(el.data, name)
  if typeof name == 'string' and value != undefined
    el.data[name] = value
  return

# Read the specified attribute from the equivalent HTML5 `data-*` attribute,
# and (if present) cache the value in the node's internal data store. If no
# attribute name is specified, read *all* HTML5 `data-*` attributes in this
# manner.

readData = (el, name) ->
  readAll = arguments.length == 1
  domNames = undefined
  domName = undefined
  jsNames = undefined
  jsName = undefined
  value = undefined
  idx = undefined
  length = undefined
  if readAll
    domNames = Object.keys(el.attribs).filter((attrName) ->
      attrName.slice(0, dataAttrPrefix.length) == dataAttrPrefix
    )
    jsNames = domNames.map((_domName) ->
      camelCase _domName.slice(dataAttrPrefix.length)
    )
  else
    domNames = [ dataAttrPrefix + cssCase(name) ]
    jsNames = [ name ]
  idx = 0
  length = domNames.length
  while idx < length
    domName = domNames[idx]
    jsName = jsNames[idx]
    if hasOwn.call(el.attribs, domName)
      value = el.attribs[domName]
      if hasOwn.call(primitives, value)
        value = primitives[value]
      else if value == String(Number(value))
        value = Number(value)
      else if rbrace.test(value)
        try
          value = JSON.parse(value)
        catch e

          ### ignore ###

      el.data[jsName] = value
    ++idx
  if readAll then el.data else value

###*
# Method for getting and setting data attributes. Gets or sets the data
# attribute value for only the first element in the matched set.
#
# @example
#
# $('<div data-apple-color="red"></div>').data()
# //=> { appleColor: 'red' }
#
# $('<div data-apple-color="red"></div>').data('apple-color')
# //=> 'red'
#
# const apple = $('.apple').data('kind', 'mac')
# apple.data('kind')
# //=> 'mac'
#
# @param {string} name - Name of the attribute.
# @param {any} [value] - If specified new value.
#
# @see {@link http://api.jquery.com/data/}
###

exports.data = (name, value) ->
  elem = @[0]
  if !elem or !isTag(elem)
    return
  if !elem.data
    elem.data = {}
  # Return the entire data object if no data specified
  if !name
    return readData(elem)
  # Set the value (with attr map support)
  if typeof name == 'object' or value != undefined
    domEach this, (i, el) ->
      setData el, name, value
      return
    return this
  else if hasOwn.call(elem.data, name)
    return elem.data[name]
  readData elem, name

###*
# Method for getting and setting the value of input, select, and textarea.
# Note: Support for `map`, and `function` has not been added yet.
#
# @example
#
# $('input[type="text"]').val()
# //=> input_text
#
# $('input[type="text"]').val('test').html()
# //=> <input type="text" value="test"/>
#
# @param {string} [value] - If specified new value.
#
# @see {@link http://api.jquery.com/val/}
###

exports.val = (value) ->
  querying = arguments.length == 0
  element = @[0]
  if !element
    return
  switch element.name
    when 'textarea'
      return @text(value)
    when 'input'
      if @attr('type') == 'radio'
        if querying
          return @attr('value')
        @attr 'value', value
        return this
      return @attr('value', value)
    when 'select'
      option = @find('option:selected')
      returnValue = undefined
      if option == undefined
        return undefined
      if !querying
        if !hasOwn.call(@attr(), 'multiple') and typeof value == 'object'
          return this
        if typeof value != 'object'
          value = [ value ]
        @find('option').removeAttr 'selected'
        i = 0
        while i < value.length
          @find('option[value="' + value[i] + '"]').attr 'selected', ''
          i++
        return this
      returnValue = option.attr('value')
      if hasOwn.call(@attr(), 'multiple')
        returnValue = []
        domEach option, (__, el) ->
          returnValue.push getAttr(el, 'value')
          return
      return returnValue
    when 'option'
      if !querying
        @attr 'value', value
        return this
      return @attr('value')
  return

###*
# Remove an attribute.
#
# @private
# @param {node} elem - Node to remove attribute from.
# @param {string} name - Name of the attribute to remove.
###

removeAttribute = (elem, name) ->
  if !elem.attribs or !hasOwn.call(elem.attribs, name)
    return
  delete elem.attribs[name]
  return

###*
# Method for removing attributes by `name`.
#
# @example
#
# $('.pear').removeAttr('class').html()
# //=> <li>Pear</li>
#
# @param {string} name - Name of the attribute.
#
# @see {@link http://api.jquery.com/removeAttr/}
###

exports.removeAttr = (name) ->
  domEach this, (i, elem) ->
    removeAttribute elem, name
    return
  this

###*
# Check to see if *any* of the matched elements have the given `className`.
#
# @example
#
# $('.pear').hasClass('pear')
# //=> true
#
# $('apple').hasClass('fruit')
# //=> false
#
# $('li').hasClass('pear')
# //=> true
#
# @param {string} className - Name of the class.
#
# @see {@link http://api.jquery.com/hasClass/}
###

exports.hasClass = (className) ->
  _.some this, (elem) ->
    attrs = elem.attribs
    clazz = attrs and attrs['class']
    idx = -1
    end = undefined
    if clazz and className.length
      while (idx = clazz.indexOf(className, idx + 1)) > -1
        end = idx + className.length
        if (idx == 0 or rspace.test(clazz[idx - 1])) and (end == clazz.length or rspace.test(clazz[end]))
          return true
    return

###*
# Adds class(es) to all of the matched elements. Also accepts a `function`
# like jQuery.
#
# @example
#
# $('.pear').addClass('fruit').html()
# //=> <li class="pear fruit">Pear</li>
#
# $('.apple').addClass('fruit red').html()
# //=> <li class="apple fruit red">Apple</li>
#
# @param {string} value - Name of new class.
#
# @see {@link http://api.jquery.com/addClass/}
###

exports.addClass = (value) ->
  # Support functions
  if typeof value == 'function'
    return domEach(this, (i, el) ->
      className = el.attribs['class'] or ''
      exports.addClass.call [ el ], value.call(el, i, className)
      return
    )
  # Return if no value or not a string or function
  if !value or typeof value != 'string'
    return this
  classNames = value.split(rspace)
  numElements = @length
  i = 0
  while i < numElements
    # If selected element isn't a tag, move on
    if !isTag(@[i])
      i++
      continue
    # If we don't already have classes
    className = getAttr(@[i], 'class')
    numClasses = undefined
    setClass = undefined
    if !className
      setAttr @[i], 'class', classNames.join(' ').trim()
    else
      setClass = ' ' + className + ' '
      numClasses = classNames.length
      # Check if class already exists
      j = 0
      while j < numClasses
        appendClass = classNames[j] + ' '
        if setClass.indexOf(' ' + appendClass) < 0
          setClass += appendClass
        j++
      setAttr @[i], 'class', setClass.trim()
    i++
  this

splitClass = (className) ->
  if className then className.trim().split(rspace) else []

###*
# Removes one or more space-separated classes from the selected elements. If
# no `className` is defined, all classes will be removed. Also accepts a
# `function` like jQuery.
#
# @example
#
# $('.pear').removeClass('pear').html()
# //=> <li class="">Pear</li>
#
# $('.apple').addClass('red').removeClass().html()
# //=> <li class="">Apple</li>
# @param {string} value - Name of the class.
#
# @see {@link http://api.jquery.com/removeClass/}
###

exports.removeClass = (value) ->
  classes = undefined
  numClasses = undefined
  removeAll = undefined
  # Handle if value is a function
  if typeof value == 'function'
    return domEach(this, (i, el) ->
      exports.removeClass.call [ el ], value.call(el, i, el.attribs['class'] or '')
      return
    )
  classes = splitClass(value)
  numClasses = classes.length
  removeAll = arguments.length == 0
  domEach this, (i, el) ->
    if !isTag(el)
      return
    if removeAll
      # Short circuit the remove all case as this is the nice one
      el.attribs.class = ''
    else
      elClasses = splitClass(el.attribs.class)
      index = undefined
      changed = undefined
      j = 0
      while j < numClasses
        index = elClasses.indexOf(classes[j])
        if index >= 0
          elClasses.splice index, 1
          changed = true
          # We have to do another pass to ensure that there are not duplicate
          # classes listed
          j--
        j++
      if changed
        el.attribs.class = elClasses.join(' ')
    return

###*
# Add or remove class(es) from the matched elements, depending on either the
# class's presence or the value of the switch argument. Also accepts a
# `function` like jQuery.
#
# @example
#
# $('.apple.green').toggleClass('fruit green red').html()
# //=> <li class="apple fruit red">Apple</li>
#
# $('.apple.green').toggleClass('fruit green red', true).html()
# //=> <li class="apple green fruit red">Apple</li>
#
# @param {(string|Function)} value - Name of the class. Can also be a function.
# @param {boolean} [stateVal] - If specified the state of the class.
#
# @see {@link http://api.jquery.com/toggleClass/}
###

exports.toggleClass = (value, stateVal) ->
  # Support functions
  if typeof value == 'function'
    return domEach(this, (i, el) ->
      exports.toggleClass.call [ el ], value.call(el, i, el.attribs['class'] or '', stateVal), stateVal
      return
    )
  # Return if no value or not a string or function
  if !value or typeof value != 'string'
    return this
  classNames = value.split(rspace)
  numClasses = classNames.length
  state = if typeof stateVal == 'boolean' then (if stateVal then 1 else -1) else 0
  numElements = @length
  elementClasses = undefined
  index = undefined
  i = 0
  while i < numElements
    # If selected element isn't a tag, move on
    if !isTag(@[i])
      i++
      continue
    elementClasses = splitClass(@[i].attribs.class)
    # Check if class already exists
    j = 0
    while j < numClasses
      # Check if the class name is currently defined
      index = elementClasses.indexOf(classNames[j])
      # Add if stateValue === true or we are toggling and there is no value
      if state >= 0 and index < 0
        elementClasses.push classNames[j]
      else if state <= 0 and index >= 0
        # Otherwise remove but only if the item exists
        elementClasses.splice index, 1
      j++
    @[i].attribs.class = elementClasses.join(' ')
    i++
  this

###*
# Checks the current list of elements and returns `true` if _any_ of the
# elements match the selector. If using an element or Cheerio selection,
# returns `true` if _any_ of the elements match. If using a predicate
# function, the function is executed in the context of the selected element,
# so `this` refers to the current element.
#
# @param {string|Function|cheerio|node} selector - Selector for the selection.
#
# @see {@link http://api.jquery.com/is/}
###

exports.is = (selector) ->
  if selector
    return @filter(selector).length > 0
  false
