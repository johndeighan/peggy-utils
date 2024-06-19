# OpDumper.coffee

import fs from 'node:fs'
import {
	undef, defined, notdefined, isString,
	assert, croak, range, indented, undented,
	} from '@jdeighan/vllu'

# --------------------------------------------------------------------------

export class OpDumper

	constructor: (@name) ->

		@level = 0
		@lLines = []

	# ..........................................................

	incLevel: () -> @level += 1
	decLevel: () -> @level -= 1

	# ..........................................................

	out: (str) ->
		@lLines.push "  ".repeat(@level) + str
		return

	# ..........................................................

	outBC: (lByteCodes) ->

		@out 'OPCODES:'
		@out lByteCodes.map((x) => x.toString()).join(' ');
		return

	# ..........................................................

	contents: () ->

		return @lLines.join("\n")

	# ..........................................................

	write: () ->

		fileName = "./#{@name}.opcodes.txt"
		console.log "Writing opcodes to #{fileName}"
		fs.writeFileSync(fileName, @contents())
		return
