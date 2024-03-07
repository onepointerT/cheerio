###
  Module Dependencies
###

htmlparser = require('htmlparser2')
parse5 = require('parse5')
htmlparser2Adapter = require('parse5-htmlparser2-tree-adapter')

###
  Parser
###

parseWithParse5 = (content, options, isDocument) ->
  parse = if isDocument then parse5.parse else parse5.parseFragment
  root = parse(content,
    treeAdapter: htmlparser2Adapter
    sourceCodeLocationInfo: options.sourceCodeLocationInfo)
  root.children

exports =
module.exports = (content, options, isDocument) ->
  dom = exports.evaluate(content, options, isDocument)
  # Generic root element
  root = exports.evaluate('<root></root>', options, false)[0]
  root.type = 'root'
  root.parent = null
  # Update the dom using the root
  exports.update dom, root
  root

exports.evaluate = (content, options, isDocument) ->
  # options = options || $.fn.options;
  dom = undefined
  if Buffer.isBuffer(content)
    content = content.toString()
  if typeof content == 'string'
    useHtmlParser2 = options.xmlMode or options._useHtmlParser2
    dom = if useHtmlParser2 then htmlparser.parseDOM(content, options) else parseWithParse5(content, options, isDocument)
  else
    dom = content
  dom

###
  Update the dom structure, for one changed layer
###

exports.update = (arr, parent) ->
  # normalize
  if !Array.isArray(arr)
    arr = [ arr ]
  # Update parent
  if parent
    parent.children = arr
  else
    parent = null
  # Update neighbors
  i = 0
  while i < arr.length
    node = arr[i]
    # Cleanly remove existing nodes from their previous structures.
    oldParent = node.parent or node.root
    oldSiblings = oldParent and oldParent.children
    if oldSiblings and oldSiblings != arr
      oldSiblings.splice oldSiblings.indexOf(node), 1
      if node.prev
        node.prev.next = node.next
      if node.next
        node.next.prev = node.prev
    if parent
      node.prev = arr[i - 1] or null
      node.next = arr[i + 1] or null
    else
      node.prev = node.next = null
    if parent and parent.type == 'root'
      node.root = parent
      node.parent = null
    else
      node.root = null
      node.parent = parent
    i++
  parent

# module.exports = $.extend(exports);
