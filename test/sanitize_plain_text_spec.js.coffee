
describe "Html diff disregarding markup", ->
  describe "sanitizePlainText", ->

    it "strips leading spaces", ->
      text = "    hello"
      expect(HtmlDiff.sanitizePlainText text).toEqual "hello"

    it "strips ending spaces", ->
      text = "hello    "
      expect(HtmlDiff.sanitizePlainText text).toEqual "hello"

    it "strips too many spaces", ->
      text = "hello    there"
      expect(HtmlDiff.sanitizePlainText text).toEqual "hello there"

    it "removes html tags", ->
      text = "<h1>hello</h1><p>there</p>"
      expect(HtmlDiff.sanitizePlainText text).toEqual "hello there"

    it "removes invalid tags", ->
      text = "<p><h1>hello</p><p>there</p>"
      expect(HtmlDiff.sanitizePlainText text).toEqual "hello there"

    it "converts html entities", ->
      text = "&lt;hello &amp; welcome&gt;"
      expect(HtmlDiff.sanitizePlainText text).toEqual "<hello & welcome>"

