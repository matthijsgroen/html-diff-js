
describe "Html diff disregarding markup", ->

  describe "makeSmallestMarkupChanges", ->

    it "splits changes per word", ->
      diff = [[DIFF_EQUAL, "nice  sentence"]]

      expected = [
        [DIFF_EQUAL, "nice"],
        [DIFF_EQUAL, "  "],
        [DIFF_EQUAL, "sentence"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

    it "splits content before optimizing", ->
      diff = [[DIFF_DELETE, "12 <h1>Dear"],
        [DIFF_INSERT, "12 <h1>Hello"]]

      expected = [
        [DIFF_EQUAL, "12"],
        [DIFF_EQUAL, " "],
        [DIFF_EQUAL, "<h1>"],
        [DIFF_DELETE, "Dear"],
        [DIFF_INSERT, "Hello"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

    it "splits content before optimizing with uneven balance", ->
      diff = [[DIFF_DELETE, " <h1>Dear"],
        [DIFF_INSERT, "<h1>\tHello"]]

      expected = [
        [DIFF_DELETE, " "],
        [DIFF_EQUAL, "<h1>"],
        [DIFF_DELETE, "Dear"],
        [DIFF_INSERT, "\t"],
        [DIFF_INSERT, "Hello"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

    it "keeps separators", ->
      diff = [
        [DIFF_INSERT, "  hello  there"],
        [DIFF_EQUAL, "nice  sentence"],
        [DIFF_DELETE, "to split"]]

      expected = [
        [DIFF_INSERT, "  "],
        [DIFF_INSERT, "hello"],
        [DIFF_INSERT, "  "],
        [DIFF_INSERT, "there"],
        [DIFF_EQUAL, "nice"],
        [DIFF_EQUAL, "  "],
        [DIFF_EQUAL, "sentence"],
        [DIFF_DELETE, "to"],
        [DIFF_DELETE, " "],
        [DIFF_DELETE, "split"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

    it "sees html tags as separator", ->
      diff = [[DIFF_INSERT, "<h1>he llo</h1><p>there"]]

      expected = [
        [DIFF_INSERT, "<h1>"],
        [DIFF_INSERT, "he"],
        [DIFF_INSERT, " "],
        [DIFF_INSERT, "llo"],
        [DIFF_INSERT, "</h1>"],
        [DIFF_INSERT, "<p>"],
        [DIFF_INSERT, "there"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

    it "optimizes insertions", ->
      diff = [
        [DIFF_DELETE, "splitted"],
        [DIFF_INSERT, "we splitted stuff"]
      ]

      expected = [
        [DIFF_INSERT, "we"],
        [DIFF_INSERT, " "],
        [DIFF_EQUAL, "splitted"],
        [DIFF_INSERT, " "],
        [DIFF_INSERT, "stuff"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

    it "optimizes deletions", ->
      diff = [
        [DIFF_DELETE, "we splitted  stuff"],
        [DIFF_INSERT, "splitted"]
      ]

      expected = [
        [DIFF_DELETE, "we"],
        [DIFF_DELETE, " "],
        [DIFF_EQUAL, "splitted"],
        [DIFF_DELETE, "  "],
        [DIFF_DELETE, "stuff"]]

      actual = HtmlDiff.makeSmallestMarkupChanges diff
      expect(actual).toEqual expected

