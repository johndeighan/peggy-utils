# PeggyTracers.coffee

import {
	undef, defined, notdefined, isString, isArray, isHash,
	assert, croak, range, indented, undented,
	isEmpty, nonEmpty, keys, escapeStr,
	} from '@jdeighan/vllu'

# ---------------------------------------------------------------------------

export rpad = (str, len, ch=' ') =>

	assert (ch.length == 1), "Not a char"
	extra = len - str.length
	if (extra < 0) then extra = 0
	return str + ch.repeat(extra)

# ---------------------------------------------------------------------------

export lpad = (str, len, ch=' ') =>

	assert (ch.length == 1), "Not a char"
	extra = len - str.length
	if (extra < 0) then extra = 0
	return ch.repeat(extra) + str

# ---------------------------------------------------------------------------

export zpad = (n, len) =>

	nStr = n.toString()
	return lpad(nStr, len, '0')

# ---------------------------------------------------------------------------

export class NullTracer

	trace: () ->

# ---------------------------------------------------------------------------

export class DefaultTracer extends NullTracer

	constructor: (@inputStr) ->
		super()
		@level = 0

	trace: (event) ->

		switch (event.type)
			when 'rule.enter'
				@log(event)
				@level += 1

			when 'rule.match', 'rule.fail'
				@level -= 1
				@log(event)

			else
				@log(event)

	log: (event) ->

		{type, rule, location, result} = event
		desc = () =>
			[cls, sub] = type.split('.')
			switch cls
				when 'rule'
					return "#{sub} <#{rule}>"
				else
					return type

		locStr = () =>
			if notdefined(location) || !isHash(location)
				return rpad('unknown', 12)
			{start: s, end: e} = location
			sl = zpad(s.line)
			sc = zpad(s.column)
			el = zpad(e.line)
			ec = zpad(e.column)
			return "#{sl}:#{sc}-#{el}:#{ec}"

		if (typeof console == 'object')
			console.log [
				locStr(location)
				'  '.repeat(@level)
				rpad(desc(event), 12)
				result
				].join(' ')

# ---------------------------------------------------------------------------

export class PeggyTracer extends NullTracer

	constructor: () ->

		super()
		@level = 0

	prefix: () ->
		return "│  ".repeat(@level)

	result: () ->
		count = if (@level==0) then 0 else @level-1
		return "│  ".repeat(count) + "└─>"

	# --- This allows unit testing
	traceStr: (hInfo) ->

		{type, rule, location, result} = hInfo
		if defined(location)
			{line, column, offset} = location.start
		switch type

			when 'rule.enter'
				return "#{@prefix()}? #{rule}"

			when 'rule.fail'
				if defined(location)
					return "#{@result()} NO (at #{line}:#{column}:#{offset})"
				else
					return "#{@result()} NO"

			when 'rule.match'
				if defined(result)
					return "#{@result()} #{JSON.stringify(result)}"
				else
					return "#{@result()} YES"
			else
				return "UNKNOWN type: #{type}"
		return

	trace: (hInfo) ->
		# --- ignore whitespace rule
		if (hInfo.rule == '_')
			return

		result = @traceStr(hInfo)
		if isString(result)
			console.log result
		else if isArray(result)
			for str in result
				console.log str

		switch hInfo.type
			when 'rule.enter'
				@level += 1
			when 'rule.fail','rule.match'
				@level -= 1;
		return

# ---------------------------------------------------------------------------

export class DetailedTracer extends PeggyTracer

	constructor: (@input, @hVars={}) ->

		super()

	# ..........................................................

	varStr: () ->

		if isEmpty(@hVars)
			return ''

		lParts = []
		for varname in keys(@hVars)
			value = @hVars[varname]()
			lParts.push "#{varname} = #{JSON.stringify(value)}"
		if (lParts.length == 0)
			return ''
		else
			return ' (' + lParts.join(',') + ')'

	# ..........................................................

	traceStr: (hInfo) ->

		str = super hInfo
		if (hInfo.type != 'rule.fail') || isEmpty(@input)
			return str

		{type, rule, location, result} = hInfo
		if defined(location)
			{offset} = location.start
			return [
				str
				"#{escapeStr(@input, 'esc', {offset})}#{@varStr()}"
				]
		else
			return [
				str
				"#{escapeStr(@input, 'esc')}#{@varStr()}"
				]

# ---------------------------------------------------------------------------
# --- tracer can be:
#        - undef
#        - a string: 'peggy','default','detailed'
#        - an object with a function property named 'trace'
#        - a function

export getTracer = (tracer, input, hVars={}) =>

	if (tracer == null)
		tracer = undef
	switch (typeof tracer)
		when 'undefined'
			return new NullTracer()
		when 'object'
			if hasKey(tracer, trace)
				return tracer
			else
				return new NullTracer()
		when 'function'
			return {trace: tracer}
		when 'string'
			switch tracer
				when 'default'
					return new DefaultTracer()
				when 'detailed'
					return new DetailedTracer(input, hVars)
				when 'peggy'
					return undef
				else
					return new NullTracer()
