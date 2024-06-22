# peggify.coffee

import fs from 'node:fs'
import {execSync} from 'node:child_process'

pkg = await import('peggy')
{generate} = pkg.default

import {assert} from '@jdeighan/llutils'
import {withExt} from '@jdeighan/llutils/fs'
import {DefaultTracer} from '@jdeighan/peggy-utils'
import {OpDumper} from '@jdeighan/peggy-utils/OpDumper'
import {ByteCodeWriter} from '@jdeighan/peggy-utils/ByteCodeWriter'

# ---------------------------------------------------------------------------

filePath = process.argv[2]
assert fs.existsSync(filePath), "No such file: #{filePath}"
fileName = filePath.split(/[\\\/]/).at(-1)
if lMatches = fileName.match(/^[a-zA-z0-9_-]*/)
	stub = lMatches[0]
else
	stub = 'unknown'

peggyCode = fs.readFileSync(filePath, 'utf8') \
		.toString() \
		.replaceAll('\r', '')

byteCodeWriter = new ByteCodeWriter(stub, {detailed: false})
opDumper = new OpDumper(stub)

jsCode = generate(peggyCode, {
	allowedStartRules: ['*']
	format: 'es'
	output: 'source'
	grammarSource: filePath
	trace: true
	dumpAST: withExt(filePath, ".ast.txt")    # --- "./#{stub}.ast.txt"
	byteCodeWriter
	opDumper
	})

byteCodeWriter.writeTo(withExt(filePath, '.bytecodes.txt'))
opDumper.writeTo(withExt(filePath, '.opcodes.txt'))

outFilePath = withExt(filePath, '.js')
console.log "Writing file '#{outFilePath}"
fs.writeFileSync(outFilePath, jsCode)

# --- Check if JS file compiles
console.log execSync("node -c #{outFilePath}", {
	encoding: 'utf8'
	windowsHide: true
	})
