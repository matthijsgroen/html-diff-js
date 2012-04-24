
describe "Html diff disregarding markup", ->

  describe "aggretateDiff", ->

    it "concats changes", ->
      diff = [
        [DIFF_INSERT, "hello "],
        [DIFF_INSERT, " there"],
        [DIFF_EQUAL, "nice "],
        [DIFF_EQUAL, "sentence"],
        [DIFF_DELETE, "to "],
        [DIFF_DELETE, "split"]]

      expected = [
        [DIFF_INSERT, "hello  there"],
        [DIFF_EQUAL, "nice sentence"],
        [DIFF_DELETE, "to split"]]

      actual = HtmlDiff.aggregateDiff diff
      expect(actual).toEqual expected

    it "includes spaces in changes", ->
      diff = [
        [DIFF_INSERT, "hello"],
        [DIFF_EQUAL, " "],
        [DIFF_EQUAL, " "],
        [DIFF_INSERT, "there"],
        [DIFF_EQUAL, "nice"],
        [DIFF_EQUAL, " "],
        [DIFF_EQUAL, "sentence"],
        [DIFF_DELETE, "to"],
        [DIFF_EQUAL, " "],
        [DIFF_DELETE, "split"]]

      expected = [
        [DIFF_INSERT, "hello  there"],
        [DIFF_EQUAL, "nice sentence"],
        [DIFF_DELETE, "to split"]]

      actual = HtmlDiff.aggregateDiff diff
      expect(actual).toEqual expected

    it "respects unchanged words", ->
      diff = [
        [DIFF_EQUAL, "Understand"],
        [DIFF_EQUAL, " "],
        [DIFF_INSERT, "&lt;p&gt;"],
        [DIFF_EQUAL, " "],
        [DIFF_EQUAL, "your"],
        [DIFF_EQUAL, " "],
        [DIFF_INSERT, "&lt;html/&gt;"],
        [DIFF_EQUAL, " "],
        [DIFF_EQUAL, "sleep"]]

      expected = [
        [DIFF_EQUAL, "Understand "],
        [DIFF_INSERT, "&lt;p&gt;"],
        [DIFF_EQUAL, " your "],
        [DIFF_INSERT, "&lt;html/&gt;"],
        [DIFF_EQUAL, " sleep"]]

      actual = HtmlDiff.aggregateDiff diff
      expect(actual).toEqual expected
