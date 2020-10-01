html-diff-js
============

Diff tool for html documents, disregarding markup

Dependencies
============

jQuery: converting text into plain text including HTML Entities

Diff Match Path: http://code.google.com/p/google-diff-match-patch/

Underscore.js: Utility functions

Usage
=====

To produce a html diff marking insertions and deletions using the
`<ins>` and `<del>` tags:

    HtmlDiff.formatTextDiff(originalText, finalText)

see the code of this method to get the individual steps if you want the
diff in array form.

License
=======

This library is released under the MIT license

 * http://www.opensource.org/licenses/MIT

