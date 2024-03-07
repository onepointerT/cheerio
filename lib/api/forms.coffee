###*
# @alias forms
# @mixin
###

exports = exports
# eslint-disable-line no-self-assign
# The preceeding statement is necessary for proper documentation generation.
# https://github.com/jquery/jquery/blob/2.1.3/src/manipulation/var/rcheckableType.js
# https://github.com/jquery/jquery/blob/2.1.3/src/serialize.js
submittableSelector = 'input,select,textarea,keygen'
r20 = /%20/g
rCRLF = /\r?\n/g
_ = map: require('lodash/map')

###*
# Encode a set of form elements as a string for submission.
#
# @see {@link http://api.jquery.com/serialize/}
###

exports.serialize = ->
  # Convert form elements into name/value objects
  arr = @serializeArray()
  # Serialize each element into a key/value string
  retArr = _.map(arr, (data) ->
    encodeURIComponent(data.name) + '=' + encodeURIComponent(data.value)
  )
  # Return the resulting serialization
  retArr.join('&').replace r20, '+'

###*
# Encode a set of form elements as an array of names and values.
#
# @example
# $('<form><input name="foo" value="bar" /></form>').serializeArray()
# //=> [ { name: 'foo', value: 'bar' } ]
#
# @see {@link http://api.jquery.com/serializeArray/}
###

exports.serializeArray = ->
  # Resolve all form elements from either forms or collections of form elements
  Cheerio = @constructor
  @map(->
    elem = this
    $elem = Cheerio(elem)
    if elem.name == 'form'
      $elem.find(submittableSelector).toArray()
    else
      $elem.filter(submittableSelector).toArray()
  ).filter('[name!=""]:not(:disabled)' + ':not(:submit, :button, :image, :reset, :file)' + ':matches([checked], :not(:checkbox, :radio))').map((i, elem) ->
    $elem = Cheerio(elem)
    name = $elem.attr('name')
    value = $elem.val()
    # If there is no value set (e.g. `undefined`, `null`), then default value to empty
    if value == null
      value = ''
    # If we have an array of values (e.g. `<select multiple>`), return an array of key/value pairs
    if Array.isArray(value)
      _.map value, (val) ->
        # We trim replace any line endings (e.g. `\r` or `\r\n` with `\r\n`) to guarantee consistency across platforms
        #   These can occur inside of `<textarea>'s`
        {
          name: name
          value: val.replace(rCRLF, '\u000d\n')
        }
      # Otherwise (e.g. `<input type="text">`, return only one key/value pair
    else
      {
        name: name
        value: value.replace(rCRLF, '\u000d\n')
      }
    # Convert our result to an array
  ).get()
