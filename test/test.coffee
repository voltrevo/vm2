{VM, NodeVM} = require '../'
assert = require "assert"

vm = null

describe 'contextify', ->
	before (done) ->
		vm = new VM
			sandbox:
				test:
					string: "text"
					stringO: new String "text"
					number: 1
					numberO: new Number 1
					boolean: true
					booleanO: new Boolean true
					date: new Date()
					regexp: /xxx/
					buffer: new Buffer 0
					function: ->
					object: {x: 1}
					
		done()
		
	it 'string', (done) ->
		assert.equal vm.run("typeof(test.stringO) === 'string' && test.string.valueOf instanceof Object"), true
		done()
	
	it 'number', (done) ->
		assert.equal vm.run("typeof(test.numberO) === 'number' && test.number.valueOf instanceof Object"), true
		done()
	
	it 'boolean', (done) ->
		assert.equal vm.run("typeof(test.booleanO) === 'boolean' && test.boolean.valueOf instanceof Object"), true
		done()
	
	it 'date', (done) ->
		assert.equal vm.run("test.date instanceof Date"), true
		done()
	
	it 'regexp', (done) ->
		assert.equal vm.run("test.regexp instanceof RegExp"), true
		done()
	
	it 'buffer', (done) ->
		assert.equal vm.run("test.buffer"), null
		done()
	
	it 'function', (done) ->
		assert.equal vm.run("test.function instanceof Function"), true
		done()
	
	it 'object', (done) ->
		assert.equal vm.run("test.object instanceof Object && test.object.x === 1"), true
		done()
	
	after (done) ->
		vm = null
		done()

describe 'VM', ->
	before (done) ->
		vm = new VM
			sandbox:
				round: (number) ->
					Math.round number
					
		done()

	it 'globals', (done) ->
		assert.equal vm.run("round(1.5)"), 2
		
		done()
		
	it 'errors', (done) ->
		assert.throws ->
			vm.run "notdefined"
		, /notdefined is not defined/
		
		done()

	it 'timeout', (done) ->
		assert.throws ->
			new VM(timeout: 10).run "while (true) {}"
		, /Script execution timed out\./

		done()
	
	after (done) ->
		vm = null
		done()

describe 'NodeVM', ->
	before (done) ->
		vm = new NodeVM
					
		done()
		
	it 'globals', (done) ->
		vm.run "module.exports = global"
		assert.equal vm.module.exports.isVM, true
		
		done()

	it 'errors', (done) ->
		assert.throws ->
			vm.run "notdefined"
		, /notdefined is not defined/
		
		done()
		
	it 'prevent global access', (done) ->
		assert.throws ->
			vm.run "process.exit()"
		, /Object #<Object> has no method 'exit'/
		
		done()
	
	it 'arguments attack', (done) ->
		assert.throws ->
			console.log vm.run("(function() {return arguments.callee.caller.toString()})()")
		, /Cannot call method 'toString' of null/
		
		done()
	
	it 'global attack', (done) ->
		assert.equal vm.run("console.log.constructor('return (function(){return this})().SANDBOX')()"), true
		
		done()
	
	after (done) ->
		vm = null
		done()

describe 'modules', ->
	it 'require json', (done) ->
		vm = new NodeVM
			require: true
			requireExternal: true
		
		assert.equal vm.run("module.exports = require('#{__dirname}/data/json.json')").working, true
		
		done()
	
	it.skip 'require coffee-script (not supported atm)', (done) ->
		vm = new NodeVM
			require: true
			requireExternal: true
		
		assert.equal vm.run("require('coffee-script'); module.exports = require('#{__dirname}/data/coffee.coffee')", __filename).working, true
		
		done()
		
	it 'disabled require', (done) ->
		vm = new NodeVM
		
		assert.throws ->
			vm.run "require('fs')"
		, /Access denied to require 'fs'/
		
		done()
		
	it 'enabled require for certain modules', (done) ->
		vm = new NodeVM
			require: true
			requireNative: ['fs']
		
		assert.doesNotThrow ->
			vm.run "require('fs')"
		
		done()

	it 'arguments attack', (done) ->
		vm = new NodeVM
		assert.doesNotThrow ->
			vm.run "module.exports.fce = function fce(msg) { arguments.callee.caller.toString(); }"
			
			# direct call, bad practice
			vm.module.exports.fce()
		
		vm = new NodeVM
		assert.throws ->
			vm.run "module.exports.fce = function fce(msg) { arguments.callee.caller.toString(); }"
			
			# proxied call, good practice
			vm.call vm.module.exports.fce
		, /Cannot call method 'toString' of null/
		
		vm = new NodeVM
		assert.throws ->
			vm.run "module.exports.fce = function fce(msg) { fce.caller.toString(); }"
			
			# proxied call, good practice
			vm.call vm.module.exports.fce
		, /Cannot call method 'toString' of null/
		
		done()
	
	after (done) ->
		vm = null
		done()