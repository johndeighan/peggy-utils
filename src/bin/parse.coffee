# parse.coffee

import {DefaultTracer} from '@jdeighan/peggy-utils'
[a, b, name, str] = process.argv
{parse} = await import("../../#{name}.js")

try
	# --- Available options:
	#        grammerSource
	#        peg$currPos
	#        peg$maxFailExpected
	#        peg$silentFails
	#        tracer
	#        startRule
	#        peg$library

	result = parse(str, {tracer: DefaultTracer})
	console.log "RESULT: #{JSON.stringify(result)}"
catch err
	console.log "PARSE FAILED"
	console.dir err
