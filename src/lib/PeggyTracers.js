  // PeggyTracers.coffee
import {
  undef,
  defined,
  notdefined,
  isString,
  isArray,
  isHash,
  assert,
  croak,
  range,
  indented,
  undented,
  isEmpty,
  nonEmpty,
  keys,
  escapeStr
} from '@jdeighan/vllu';

// ---------------------------------------------------------------------------
export var rpad = (str, len, ch = ' ') => {
  var extra;
  assert(ch.length === 1, "Not a char");
  extra = len - str.length;
  if (extra < 0) {
    extra = 0;
  }
  return str + ch.repeat(extra);
};

// ---------------------------------------------------------------------------
export var lpad = (str, len, ch = ' ') => {
  var extra;
  assert(ch.length === 1, "Not a char");
  extra = len - str.length;
  if (extra < 0) {
    extra = 0;
  }
  return ch.repeat(extra) + str;
};

// ---------------------------------------------------------------------------
export var zpad = (n, len) => {
  var nStr;
  nStr = n.toString();
  return lpad(nStr, len, '0');
};

// ---------------------------------------------------------------------------
export var NullTracer = class NullTracer {
  trace() {}

};

// ---------------------------------------------------------------------------
export var DefaultTracer = class DefaultTracer extends NullTracer {
  constructor(inputStr) {
    super();
    this.inputStr = inputStr;
    this.level = 0;
  }

  trace(event) {
    switch (event.type) {
      case 'rule.enter':
        this.log(event);
        return this.level += 1;
      case 'rule.match':
      case 'rule.fail':
        this.level -= 1;
        return this.log(event);
      default:
        return this.log(event);
    }
  }

  log(event) {
    var desc, locStr, location, result, rule, type;
    ({type, rule, location, result} = event);
    desc = () => {
      var cls, sub;
      [cls, sub] = type.split('.');
      switch (cls) {
        case 'rule':
          return `${sub} <${rule}>`;
        default:
          return type;
      }
    };
    locStr = () => {
      var e, ec, el, s, sc, sl;
      if (notdefined(location) || !isHash(location)) {
        return rpad('unknown', 12);
      }
      ({
        start: s,
        end: e
      } = location);
      sl = zpad(s.line);
      sc = zpad(s.column);
      el = zpad(e.line);
      ec = zpad(e.column);
      return `${sl}:${sc}-${el}:${ec}`;
    };
    if (typeof console === 'object') {
      return console.log([locStr(location), '  '.repeat(this.level), rpad(desc(event), 12), result].join(' '));
    }
  }

};

// ---------------------------------------------------------------------------
export var PeggyTracer = class PeggyTracer extends NullTracer {
  constructor() {
    super();
    this.level = 0;
  }

  prefix() {
    return "│  ".repeat(this.level);
  }

  result() {
    var count;
    count = (this.level === 0) ? 0 : this.level - 1;
    return "│  ".repeat(count) + "└─>";
  }

  // --- This allows unit testing
  traceStr(hInfo) {
    var column, line, location, offset, result, rule, type;
    ({type, rule, location, result} = hInfo);
    if (defined(location)) {
      ({line, column, offset} = location.start);
    }
    switch (type) {
      case 'rule.enter':
        return `${this.prefix()}? ${rule}`;
      case 'rule.fail':
        if (defined(location)) {
          return `${this.result()} NO (at ${line}:${column}:${offset})`;
        } else {
          return `${this.result()} NO`;
        }
        break;
      case 'rule.match':
        if (defined(result)) {
          return `${this.result()} ${JSON.stringify(result)}`;
        } else {
          return `${this.result()} YES`;
        }
        break;
      default:
        return `UNKNOWN type: ${type}`;
    }
  }

  trace(hInfo) {
    var i, len1, result, str;
    // --- ignore whitespace rule
    if (hInfo.rule === '_') {
      return;
    }
    result = this.traceStr(hInfo);
    if (isString(result)) {
      console.log(result);
    } else if (isArray(result)) {
      for (i = 0, len1 = result.length; i < len1; i++) {
        str = result[i];
        console.log(str);
      }
    }
    switch (hInfo.type) {
      case 'rule.enter':
        this.level += 1;
        break;
      case 'rule.fail':
      case 'rule.match':
        this.level -= 1;
    }
  }

};

// ---------------------------------------------------------------------------
export var DetailedTracer = class DetailedTracer extends PeggyTracer {
  constructor(input1, hVars1 = {}) {
    super();
    this.input = input1;
    this.hVars = hVars1;
  }

  // ..........................................................
  varStr() {
    var i, lParts, len1, ref, value, varname;
    if (isEmpty(this.hVars)) {
      return '';
    }
    lParts = [];
    ref = keys(this.hVars);
    for (i = 0, len1 = ref.length; i < len1; i++) {
      varname = ref[i];
      value = this.hVars[varname]();
      lParts.push(`${varname} = ${JSON.stringify(value)}`);
    }
    if (lParts.length === 0) {
      return '';
    } else {
      return ' (' + lParts.join(',') + ')';
    }
  }

  // ..........................................................
  traceStr(hInfo) {
    var location, offset, result, rule, str, type;
    str = super.traceStr(hInfo);
    if ((hInfo.type !== 'rule.fail') || isEmpty(this.input)) {
      return str;
    }
    ({type, rule, location, result} = hInfo);
    if (defined(location)) {
      ({offset} = location.start);
      return [str, `${escapeStr(this.input, 'esc', {offset})}${this.varStr()}`];
    } else {
      return [str, `${escapeStr(this.input, 'esc')}${this.varStr()}`];
    }
  }

};

// ---------------------------------------------------------------------------
// --- tracer can be:
//        - undef
//        - a string: 'peggy','default','detailed'
//        - an object with a function property named 'trace'
//        - a function
export var getTracer = (tracer, input, hVars = {}) => {
  if (tracer === null) {
    tracer = undef;
  }
  switch (typeof tracer) {
    case 'undefined':
      return new NullTracer();
    case 'object':
      if (hasKey(tracer, trace)) {
        return tracer;
      } else {
        return new NullTracer();
      }
      break;
    case 'function':
      return {
        trace: tracer
      };
    case 'string':
      switch (tracer) {
        case 'default':
          return new DefaultTracer();
        case 'detailed':
          return new DetailedTracer(input, hVars);
        case 'peggy':
          return undef;
        default:
          return new NullTracer();
      }
  }
};

//# sourceMappingURL=PeggyTracers.js.map
