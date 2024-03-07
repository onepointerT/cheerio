find = (spec) ->
  helper.find data, spec

tutoriallink = (tutorial) ->
  helper.toTutorial tutorial, null,
    tag: 'em'
    classname: 'disabled'
    prefix: 'Tutorial: '

getAncestorLinks = (doclet) ->
  helper.getAncestorLinks data, doclet

hashToLink = (doclet, hash) ->
  url = undefined
  if !/^(#.+)/.test(hash)
    return hash
  url = helper.createLink(doclet)
  url = url.replace(/(#.+|$)/, hash)
  '<a href="' + url + '">' + hash + '</a>'

needsSignature = (doclet) ->
  needsSig = false
  # function and class definitions always get a signature
  if doclet.kind == 'function' or doclet.kind == 'class'
    needsSig = true
  else if doclet.kind == 'typedef' and doclet.type and doclet.type.names and doclet.type.names.length
    i = 0
    l = doclet.type.names.length
    while i < l
      if doclet.type.names[i].toLowerCase() == 'function'
        needsSig = true
        break
      i++
  else if doclet.kind == 'namespace' and doclet.meta and doclet.meta.code and doclet.meta.code.type and doclet.meta.code.type.match(/[Ff]unction/)
    needsSig = true
  needsSig

getSignatureAttributes = (item) ->
  attributes = []
  if item.optional
    attributes.push 'opt'
  if item.nullable == true
    attributes.push 'nullable'
  else if item.nullable == false
    attributes.push 'non-null'
  attributes

updateItemName = (item) ->
  attributes = getSignatureAttributes(item)
  itemName = item.name or ''
  if item.variable
    itemName = '&hellip;' + itemName
  if attributes and attributes.length
    itemName = util.format('%s<span class="signature-attributes">%s</span>', itemName, attributes.join(', '))
  itemName

addParamAttributes = (params) ->
  params.filter((param) ->
    param.name and param.name.indexOf('.') == -1
  ).map updateItemName

buildItemTypeStrings = (item) ->
  types = []
  if item and item.type and item.type.names
    item.type.names.forEach (name) ->
      types.push linkto(name, htmlsafe(name))
      return
  types

buildAttribsString = (attribs) ->
  attribsString = ''
  if attribs and attribs.length
    attribsString = htmlsafe(util.format('(%s) ', attribs.join(', ')))
  attribsString

addNonParamAttributes = (items) ->
  types = []
  items.forEach (item) ->
    types = types.concat(buildItemTypeStrings(item))
    return
  types

addSignatureParams = (f) ->
  params = if f.params then addParamAttributes(f.params) else []
  f.signature = util.format('%s(%s)', f.signature or '', params.join(', '))
  return

addSignatureReturns = (f) ->
  attribs = []
  attribsString = ''
  returnTypes = []
  returnTypesString = ''
  source = f.yields or f.returns
  # jam all the return-type attributes into an array. this could create odd results (for example,
  # if there are both nullable and non-nullable return types), but let's assume that most people
  # who use multiple @return tags aren't using Closure Compiler type annotations, and vice-versa.
  if source
    source.forEach (item) ->
      helper.getAttribs(item).forEach (attrib) ->
        if attribs.indexOf(attrib) == -1
          attribs.push attrib
        return
      return
    attribsString = buildAttribsString(attribs)
  if source
    returnTypes = addNonParamAttributes(source)
  if returnTypes.length
    returnTypesString = util.format(' &rarr; %s{%s}', attribsString, returnTypes.join('|'))
  f.signature = '<span class="signature">' + (f.signature or '') + '</span>' + '<span class="type-signature">' + returnTypesString + '</span>'
  return

addSignatureTypes = (f) ->
  types = if f.type then buildItemTypeStrings(f) else []
  f.signature = (f.signature or '') + '<span class="type-signature">' + (if types.length then ' :' + types.join('|') else '') + '</span>'
  return

addAttribs = (f) ->
  attribs = helper.getAttribs(f)
  attribsString = buildAttribsString(attribs)
  f.attribs = util.format('<span class="type-signature">%s</span>', attribsString)
  return

shortenPaths = (files, commonPrefix) ->
  Object.keys(files).forEach (file) ->
    files[file].shortened = files[file].resolved.replace(commonPrefix, '').replace(/\\/g, '/')
    return
  files

getPathFromDoclet = (doclet) ->
  if !doclet.meta
    return null
  if doclet.meta.path and doclet.meta.path != 'null' then path.join(doclet.meta.path, doclet.meta.filename) else doclet.meta.filename

generate = (title, docs, filename, resolveLinks) ->
  docData = undefined
  html = undefined
  outpath = undefined
  resolveLinks = resolveLinks != false
  docData =
    env: env
    title: title
    docs: docs
  outpath = path.join(outdir, filename)
  html = view.render('container.tmpl', docData)
  if resolveLinks
    html = helper.resolveLinks(html)
    # turn {@link foo} into <a href="foodoc.html">foo</a>
  fs.writeFileSync outpath, html, 'utf8'
  return

generateSourceFiles = (sourceFiles, encoding) ->
  encoding = encoding or 'utf8'
  Object.keys(sourceFiles).forEach (file) ->
    source = undefined
    # links are keyed to the shortened path in each doclet's `meta.shortpath` property
    sourceOutfile = helper.getUniqueFilename(sourceFiles[file].shortened)
    helper.registerLink sourceFiles[file].shortened, sourceOutfile
    try
      source =
        kind: 'source'
        code: helper.htmlsafe(fs.readFileSync(sourceFiles[file].resolved, encoding))
    catch e
      logger.error 'Error while generating source file %s: %s', file, e.message
    generate 'Source: ' + sourceFiles[file].shortened, [ source ], sourceOutfile, false
    return
  return

###*
# Look for classes or functions with the same name as modules (which indicates that the module
# exports only that class or function), then attach the classes or functions to the `module`
# property of the appropriate module doclets. The name of each class or function is also updated
# for display purposes. This function mutates the original arrays.
#
# @private
# @param {Array.<module:jsdoc/doclet.Doclet>} doclets - The array of classes and functions to
# check.
# @param {Array.<module:jsdoc/doclet.Doclet>} modules - The array of module doclets to search.
###

attachModuleSymbols = (doclets, modules) ->
  symbols = {}
  # build a lookup table
  doclets.forEach (symbol) ->
    symbols[symbol.longname] = symbols[symbol.longname] or []
    symbols[symbol.longname].push symbol
    return
  modules.forEach (module) ->
    if symbols[module.longname]
      module.modules = symbols[module.longname].filter((symbol) ->
        symbol.description or symbol.kind == 'class'
      ).map((symbol) ->
        symbol = doop(symbol)
        if symbol.kind == 'class' or symbol.kind == 'function'
          symbol.name = symbol.name.replace('module:', '(require("') + '"))'
        symbol
      )
    return
  return

buildMemberNav = (items, itemHeading, itemsSeen, linktoFn) ->
  nav = ''
  if items.length
    itemsNav = ''
    items.forEach (item) ->
      displayName = undefined
      if !hasOwnProp.call(item, 'longname')
        itemsNav += '<li>' + linktoFn('', item.name) + '</li>'
      else if !hasOwnProp.call(itemsSeen, item.longname)
        if env.conf.templates.default.useLongnameInNav
          displayName = item.longname
        else
          displayName = item.name
        itemsNav += '<li>' + linktoFn(item.longname, displayName.replace(/\b(module|event):/g, '')) + '</li>'
        itemsSeen[item.longname] = true
      return
    if itemsNav != ''
      nav += '<h3>' + itemHeading + '</h3><ul>' + itemsNav + '</ul>'
  nav

linktoTutorial = (longName, name) ->
  tutoriallink name

linktoExternal = (longName, name) ->
  linkto longName, name.replace(/(^"|"$)/g, '')

###*
# Create the navigation sidebar.
# @param {object} members The members that will be used to create the sidebar.
# @param {array<object>} members.classes
# @param {array<object>} members.externals
# @param {array<object>} members.globals
# @param {array<object>} members.mixins
# @param {array<object>} members.modules
# @param {array<object>} members.namespaces
# @param {array<object>} members.tutorials
# @param {array<object>} members.events
# @param {array<object>} members.interfaces
# @return {string} The HTML for the navigation sidebar.
###

buildNav = (members) ->
  globalNav = undefined
  nav = '<h2><a href="index.html">Home</a></h2>'
  seen = {}
  seenTutorials = {}
  nav += buildMemberNav(members.modules, 'Modules', {}, linkto)
  nav += buildMemberNav(members.externals, 'Externals', seen, linktoExternal)
  nav += buildMemberNav(members.namespaces, 'Namespaces', seen, linkto)
  nav += buildMemberNav(members.classes, 'Classes', seen, linkto)
  nav += buildMemberNav(members.interfaces, 'Interfaces', seen, linkto)
  nav += buildMemberNav(members.events, 'Events', seen, linkto)
  nav += buildMemberNav(members.mixins, 'Categories', seen, linkto)
  nav += buildMemberNav(members.tutorials, 'Tutorials', seenTutorials, linktoTutorial)
  if members.globals.length
    globalNav = ''
    members.globals.forEach (g) ->
      if g.kind != 'typedef' and !hasOwnProp.call(seen, g.longname)
        globalNav += '<li>' + linkto(g.longname, g.name) + '</li>'
      seen[g.longname] = true
      return
    if !globalNav
      # turn the heading into a link so you can actually get to the global page
      nav += '<h3>' + linkto('global', 'Global') + '</h3>'
    else
      nav += '<h3>Global</h3><ul>' + globalNav + '</ul>'
  nav

'use strict'
doop = require('jsdoc/util/doop')
env = require('jsdoc/env')
fs = require('jsdoc/fs')
helper = require('jsdoc/util/templateHelper')
logger = require('jsdoc/util/logger')
path = require('jsdoc/path')
taffy = require('taffydb').taffy
template = require('jsdoc/template')
util = require('util')
htmlsafe = helper.htmlsafe
linkto = helper.linkto
resolveAuthorLinks = helper.resolveAuthorLinks
hasOwnProp = Object::hasOwnProperty
data = undefined
view = undefined
outdir = path.normalize(env.opts.destination)

###*
    @param {TAFFY} taffyData See <http://taffydb.com/>.
    @param {object} opts
    @param {Tutorial} tutorials
###

exports.publish = (taffyData, opts, tutorials) ->
  classes = undefined
  conf = undefined
  externals = undefined
  files = undefined
  fromDir = undefined
  globalUrl = undefined
  indexUrl = undefined
  interfaces = undefined
  members = undefined
  mixins = undefined
  modules = undefined
  namespaces = undefined
  outputSourceFiles = undefined
  packageInfo = undefined
  packages = undefined
  sourceFilePaths = []
  sourceFiles = {}
  staticFileFilter = undefined
  staticFilePaths = undefined
  staticFiles = undefined
  staticFileScanner = undefined
  templatePath = undefined
  # TODO: move the tutorial functions to templateHelper.js

  generateTutorial = (title, tutorial, filename) ->
    tutorialData = 
      title: title
      header: tutorial.title
      content: tutorial.parse()
      children: tutorial.children
    tutorialPath = path.join(outdir, filename)
    html = view.render('tutorial.tmpl', tutorialData)
    # yes, you can use {@link} in tutorials too!
    html = helper.resolveLinks(html)
    # turn {@link foo} into <a href="foodoc.html">foo</a>
    fs.writeFileSync tutorialPath, html, 'utf8'
    return

  # tutorials can have only one parent so there is no risk for loops

  saveChildren = (node) ->
    node.children.forEach (child) ->
      generateTutorial 'Tutorial: ' + child.title, child, helper.tutorialToUrl(child.name)
      saveChildren child
      return
    return

  data = taffyData
  conf = env.conf.templates or {}
  conf.default = conf.default or {}
  templatePath = path.normalize(opts.template)
  view = new (template.Template)(path.join(templatePath, 'tmpl'))
  # claim some special filenames in advance, so the All-Powerful Overseer of Filename Uniqueness
  # doesn't try to hand them out later
  indexUrl = helper.getUniqueFilename('index')
  # don't call registerLink() on this one! 'index' is also a valid longname
  globalUrl = helper.getUniqueFilename('global')
  helper.registerLink 'global', globalUrl
  # set up templating
  view.layout = if conf.default.layoutFile then path.getResourcePath(path.dirname(conf.default.layoutFile), path.basename(conf.default.layoutFile)) else 'layout.tmpl'
  # set up tutorials for helper
  helper.setTutorials tutorials
  data = helper.prune(data)
  data.sort 'longname, version, since'
  helper.addEventListeners data
  data().each (doclet) ->
    sourcePath = undefined
    doclet.attribs = ''
    if doclet.examples
      doclet.examples = doclet.examples.map((example) ->
        caption = undefined
        code = undefined
        if example.match(/^\s*<caption>([\s\S]+?)<\/caption>(\s*[\n\r])([\s\S]+)$/i)
          caption = RegExp.$1
          code = RegExp.$3
        {
          caption: caption or ''
          code: code or example
        }
      )
    if doclet.see
      doclet.see.forEach (seeItem, i) ->
        doclet.see[i] = hashToLink(doclet, seeItem)
        return
    # build a list of source files
    if doclet.meta
      sourcePath = getPathFromDoclet(doclet)
      sourceFiles[sourcePath] =
        resolved: sourcePath
        shortened: null
      if sourceFilePaths.indexOf(sourcePath) == -1
        sourceFilePaths.push sourcePath
    return
  # update outdir if necessary, then create outdir
  packageInfo = (find(kind: 'package') or [])[0]
  if packageInfo and packageInfo.name
    outdir = path.join(outdir, packageInfo.name, packageInfo.version or '')
  fs.mkPath outdir
  # copy the template's static files to outdir
  fromDir = path.join(templatePath, 'static')
  staticFiles = fs.ls(fromDir, 3)
  staticFiles.forEach (fileName) ->
    toDir = fs.toDir(fileName.replace(fromDir, outdir))
    fs.mkPath toDir
    fs.copyFileSync fileName, toDir
    return
  # copy user-specified static files to outdir
  if conf.default.staticFiles
    # The canonical property name is `include`. We accept `paths` for backwards compatibility
    # with a bug in JSDoc 3.2.x.
    staticFilePaths = conf.default.staticFiles.include or conf.default.staticFiles.paths or []
    staticFileFilter = new (require('jsdoc/src/filter').Filter)(conf.default.staticFiles)
    staticFileScanner = new (require('jsdoc/src/scanner').Scanner)
    staticFilePaths.forEach (filePath) ->
      extraStaticFiles = undefined
      filePath = path.resolve(env.pwd, filePath)
      extraStaticFiles = staticFileScanner.scan([ filePath ], 10, staticFileFilter)
      extraStaticFiles.forEach (fileName) ->
        sourcePath = fs.toDir(filePath)
        toDir = fs.toDir(fileName.replace(sourcePath, outdir))
        fs.mkPath toDir
        fs.copyFileSync fileName, toDir
        return
      return
  if sourceFilePaths.length
    sourceFiles = shortenPaths(sourceFiles, path.commonPrefix(sourceFilePaths))
  data().each (doclet) ->
    docletPath = undefined
    url = helper.createLink(doclet)
    helper.registerLink doclet.longname, url
    # add a shortened version of the full path
    if doclet.meta
      docletPath = getPathFromDoclet(doclet)
      docletPath = sourceFiles[docletPath].shortened
      if docletPath
        doclet.meta.shortpath = docletPath
    return
  data().each (doclet) ->
    url = helper.longnameToUrl[doclet.longname]
    if url.indexOf('#') > -1
      doclet.id = helper.longnameToUrl[doclet.longname].split(/#/).pop()
    else
      doclet.id = doclet.name
    if needsSignature(doclet)
      addSignatureParams doclet
      addSignatureReturns doclet
      addAttribs doclet
    return
  # do this after the urls have all been generated
  data().each (doclet) ->
    doclet.ancestors = getAncestorLinks(doclet)
    if doclet.kind == 'member'
      addSignatureTypes doclet
      addAttribs doclet
    if doclet.kind == 'constant'
      addSignatureTypes doclet
      addAttribs doclet
      doclet.kind = 'member'
    return
  members = helper.getMembers(data)
  members.tutorials = tutorials.children
  # output pretty-printed source files by default
  outputSourceFiles = conf.default and conf.default.outputSourceFiles != false
  # add template helpers
  view.find = find
  view.linkto = linkto
  view.resolveAuthorLinks = resolveAuthorLinks
  view.tutoriallink = tutoriallink
  view.htmlsafe = htmlsafe
  view.outputSourceFiles = outputSourceFiles
  # once for all
  view.nav = buildNav(members)
  attachModuleSymbols find(longname: left: 'module:'), members.modules
  # generate the pretty-printed source files first so other pages can link to them
  if outputSourceFiles
    generateSourceFiles sourceFiles, opts.encoding
  if members.globals.length
    generate 'Global', [ { kind: 'globalobj' } ], globalUrl
  # index page displays information from package.json and lists files
  files = find(kind: 'file')
  packages = find(kind: 'package')
  generate 'Home', packages.concat([ {
    kind: 'mainpage'
    readme: opts.readme
    longname: if opts.mainpagetitle then opts.mainpagetitle else 'Main Page'
  } ]).concat(files), indexUrl
  # set up the lists that we'll use to generate pages
  classes = taffy(members.classes)
  modules = taffy(members.modules)
  namespaces = taffy(members.namespaces)
  mixins = taffy(members.mixins)
  externals = taffy(members.externals)
  interfaces = taffy(members.interfaces)
  Object.keys(helper.longnameToUrl).forEach (longname) ->
    myClasses = helper.find(classes, longname: longname)
    myExternals = helper.find(externals, longname: longname)
    myInterfaces = helper.find(interfaces, longname: longname)
    myMixins = helper.find(mixins, longname: longname)
    myModules = helper.find(modules, longname: longname)
    myNamespaces = helper.find(namespaces, longname: longname)
    if myModules.length
      generate 'Module: ' + myModules[0].name, myModules, helper.longnameToUrl[longname]
    if myClasses.length
      generate 'Class: ' + myClasses[0].name, myClasses, helper.longnameToUrl[longname]
    if myNamespaces.length
      generate 'Namespace: ' + myNamespaces[0].name, myNamespaces, helper.longnameToUrl[longname]
    if myMixins.length
      generate 'Category: ' + myMixins[0].name, myMixins, helper.longnameToUrl[longname]
    if myExternals.length
      generate 'External: ' + myExternals[0].name, myExternals, helper.longnameToUrl[longname]
    if myInterfaces.length
      generate 'Interface: ' + myInterfaces[0].name, myInterfaces, helper.longnameToUrl[longname]
    return
  saveChildren tutorials
  return
