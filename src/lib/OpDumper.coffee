# OpDumper.coffee

import fs from 'node:fs'
import {
	undef, defined, notdefined, isString,
	assert, croak, range,
	} from '@jdeighan/llutils'
import {indented, undented} from '@jdeighan/llutils/indent'

# ---------------------------------------------------------------------------
# --- valid options:
#        char - char to use on left and right
#        buffer - num spaces around text when char <> ' '

export centered = (text, width, hOptions={}) =>

	{char} = hOptions

	numBuffer = hOptions.numBuffer || 2

	totSpaces = width - text.length
	if (totSpaces <= 0)
		return text
	numLeft = Math.floor(totSpaces / 2)
	numRight = totSpaces - numLeft
	if (char == ' ')
		return spaces(numLeft) + text + spaces(numRight)
	else
		buf = ' '.repeat(numBuffer)
		left = char.repeat(numLeft - numBuffer)
		right = char.repeat(numRight - numBuffer)
		numLeft -= numBuffer
		numRight -= numBuffer
		return left + buf + text + buf + right

# --------------------------------------------------------------------------

export class OpDumper

	constructor: (@name) ->

		@level = 0
		@lLines = []

	# ..........................................................

	setStack: (stack) ->

		@stack = stack
		return

	# ..........................................................

	incLevel: () -> @level += 1
	decLevel: () -> @level -= 1

	# ..........................................................

	out: (str) ->
		@lLines.push "  ".repeat(@level) + str
		return

	# ..........................................................

	outBC: (lByteCodes) ->

		@out 'OPCODES: ' + lByteCodes.map((x) => x.toString()).join(' ');
		return

	# ..........................................................

	outCode: (lLines, label) ->

		width = 34
		if ! label then label = "UNKNOWN"
		@out centered(label, width, {char: '-'})
		for line in lLines
			@out line
		@out '-'.repeat(width)
		return

	# ..........................................................

	contents: () ->

		return @lLines.join("\n")

	# ..........................................................

	writeTo: (filePath) ->

		console.log "Writing opcodes to #{filePath}"
		fs.writeFileSync(filePath, @contents())
		return
