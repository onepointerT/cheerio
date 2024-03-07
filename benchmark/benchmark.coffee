Suites = require('./suite')
suites = new Suites
regexIdx = process.argv.indexOf('--regex') + 1
if regexIdx > 0
  if regexIdx == process.argv.length
    console.error 'Error: the "--regex" option requires a value'
    process.exit 1
  suites.filter process.argv[regexIdx]
if process.argv.indexOf('--cheerio-only') >= 0
  suites.cheerioOnly()
suites.add 'Select all', 'jquery.html', test: ($) ->
  $('*').length
  return
suites.add 'Select some', 'jquery.html', test: ($) ->
  $('li').length
  return

###
# Manipulation Tests
###

suites.add 'manipulation - append', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $body) ->
    $body.append new Array(50).join('<div>')
    return
# These tests run out of memory in jsdom
suites.add 'manipulation - prepend - highmem', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $body) ->
    $body.prepend new Array(50).join('<div>')
    return
suites.add 'manipulation - after - highmem', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $body) ->
    $body.after new Array(50).join('<div>')
    return
suites.add 'manipulation - before - highmem', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $body) ->
    $body.before new Array(50).join('<div>')
    return
suites.add 'manipulation - remove', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $lis) ->
    child = $('<div>')
    $lis.append child
    child.remove()
    return
suites.add 'manipulation - replaceWith', 'jquery.html',
  setup: ($) ->
    $('body').append '<div id="foo">'
    return
  test: ($) ->
    $('#foo').replaceWith '<div id="foo">'
    return
suites.add 'manipulation - empty', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.empty()
    return
suites.add 'manipulation - html', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.html()
    $lis.html 'foo'
    return
suites.add 'manipulation - html render', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $lis) ->
    $lis.html()
    return
suites.add 'manipulation - html independent', 'jquery.html',
  setup: ->
    '<div class="foo"><div id="bar">bat<hr>baz</div> </div>' + '<div class="foo"><div id="bar">bat<hr>baz</div> </div>' + '<div class="foo"><div id="bar">bat<hr>baz</div> </div>' + '<div class="foo"><div id="bar">bat<hr>baz</div> </div>' + '<div class="foo"><div id="bar">bat<hr>baz</div> </div>' + '<div class="foo"><div id="bar">bat<hr>baz</div> </div>'
  test: ($, content) ->
    $(content).html()
    return
suites.add 'manipulation - text', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.text()
    $lis.text 'foo'
    return

###
# Traversing Tests
###

suites.add 'traversing - Find', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.find('li').length
    return
suites.add 'traversing - Parent', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.parent('div').length
    return
suites.add 'traversing - Parents', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.parents('div').length
    return
suites.add 'traversing - Closest', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.closest('div').length
    return
suites.add 'traversing - next', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.next().length
    return
suites.add 'traversing - nextAll', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.nextAll('li').length
    return
suites.add 'traversing - nextUntil', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.nextUntil('li').length
    return
suites.add 'traversing - prev', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.prev().length
    return
suites.add 'traversing - prevAll', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.prevAll('li').length
    return
suites.add 'traversing - prevUntil', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.prevUntil('li').length
    return
suites.add 'traversing - siblings', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.siblings('li').length
    return
suites.add 'traversing - Children', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.children('a').length
    return
suites.add 'traversing - Filter', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.filter('li').length
    return
suites.add 'traversing - First', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.first().first().length
    return
suites.add 'traversing - Last', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.last().last().length
    return
suites.add 'traversing - Eq', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.eq(0).eq(0).length
    return

###
# Attributes Tests
###

suites.add 'attributes - Attributes', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.attr 'foo', 'bar'
    $lis.attr 'foo'
    $lis.removeAttr 'foo'
    return
suites.add 'attributes - Single Attribute', 'jquery.html',
  setup: ($) ->
    $ 'body'
  test: ($, $lis) ->
    $lis.attr 'foo', 'bar'
    $lis.attr 'foo'
    $lis.removeAttr 'foo'
    return
suites.add 'attributes - Data', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.data 'foo', 'bar'
    $lis.data 'foo'
    return
suites.add 'attributes - Val', 'jquery.html',
  setup: ($) ->
    $ 'select,input,textarea,option'
  test: ($, $lis) ->
    $lis.each ->
      $(this).val()
      $(this).val 'foo'
      return
    return
suites.add 'attributes - Has class', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.hasClass 'foo'
    return
suites.add 'attributes - Toggle class', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.toggleClass 'foo'
    return
suites.add 'attributes - Add Remove class', 'jquery.html',
  setup: ($) ->
    $ 'li'
  test: ($, $lis) ->
    $lis.addClass 'foo'
    $lis.removeClass 'foo'
    return
