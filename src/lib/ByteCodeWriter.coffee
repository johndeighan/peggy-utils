# ByteCodeWriter.coffee

import fs from 'node:fs'
import {
	undef, defined, notdefined, isString, untabify,
	assert, croak, range, pass,
	} from '@jdeighan/llutils'
import {indented, undented} from '@jdeighan/llutils/indent'
# pass = () =>

# ---------------------------------------------------------------------------

export class ByteCodeWriter

	constructor: (@name, hOptions={}) ->

		@lRuleNames = [];
		@hRules = {}

		# --- These are set when the AST is known
		@literals = undef
		@expectations = undef

		# --- options
		@detailed = hOptions.detailed

	# ..........................................................

	setAST: (ast) ->

		assert (ast.type == 'grammar'), "not a grammar"
		assert (ast.rules.length > 0), "no rules"
		@literals = ast.literals
		@expectations = ast.expectations
		return

	# ..........................................................

	add: (ruleName, lOpcodes) ->

		assert (typeof ruleName == 'string'), "not a string"
		assert Array.isArray(lOpcodes), "not an array"
		assert !@hRules[ruleName], "rule #{ruleName} already defined"
		@lRuleNames.push ruleName
		@hRules[ruleName] = lOpcodes
		return

	# ..........................................................

	getOpInfo: (op, pos) ->

		switch op
			when 35 then return ['PUSH_EMPTY_STRING', [],              []]
			when 5  then return ['PUSH_CUR_POS',      [],              []]
			when 1  then return ['PUSH_UNDEFINED',    [],              []]
			when 2  then return ['PUSH_NULL',         [],              []]
			when 3  then return ['PUSH_FAILED',       [],              []]
			when 4  then return ['PUSH_EMPTY_ARRAY',  [],              []]
			when 6  then return ['POP',               [],              []]
			when 7  then return ['POP_CUR_POS',       [],              []]
			when 8  then return ['POP_N',             ['/'],           []]
			when 9  then return ['NIP',               [],              []]
			when 10 then return ['APPEND',            [],              []]
			when 11 then return ['WRAP',              [''],            []]
			when 12 then return ['TEXT',              [],              []]
			when 36 then return ['PLUCK',             ['/','/','/','p'], []]
			when 13 then return ['IF',                [],              ['THEN', 'ELSE']]
			when 14 then return ['IF_ERROR',          [],              ['THEN', 'ELSE']]
			when 15 then return ['IF_NOT_ERROR',      [],              ['THEN', 'ELSE']]
			when 30 then return ['IF_LT',             [],              ['THEN', 'ELSE']]
			when 31 then return ['IF_GE',             [],              ['THEN', 'ELSE']]
			when 32 then return ['IF_LT_DYNAMIC',     [],              ['THEN', 'ELSE']]
			when 33 then return ['IF_GE_DYNAMIC',     [],              ['THEN', 'ELSE']]
			when 16 then return ['WHILE_NOT_ERROR',   [],              ['THEN']]
			when 17 then return ['MATCH_ANY',         [],              ['THEN', 'ELSE']]
			when 18 then return ['MATCH_STRING',      ['/lit'],        ['THEN', 'ELSE']]
			when 19 then return ['MATCH_STRING_IC',   ['/lit'],        ['THEN', 'ELSE']]
			when 20 then return ['MATCH_CHAR_CLASS',  ['/class'],      []]
			when 21 then return ['ACCEPT_N',          ['/num'],        []]
			when 22 then return ['ACCEPT_STRING',     ['/lit'],        []]
			when 23 then return ['FAIL',              ['/expectation'],[]]
			when 24 then return ['LOAD_SAVED_POS',    ['pos/num'],     []]
			when 25 then return ['UPDATE_SAVED_POS',  ['pos/num'],     []]
			when 26 then return ['CALL',              [],              []]
			when 27 then return ['RULE',              ['/rule'],       []]
			else
				croak "Unknown opcode: #{op} at pos #{pos}"

	# ..........................................................

	argStr: (arg, infoStr) ->

		if (infoStr == '/')
			return arg.toString()

		[label, type] = infoStr.split('/')

		switch type

			when 'rule'
				if (arg < @lRuleNames.length)
					result = "<#{@lRuleNames[arg]}>"
				else
					result = "<##{arg}>"

			when 'lit'
				result = "'#{@literals[arg]}'"

			when 'num','i'
				result = arg.toString()

			when 'expectation'
				hExpect = @expectations[arg]
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

		debugger
		lLines = []
		pos = 0
		while (pos < lOpcodes.length)
			op = lOpcodes[pos]
			pos += 1

			[name, lArgInfo, lBlockInfo] = @getOpInfo(op, pos)
			numArgs = lArgInfo.length
			if (numArgs == 0)
				if @detailed
					lLines.push "(#{op}) #{name}"
				else
					lLines.push "#{name}"
			else
				lArgs = lOpcodes.slice(pos, pos + numArgs)
				pos += numArgs
				lArgDesc = lArgs.map (arg,i) => @argStr(arg, lArgInfo[i])
				if @detailed
					lLines.push "(#{op}) #{name} #{lArgDesc.join(' ')}"
				else
					lLines.push "#{name} #{lArgDesc.join(' ')}"

			blockBase = pos + lBlockInfo.length
			for label,i in lBlockInfo
				blockLen = lOpcodes[pos]
				pos += 1

				switch label
					when 'ELSE'
						if (blockLen > 0)
							lLines.push 'ELSE'
					when 'THEN'
						pass()
					else
						croak "Bad block label: #{label}"

				lSubOps = lOpcodes.slice(blockBase, blockBase + blockLen)
				lLines.push indented(@opStr(lSubOps))
				blockBase += blockLen
			pos = blockBase
		return lLines.join("\n")

	# ..........................................................

	getBlock: () ->

		lParts = []
		for ruleName in Object.keys(@hRules)
			lParts.push "<#{ruleName}>"
			lOpcodes = @hRules[ruleName]
			block = @opStr(lOpcodes).trimEnd()
			if (block != '')
				lParts.push indented(block)
			lParts.push ''
		return lParts.join("\n").trimEnd()

	# ..........................................................

	writeTo: (filePath) ->

		console.log "Writing bytecodes to #{filePath}"
		fs.writeFileSync(filePath, @getBlock())
		return
