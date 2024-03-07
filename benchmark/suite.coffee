fs = require('fs')
path = require('path')
Benchmark = require('benchmark')
JSDOM = require('jsdom').JSDOM
Script = require('vm').Script
cheerio = require('..')
documentDir = path.join(__dirname, 'documents')
jQuerySrc = fs.readFileSync(path.join(__dirname, '../node_modules/jquery/dist/jquery.slim.js'))
jQueryScript = new Script(jQuerySrc)
filterRe = /./
cheerioOnly = false
Suites = 
module.exports = ->

Suites::filter = (str) ->
  filterRe = new RegExp(str, 'i')
  return

Suites::cheerioOnly = ->
  cheerioOnly = true
  return

Suites::add = (name, fileName, options) ->
  markup = undefined
  suite = undefined
  if !filterRe.test(name)
    return
  markup = fs.readFileSync(path.join(documentDir, fileName), 'utf8')
  suite = new (Benchmark.Suite)(name)
  suite.on 'start', ->
    console.log 'Test: ' + name + ' (file: ' + fileName + ')'
    return
  suite.on 'cycle', (event) ->
    if event.target.error
      return
    console.log '\u0009' + String(event.target)
    return
  suite.on 'error', (event) ->
    console.log '*** Error in ' + event.target.name + ': ***'
    console.log '\u0009' + event.target.error
    console.log '*** Test invalidated. ***'
    return
  suite.on 'complete', (event) ->
    if event.target.error
      console.log()
      return
    console.log '\u0009Fastest: ' + @filter('fastest')[0].name + '\n'
    return
  @_benchCheerio suite, markup, options
  if !cheerioOnly
    @_benchJsDom suite, markup, options
  else
    suite.run()
  return

Suites::_benchJsDom = (suite, markup, options) ->
  testFn = options.test
  dom = new JSDOM(markup, runScripts: 'outside-only')
  dom.runVMScript jQueryScript
  setupData = undefined
  if options.setup
    setupData = options.setup.call(null, dom.window.$)
  suite.add 'jsdom', ->
    testFn.call null, dom.window.$, setupData
    return
  suite.run()
  return

Suites::_benchCheerio = (suite, markup, options) ->
  $ = cheerio.load(markup)
  testFn = options.test
  setupData = undefined
  if options.setup
    setupData = options.setup.call(null, $)
  suite.add 'cheerio', ->
    testFn.call null, $, setupData
    return
  return
