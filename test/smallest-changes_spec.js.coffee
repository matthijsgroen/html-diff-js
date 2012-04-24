
describe "Html diff disregarding markup", ->

  describe "makeSmallestPlainChanges", ->

    it "splits changes per word", ->
      diff = [
        [DIFF_INSERT, "hello there"],
        [DIFF_EQUAL, "nice sentence"],
        [DIFF_DELETE, "to split"]]

      expected = [
        [DIFF_INSERT, "hello"],
        [DIFF_INSERT, "there"],
        [DIFF_DELETE, "to"],
        [DIFF_DELETE, "split"]]

      actual = HtmlDiff.makeSmallestPlainChanges diff
      expect(actual).toEqual expected

    it "splits large inserts if it contains the deletion", ->
      diff = [
        [DIFF_DELETE, "splitted"],
        [DIFF_INSERT, "we splitted stuff"]]
      expected = [
        [DIFF_INSERT, "we"],
        [DIFF_INSERT, "stuff"]]

      actual = HtmlDiff.makeSmallestPlainChanges diff
      expect(actual).toEqual expected

    it "splits large deletions if it contains the insertion", ->
      diff = [
        [DIFF_DELETE, "we splitted stuff"],
        [DIFF_INSERT, "splitted"]]
      expected = [
        [DIFF_DELETE, "we"],
        [DIFF_DELETE, "stuff"]]

      actual = HtmlDiff.makeSmallestPlainChanges diff
      expect(actual).toEqual expected

    it "converts characters back to entities", ->
      diff = [
        [DIFF_EQUAL, "We like"],
        [DIFF_INSERT, "<html>"],
        [DIFF_EQUAL, "in our text"]]
      expected = [
        [DIFF_INSERT, "&lt;html&gt;"]]
      actual = HtmlDiff.makeSmallestPlainChanges diff
      expect(actual).toEqual expected
