###global document ###

do ->
  source = document.getElementsByClassName('prettyprint source linenums')
  i = 0
  lineNumber = 0
  lineId = undefined
  lines = undefined
  totalLines = undefined
  anchorHash = undefined
  if source and source[0]
    anchorHash = document.location.hash.substring(1)
    lines = source[0].getElementsByTagName('li')
    totalLines = lines.length
    while i < totalLines
      lineNumber++
      lineId = 'line' + lineNumber
      lines[i].id = lineId
      if lineId == anchorHash
        lines[i].className += ' selected'
      i++
  return
