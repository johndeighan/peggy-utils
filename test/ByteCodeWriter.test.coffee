# --- ByteCodeWriter.test.offee

import * as lib from '@jdeighan/peggy-utils/ByteCodeWriter'
Object.assign(global, lib)
import test from 'ava'

# ---------------------------------------------------------------------------

test "line 9", (t) =>

	bcw = new ByteCodeWriter('dummy')
	bcw.setAST({
		type: 'grammar'
		rules: [
			'abc'
			]
		})
	t.deepEqual bcw.getOpInfo(35), ['PUSH_EMPTY_STRING', [], []]

# ---------------------------------------------------------------------------

test "line 22", (t) =>

	bcw = new ByteCodeWriter()
	bcw.setAST({
		type: 'grammar'
		rules: [1,2,3] # only length is checked
		literals: [
			"abc",
			"def"
			],
		expectations: [
			{
				"type": "literal",
				"value": "abc",
				"ignoreCase": false
				},
			{
				"type": "literal",
				"value": "def",
				"ignoreCase": false
				}
			],
		})
	bcw.add('start', [27, 1, 14, 3, 0, 6, 27, 2])
	t.is bcw.getBlock(), """
		<start>
			RULE <#1>
			IF_ERROR
				POP
				RULE <#2>
		"""

# ---------------------------------------------------------------------------

test "line 56", (t) =>

	bcw = new ByteCodeWriter()
	bcw.setAST({
		type: 'grammar'
		rules: ['start','first','second'] # only length is checked
		literals: [
			"abc",
			"def"
			],
		expectations: [
			{
				"type": "literal",
				"value": "abc",
				"ignoreCase": false
				},
			{
				"type": "literal",
				"value": "def",
				"ignoreCase": false
				}
			],
		})
	bcw.add('first', [18, 0, 2, 2, 22, 0, 23, 0])
	t.is bcw.getBlock(), """
		<first>
			MATCH_STRING 'abc'
				ACCEPT_STRING 'abc'
			ELSE
				FAIL "abc"
		"""

# ---------------------------------------------------------------------------

test "line 90", (t) =>

	bcw = new ByteCodeWriter()
	bcw.setAST({
		type: 'grammar'
		rules: ['start','first','second'] # only length is checked
		literals: [
			"abc",
			"def"
			],
		expectations: [
			{
				"type": "literal",
				"value": "abc",
				"ignoreCase": false
				},
			{
				"type": "literal",
				"value": "def",
				"ignoreCase": false
				}
			],
		})
	bcw.add('second', [18, 1, 2, 2, 22, 1, 23, 1])
	t.is bcw.getBlock(), """
		<second>
			MATCH_STRING 'def'
				ACCEPT_STRING 'def'
			ELSE
				FAIL "def"
		"""

# ---------------------------------------------------------------------------

test "line 124", (t) =>

	bcw = new ByteCodeWriter()
	bcw.setAST({
		type: 'grammar'
		rules: [1,2,3] # only length is checked
		literals: [
			"abc",
			"def"
			],
		expectations: [
			{
				"type": "literal",
				"value": "abc",
				"ignoreCase": false
				},
			{
				"type": "literal",
				"value": "def",
				"ignoreCase": false
				}
			],
		})
	bcw.add('start', [27, 1, 14, 3, 0, 6, 27, 2])
	bcw.add('first', [18, 0, 2, 2, 22, 0, 23, 0])
	bcw.add('second', [18, 1, 2, 2, 22, 1, 23, 1])
	t.is bcw.getBlock(), """
		<start>
			RULE <first>
			IF_ERROR
				POP
				RULE <second>

		<first>
			MATCH_STRING 'abc'
				ACCEPT_STRING 'abc'
			ELSE
				FAIL "abc"

		<second>
			MATCH_STRING 'def'
				ACCEPT_STRING 'def'
			ELSE
				FAIL "def"
		"""
