path = require 'path'
GrammarRegistry = require '../lib/grammar-registry'

describe "GrammarRegistry", ->
  registry = null

  loadGrammarSync = (name) ->
    registry.loadGrammarSync(path.join(__dirname, 'fixtures', name))

  describe "grammar overrides", ->
    it "stores the override scope name for a path", ->
      registry = new GrammarRegistry()

      expect(registry.grammarOverrideForPath('foo.js.txt')).toBeUndefined()
      expect(registry.grammarOverrideForPath('bar.js.txt')).toBeUndefined()

      registry.setGrammarOverrideForPath('foo.js.txt', 'source.js')
      expect(registry.grammarOverrideForPath('foo.js.txt')).toBe 'source.js'

      registry.setGrammarOverrideForPath('bar.js.txt', 'source.coffee')
      expect(registry.grammarOverrideForPath('bar.js.txt')).toBe 'source.coffee'

      registry.clearGrammarOverrideForPath('foo.js.txt')
      expect(registry.grammarOverrideForPath('foo.js.txt')).toBeUndefined()
      expect(registry.grammarOverrideForPath('bar.js.txt')).toBe 'source.coffee'

      registry.clearGrammarOverrides()
      expect(registry.grammarOverrideForPath('bar.js.txt')).toBeUndefined()

      registry.setGrammarOverrideForPath('', 'source.coffee')
      expect(registry.grammarOverrideForPath('')).toBeUndefined()

      registry.setGrammarOverrideForPath(null, 'source.coffee')
      expect(registry.grammarOverrideForPath(null)).toBeUndefined()

      registry.setGrammarOverrideForPath(undefined, 'source.coffee')
      expect(registry.grammarOverrideForPath(undefined)).toBeUndefined()

  describe "::selectGrammar", ->
    it "always returns a grammar", ->
      registry = new GrammarRegistry()
      expect(registry.selectGrammar().scopeName).toBe 'text.plain.null-grammar'

    it "selects the text.plain grammar over the null grammar", ->
      registry = new GrammarRegistry()
      loadGrammarSync('text.json')

      expect(registry.selectGrammar('test.txt').scopeName).toBe 'text.plain'

    it "selects a grammar based on the file path case insensitively", ->
      registry = new GrammarRegistry()
      loadGrammarSync('javascript.json')
      loadGrammarSync('coffee-script.json')

      expect(registry.selectGrammar('/tmp/source.coffee').scopeName).toBe 'source.coffee'
      expect(registry.selectGrammar('/tmp/source.COFFEE').scopeName).toBe 'source.coffee'

  describe "when the grammar has no scope name", ->
    it "throws an error", ->
      grammarPath = path.join(__dirname, 'fixtures', 'no-scope-name.json')
      registry = new GrammarRegistry()
      expect(-> registry.loadGrammarSync(grammarPath)).toThrow()

      callback = jasmine.createSpy('callback')
      registry.loadGrammar(grammarPath, callback)

      waitsFor ->
        callback.callCount is 1

      runs ->
        expect(callback.argsForCall[0][0].message.length).toBeGreaterThan 0

  describe "maxTokensPerLine option", ->
    it "set the value on each created grammar and limits the number of tokens per line to that value", ->
      registry = new GrammarRegistry(maxTokensPerLine: 2)
      loadGrammarSync('json.json')

      grammar = registry.selectGrammar('test.json')
      expect(grammar.maxTokensPerLine).toBe 2

      {tokens} = grammar.tokenizeLine("{ }")
      expect(tokens.length).toBe 2
