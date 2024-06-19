# ByteCodeWriter.coffee

import fs from 'node:fs'
import {
	undef, defined, notdefined, isString,
	assert, croak, range, indented, undented,
	} from '@jdeighan/vllu'

# ---------------------------------------------------------------------------

export class ByteCodeWriter

	constructor: (@name, hOptions={}) ->

		@hRules = {}
		@hCounts = {}
		@lOpcodes = undef
		@detailed = hOptions.detailed

	# ..........................................................

	setAST: (ast) ->

		assert (ast.type == 'grammar'), "not a grammar"
		assert (ast.rules.length > 0), "no rules"
		@ast = ast
		return

	# ..........................................................

	getOpInfo: (op) ->

		switch op
			when 35 then return ['PUSH_EMPTY_STRING']
			when 5  then return ['PUSH_CUR_POS']
			when 1  then return ['PUSH_UNDEFINED']
			when 2  then return ['PUSH_NULL']
			when 3  then return ['PUSH_FAILED']
			when 4  then return ['PUSH_EMPTY_ARRAY']
			when 6  then return ['POP']
			when 7  then return ['POP_CUR_POS']
			when 8  then return ['POP_N', '/number']
			when 9  then return ['NIP']
			when 10 then return ['APPEND']
			when 11 then return ['WRAP', undef]
			when 12 then return ['TEXT']
			when 36 then return ['PLUCK', undef, undef, undef, 'p']
			when 13 then return ['IF', 'OK/block','FAIL/block']
			when 14 then return ['IF_ERROR', 'OK/block','FAIL/block']
			when 15 then return ['IF_NOT_ERROR', 'OK/block','FAIL/block']
			when 30 then return ['IF_LT', 'OK/block','FAIL/block']
			when 31 then return ['IF_GE', 'OK/block','FAIL/block']
			when 32 then return ['IF_LT_DYNAMIC', 'OK/block','FAIL/block']
			when 33 then return ['IF_GE_DYNAMIC', 'OK/block','FAIL/block']
			when 16 then return ['WHILE_NOT_ERROR', 'OK/block']
			when 17 then return ['MATCH_ANY', 'OK/block','FAIL/block']
			when 18 then return ['MATCH_STRING', '/literal', 'OK/block', 'FAIL/block']
			when 19 then return ['MATCH_STRING_IC', '/literal', 'OK/block', 'FAIL/block']
			when 20 then return ['MATCH_CHAR_CLASS', '/class']
			when 21 then return ['ACCEPT_N', '/number']
			when 22 then return ['ACCEPT_STRING', '/literal']
			when 23 then return ['FAIL', '/expectation']
			when 24 then return ['LOAD_SAVED_POS', 'pos/number']
			when 25 then return ['UPDATE_SAVED_POS', 'pos/number']
			when 26 then return ['CALL']
			when 27 then return ['RULE', '/rule']
			else
				return undefined

	# ..........................................................

	argStr: (arg, infoStr) ->

		if (infoStr == undef)
			return arg.toString()

		[label, type] = infoStr.split('/')

		switch type

			when 'rule'
				if (typeof(arg) == 'number') && (arg < @ast.rules.length)
					result = "<#{@ast.rules[arg].name}>"
				else
					result = "<UNKNOWN RULE #{arg}>"

			when 'literal'
				result = "'#{@ast.literals[arg]}'"

			when 'number'
				result = arg.toString()

			when 'expectation'
				hExpect = @ast.expectations[arg]
				{type, value} = hExpect
				switch type
					when 'literal'
						result = "\"#{value}\""
					when 'class'
						result = "[..]"
					when 'any'
						result = '.'
					else
						croak "Unknown expectation type: #{type}"
			when 'block'
				if label
					result = "#{label}:#{arg}"
				else
					result = "BLOCK: #{arg}"

			when 'class'
				if label
					result = "#{label}:[#{arg}]"
				else
					result = "CLASS: #{arg}"

			else
				croak "argStr(): unknown type #{type}"

		if @detailed
			return "(#{arg}) #{result}"
		else
			return result

	# ..........................................................

	opStr: (lOpcodes) ->

		lLines = []
		pos = 0
		nOpcodes = lOpcodes.length
		while (pos < nOpcodes)
			op = lOpcodes[pos]
			pos += 1

			lInfo = @getOpInfo(op)
			if notdefined(lInfo)
				lLines.push "OPCODE #{op}"
				continue
			name = lInfo[0]
			if lInfo[1]
				lArgInfo = lInfo.slice(1)
			else
				lArgInfo = []

			if notdefined(lArgInfo)
				lArgInfo = []
			numArgs = lArgInfo.length

			lArgs = lOpcodes.slice(pos, pos + numArgs)
			pos += numArgs
			lArgDesc = lArgs.map (arg,i) => @argStr(arg, lArgInfo[i])

			if @detailed
				lLines.push "(#{op}) #{name}#{' ' + lArgDesc.join(' ')}"
			else
				lLines.push "#{name}#{' ' + lArgDesc.join(' ')}"

			for arg,i in lArgs
				infoStr = lArgInfo[i]
				if notdefined(infoStr)
					continue
				if infoStr.includes('/')
					[label, type] = infoStr.split('/')
					if (type == 'block')
						lLines.push indented("[#{label}]")

						# --- NOTE: arg is the length of the block in bytes
						lSubOps = lOpcodes.slice(pos, pos+arg)
						pos += arg
						lLines.push indented(@opStr(lSubOps), 2)

		return lLines.join("\n")

	# ..........................................................

	add: (ruleName, lOpcodes) ->

		assert (typeof ruleName == 'string'), "not a string"
		assert Array.isArray(lOpcodes), "not an array"
		assert !@hRules[ruleName], "rule #{ruleName} already defined"
		@hRules[ruleName] = lOpcodes
		return

	# ..........................................................

	write: () ->
		lParts = []
		for ruleName in Object.keys(@hRules)
			lParts.push "#{ruleName}:"
			lOpcodes = @hRules[ruleName]
			lParts.push indented(@opStr(lOpcodes))
			lParts.push ''
		fileName = "./#{@name}.bytecodes.txt"
		console.log "Writing bytecodes to #{fileName}"
		fs.writeFileSync(fileName, lParts.join("\n"))
		return
