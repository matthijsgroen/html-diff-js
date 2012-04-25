
describe "Html diff disregarding markup", ->
  describe "formatTextdiff", ->

    it "detects insertions", ->
      original = "Hello how is it?"
      final = "Hello how is it out there?"
      expected = "Hello how is it <ins>out there</ins>?"

      expect(HtmlDiff.formatTextDiff original, final).toEqual expected

    it "detects deletions", ->
      original = "Hello how is it out there?"
      final = "Hello how is it?"
      expected = "Hello how is it<del> out there</del>?"

      expect(HtmlDiff.formatTextDiff original, final).toEqual expected

    it "detects swaps", ->
      original = "Hello how is it out there?"
      final = "Hello how is it in here?"
      expected = "Hello how is it <del>out t</del><ins>in</ins> here?"

      expect(HtmlDiff.formatTextDiff original, final).toEqual expected

    it "detects correct insertions using entities", ->
      original = "<h2>Dear Wendy,</h2><h2>Understand your knitting patterns </h2>You completed"
      final = "<h2>Dear Wendy,</h2><h2>Understand &lt;p&gt; your &lt;html/&gt; knitting patterns </h2>You completed"
      expected = "<h2>Dear Wendy,</h2><h2>Understand <ins>&lt;p&gt;</ins> your <ins>&lt;html/&gt;</ins> knitting patterns </h2>You completed"

      expect(HtmlDiff.formatTextDiff original, final).toEqual expected

    it "ignores html markup changes", ->
      original = "<h1>Hello<p>how is it out there?"
      final = "<h1>Hello</h1><p>how is <em>it</em> out there?</p>"
      expected = "<h1>Hello</h1><p>how is <em>it</em> out there?</p>"

      expect(HtmlDiff.formatTextDiff original, final).toEqual expected

    describe "mapping changes in marked up final", ->

      it "places changed parts in correct markup piece", ->
        original = "<h1>Hello<p>how is <em>it</em> out there?</p>"
        final = "<h1>Hello there</h1><p>And how is <em>it</em> out there?</p>"
        expected = "<h1>Hello <ins>there</ins></h1><p><ins>And</ins> how is <em>it</em> out there?</p>"

        expect(HtmlDiff.formatTextDiff original, final).toEqual expected

      it "ignores matches in html tags", ->
        original = "<h1>Hello<p>how is <em>it</em> out there?</p>"
        final = "<h1>Hello</h1><p>&nbsp;</p><p>p how is <em>it</em> out there?</p>"
        expected = "<h1>Hello</h1><p>&nbsp;</p><p><ins>p</ins> how is <em>it</em> out there?</p>"

        expect(HtmlDiff.formatTextDiff original, final).toEqual expected

      it "entities are respected", ->
        original = "<h1>Hello</h1><p>how is out there?</p>"
        final = "<h1>Hello</h1><p>how is &lt;html&gt; out there?</p>"
        expected = "<h1>Hello</h1><p>how is <ins>&lt;html&gt;</ins> out there?</p>"

        expect(HtmlDiff.formatTextDiff original, final).toEqual expected
