#
# Creates a HTML Diff based on content changes and not
# based on markup changes.
# Ideal to compare a HTML invalid formatting with a 
# valid one.
#
# Dependencies:
#
# jQuery -> converting text into plain text including HTML Entities
# Diff Match Path -> http://code.google.com/p/google-diff-match-patch/
#= require ./diff_match_patch_uncompressed

window.HtmlDiff =

  formatTextDiff: (originalText, finalText) ->
    #console.log originalText
    #console.log finalText
    # First create a correct diff of these 2 texts, disregarding markup changes
    finalDiff = @makeDiff(originalText, finalText)
    #@consoleDiff finalDiff
    finalDiff = @aggregateDiff finalDiff
    finalDiff = @filterRemovedSpaces finalDiff
    # format the diff to HTML tags
    r = @formatDiff finalDiff
    console.log r
    r

  # private method
  makeDiff: (originalText, finalText) ->
    originalText = @fixEntities originalText
    finalText = @fixEntities finalText

    # To make a correct diff, we need to have the real content changes,
    # so 1. Convert both texts to comparable plain text strings
    initialPlain = @sanitizePlainText originalText
    updatedPlain = @sanitizePlainText finalText
    #console.log initialPlain, updatedPlain

    # 2. Make the plain text diff
    plainDiff = diff_match_patch.prototype.diff_main(initialPlain, updatedPlain)
    diff_match_patch.prototype.diff_cleanupSemantic plainDiff

    # no text changes, accept the final text
    return [[DIFF_EQUAL, finalText]] if plainDiff.length is 1

    #@consoleDiff plainDiff
    # Only keep the changes, strip all changes of trailing and leading spaces
    plainChanges = @makeSmallestPlainChanges plainDiff
    #console.log "plain changes:"
    #@consoleDiff plainChanges

    # 3. Make the diff with the 2 marked up texts
    diff = diff_match_patch.prototype.diff_main(originalText, finalText)
    diff_match_patch.prototype.diff_cleanupSemantic diff
    diff = @makeSmallestMarkupChanges diff
    #@consoleDiff diff

    # store our final diff.
    # It's a list of changes, each entry is of the form [change, content]
    # where change is one of DIFF_ADD, DIFF_DELETE or DIFF_EQUAL
    finalDiff = []

    # Walk through our messy markup diff
    diffIndex = 0
    while diffIndex < diff.length
      [changeType, text] = diff[diffIndex]
      #@consoleDiff [diff[diffIndex]]

      # Try to find the markup change within our plain text changes
      # Take into account the changes that are alread added to the final
      # diff using the lookupPos var. The markup change could also contain
      # our plain text change. e.g. '<h2>Hello' => 'Hello'
      # These should also be detected, so indexOf is used instead of ==
      plainTextChange = text
      textChange = null
      if plainTextChange.length
        textChange = _.find plainChanges, ([plainChange, plainText], index) =>
          scramble = @scrambleMarkup plainTextChange, plainText
          # check if:
          # - the markup change contains our plain text change
          # - the change is of the same direction (addition, deletion)
          # - the change is not already in our final diff.
          if (scramble.indexOf(plainText) > -1) and (changeType is plainChange) and (changeType isnt DIFF_EQUAL)
            #@consoleDiff plainChanges
            #@consoleDiff finalDiff
            plainChanges.splice(0, index + 1) # shrink our 'todo'
            true

      if textChange
        plainText = textChange[1]

        # scramble the markup code to find the position of the replacement. By scrambling all markup the position will be a true
        # text position, and not a markup position. e.g. 'p' wrongly matching in '<p>hello p'
        scramble = @scrambleMarkup text, plainText

        # scramble own entities for matching.
        replacePos = scramble.indexOf(@scrambleMarkup plainText, plainText)
        preChange = text.substr(0, replacePos)
        plainPreChange = @sanitizePlainText preChange
        postChange = text.substr(replacePos + plainText.length)
        #console.log "'#{plainText}' as change for: '#{text}'", "'#{scramble}', starting: #{replacePos}, change: #{changeType}, pre: #{preChange}"

        lastChangeType = finalDiff[finalDiff.length - 1]?[0]
        if (lastChangeType is DIFF_DELETE and changeType is DIFF_INSERT) and plainPreChange.length
          #console.log "prechanges is a swap"
          finalDiff.push([DIFF_INSERT, preChange]) # we are in a swap (del - ins)
        else
          #console.log "prechanges is equal (not interesting)"
          finalDiff.push([DIFF_EQUAL, preChange])

        finalDiff.push([changeType, plainText])

        if postChange.length
          #console.log "injecting '#{postChange}' into diff for processing"
          diff.splice(diffIndex + 1, 0, [changeType, postChange])
      else
        if changeType is DIFF_DELETE
          # only pass through delete spaces (which get filtered in the end)
          finalDiff.push([DIFF_DELETE, text]) if text.match(/^\s+$/)
        else
          finalDiff.push([DIFF_EQUAL, text])
      diffIndex++

    finalDiff

  # private method
  # scramble markup code to prevent matching with our plain text change
  scrambleMarkup: (markup, text) ->
    scrambler = (content) -> content.replace text, text.substr(1).concat("~")
    scramble = markup.replace /(<[^>]*>)/g, scrambler
    scramble = scramble.replace /^([a-zA-Z]*>)/, scrambler
    scramble = scramble.replace /(<[a-zA-Z]*)$/, scrambler
    if not text.match /&[^;]+;/ # no entity placement?
      scramble = scramble.replace /(&[^;]*;)/g, scrambler
    scramble

  # private method
  # Split the diff components into the smallest parts possible.
  # no multiple words, no large replacements
  makeSmallestPlainChanges: (plainDiff) ->
    plainChanges = []
    for [change, content], index in plainDiff
      if change is DIFF_DELETE and plainDiff[index + 1]?[0] is DIFF_INSERT
        # word replacement. check if it should be split up more
        deletion = content
        insertion = plainDiff[index + 1][1]
        if (pos = insertion.indexOf(deletion)) > -1 # insertion contains deletion, split up
          prefix = insertion.substr(0, pos).replace(/^\s+/, '').replace(/\s+$/, '')
          suffix = insertion.substr(pos + deletion.length).replace(/^\s+/, '').replace(/\s+$/, '')
          #console.log "'#{insertion}' => '#{prefix}' '#{deletion}' '#{suffix}'"
          @addDiffPart plainChanges, DIFF_INSERT, prefix
          @addDiffPart plainChanges, DIFF_INSERT, suffix
        else if (pos = deletion.indexOf(insertion)) > -1 # deletion contains insertion, split up
          prefix = deletion.substr(0, pos).replace(/^\s+/, '').replace(/\s+$/, '')
          suffix = deletion.substr(pos + insertion.length).replace(/^\s+/, '').replace(/\s+$/, '')
          #console.log "'#{insertion}' => '#{prefix}' '#{deletion}' '#{suffix}'"
          @addDiffPart plainChanges, DIFF_DELETE, prefix
          @addDiffPart plainChanges, DIFF_DELETE, suffix
        else
          @addDiffPart plainChanges, DIFF_DELETE, deletion
          @addDiffPart plainChanges, DIFF_INSERT, insertion

          #console.log "Replacement: '#{deletion}' => '#{insertion}'"
      else if change is DIFF_INSERT and plainDiff[index - 1]?[0] is DIFF_DELETE
        # Already handled by block above
      else if change isnt DIFF_EQUAL
        @addDiffPart plainChanges, change, content
    plainChanges

  addDiffPart: (diff, change, text) ->
    plainText = $("<div>").text(text).html()
    plainText = @sanitizeSpaces plainText
    for word in plainText.split(/\s+/)
      diff.push [change, word]

  makeSmallestMarkupChanges: (markupDiff) ->
    markupChanges = []
    for [change, content], index in markupDiff
      if change is DIFF_DELETE and markupDiff[index + 1]?[0] is DIFF_INSERT
        # word replacement. check if it should be split up more
        deletion = content
        insertion = markupDiff[index + 1][1]
        if (pos = insertion.indexOf(deletion)) > -1 # insertion contains deletion, split up
          prefix = insertion.substr(0, pos)
          suffix = insertion.substr(pos + deletion.length)
          @addMarkupDiff markupChanges, DIFF_INSERT, prefix
          @addMarkupDiff markupChanges, DIFF_EQUAL, deletion
          @addMarkupDiff markupChanges, DIFF_INSERT, suffix
        else if (pos = deletion.indexOf(insertion)) > -1 # deletion contains insertion, split up
          prefix = deletion.substr(0, pos)
          suffix = deletion.substr(pos + insertion.length)
          @addMarkupDiff markupChanges, DIFF_DELETE, prefix
          @addMarkupDiff markupChanges, DIFF_EQUAL, insertion
          @addMarkupDiff markupChanges, DIFF_DELETE, suffix
        else
          deletions = []
          @addMarkupDiff deletions, DIFF_DELETE, deletion
          inserts = []
          @addMarkupDiff inserts, DIFF_INSERT, insertion
          deletedParts = (text for [change, text] in deletions)
          insertedParts = (text for [change, text] in inserts)
          #console.log deletedParts
          #console.log insertedParts
          equals = []

          intersected = _.reject _.intersect(deletedParts, insertedParts), (elem) -> elem.match /^\s+$/
          #console.log intersected
          if intersected.length > 0
            while deletions[0]? and (deletions[0][1] isnt intersected[0])
              markupChanges.push(deletions.shift())
            while inserts[0]? and (inserts[0][1] isnt intersected[0])
              markupChanges.push(inserts.shift())

            while inserts[0]? and deletions[0]? and (inserts[0][1] is deletions[0][1])
              equals.push [DIFF_EQUAL, inserts[0][1]]
              inserts.shift()
              deletions.shift()

          markupChanges = markupChanges.concat(equals).concat(deletions).concat(inserts)

      else if change is DIFF_INSERT and markupDiff[index - 1]?[0] is DIFF_DELETE
        # Already handled by block above
      else
        @addMarkupDiff markupChanges, change, content
    markupChanges

  addMarkupDiff: (diff, change, text) ->
    items = @splitCollect(text, /\s+|<[^>]+>/g)
    diff.push [change, item] for item in items

  splitCollect: (text, separator) ->
    elements = text.split separator
    splittings = []
    text.replace separator, (content) -> splittings.push content
    collection = []
    for element in elements
      collection.push(element) if element.length
      sep = splittings.shift()
      collection.push(sep) if sep?
    collection

  # private method
  # grab all plain text from a piece of HTML, separate all words
  # with a single space and strip the leading and trailing spaces
  sanitizePlainText: (text) ->
    plainText = $("<div>#{text.replace />/g, "> "}</div>").text()
    plainText = @sanitizeSpaces plainText

  sanitizeSpaces: (plainText) ->
    plainText = plainText.replace(/\s+/g, " ").replace(/^\s*/, "").replace(/\s*$/, "")

  htmlText: (text) ->
    plainText = $("<div>#{text.replace />/g, "> "}</div>").text()
    $("<div>").text(plainText).html()

  formatDiff: (diff) ->
    html = []
    for [change, text] in diff
      switch change
        when DIFF_INSERT then html.push "<ins>#{text}</ins>"
        when DIFF_DELETE then html.push "<del>#{text}</del>"
        when DIFF_EQUAL then html.push text
    html.join ''

  aggregateDiff: (diff) ->
    aggregatedDiff = [diff[0]]

    spaces = []
    lastChangeType = aggregatedDiff[0][0]
    for [change, content], index in diff when index > 0
      lastPos = aggregatedDiff.length - 1
      [lastChange, lastContent] = aggregatedDiff[lastPos]
      if change is lastChange
        aggregatedDiff[lastPos][1] = lastContent.concat(content)
      else
        lastChangePos = aggregatedDiff.length - 2
        if lastChangePos >= 0
          [previousChangeType, previousContent] = aggregatedDiff[lastChangePos]
          if (previousChangeType is change) and (lastChange is DIFF_EQUAL) and (lastContent.match /^\s*$/)
            aggregatedDiff[lastChangePos][1] = previousContent.concat(lastContent).concat(content)
            aggregatedDiff.pop()
          else
            aggregatedDiff.push [change, content]
        else
          aggregatedDiff.push [change, content]
    aggregatedDiff

  fixEntities: (text) ->
    $("<div>#{text}</div>").html()

  consoleDiff: (diff) ->
    return unless console?
    items = for [change, text] in _.clone(diff)
      sign = ""
      sign = "+" if change is DIFF_INSERT
      sign = "-" if change is DIFF_DELETE
      "#{sign}#{text}"
    console.log items

  filterRemovedSpaces: (diff) ->
    filtered = _.select diff, ([change, content]) ->
      if change is DIFF_DELETE and content.match(/^\s+$/)
        false
      else true

