// ByteCodeWriter.coffee
import fs from 'node:fs';

import {
  undef,
  defined,
  notdefined,
  isString,
  assert,
  croak,
  range,
  indented,
  undented
} from '@jdeighan/vllu';

// ---------------------------------------------------------------------------
export var ByteCodeWriter = class ByteCodeWriter {
  constructor(name1, hOptions = {}) {
    this.name = name1;
    this.hRules = {};
    this.hCounts = {};
    this.lOpcodes = undef;
    this.detailed = hOptions.detailed;
  }

  // ..........................................................
  setAST(ast) {
    assert(ast.type === 'grammar', "not a grammar");
    assert(ast.rules.length > 0, "no rules");
    this.ast = ast;
  }

  // ..........................................................
  getOpInfo(op) {
    switch (op) {
      case 35:
        return ['PUSH_EMPTY_STRING'];
      case 5:
        return ['PUSH_CUR_POS'];
      case 1:
        return ['PUSH_UNDEFINED'];
      case 2:
        return ['PUSH_NULL'];
      case 3:
        return ['PUSH_FAILED'];
      case 4:
        return ['PUSH_EMPTY_ARRAY'];
      case 6:
        return ['POP'];
      case 7:
        return ['POP_CUR_POS'];
      case 8:
        return ['POP_N', '/number'];
      case 9:
        return ['NIP'];
      case 10:
        return ['APPEND'];
      case 11:
        return ['WRAP', undef];
      case 12:
        return ['TEXT'];
      case 36:
        return ['PLUCK', undef, undef, undef, 'p'];
      case 13:
        return ['IF', 'OK/block', 'FAIL/block'];
      case 14:
        return ['IF_ERROR', 'OK/block', 'FAIL/block'];
      case 15:
        return ['IF_NOT_ERROR', 'OK/block', 'FAIL/block'];
      case 30:
        return ['IF_LT', 'OK/block', 'FAIL/block'];
      case 31:
        return ['IF_GE', 'OK/block', 'FAIL/block'];
      case 32:
        return ['IF_LT_DYNAMIC', 'OK/block', 'FAIL/block'];
      case 33:
        return ['IF_GE_DYNAMIC', 'OK/block', 'FAIL/block'];
      case 16:
        return ['WHILE_NOT_ERROR', 'OK/block'];
      case 17:
        return ['MATCH_ANY', 'OK/block', 'FAIL/block'];
      case 18:
        return ['MATCH_STRING', '/literal', 'OK/block', 'FAIL/block'];
      case 19:
        return ['MATCH_STRING_IC', '/literal', 'OK/block', 'FAIL/block'];
      case 20:
        return ['MATCH_CHAR_CLASS', '/class'];
      case 21:
        return ['ACCEPT_N', '/number'];
      case 22:
        return ['ACCEPT_STRING', '/literal'];
      case 23:
        return ['FAIL', '/expectation'];
      case 24:
        return ['LOAD_SAVED_POS', 'pos/number'];
      case 25:
        return ['UPDATE_SAVED_POS', 'pos/number'];
      case 26:
        return ['CALL'];
      case 27:
        return ['RULE', '/rule'];
      default:
        return void 0;
    }
  }

  // ..........................................................
  argStr(arg, infoStr) {
    var hExpect, label, result, type, value;
    if (infoStr === undef) {
      return arg.toString();
    }
    [label, type] = infoStr.split('/');
    switch (type) {
      case 'rule':
        if ((typeof arg === 'number') && (arg < this.ast.rules.length)) {
          result = `<${this.ast.rules[arg].name}>`;
        } else {
          result = `<UNKNOWN RULE ${arg}>`;
        }
        break;
      case 'literal':
        result = `'${this.ast.literals[arg]}'`;
        break;
      case 'number':
        result = arg.toString();
        break;
      case 'expectation':
        hExpect = this.ast.expectations[arg];
        ({type, value} = hExpect);
        switch (type) {
          case 'literal':
            result = `\"${value}\"`;
            break;
          case 'class':
            result = "[..]";
            break;
          case 'any':
            result = '.';
            break;
          default:
            croak(`Unknown expectation type: ${type}`);
        }
        break;
      case 'block':
        if (label) {
          result = `${label}:${arg}`;
        } else {
          result = `BLOCK: ${arg}`;
        }
        break;
      case 'class':
        if (label) {
          result = `${label}:[${arg}]`;
        } else {
          result = `CLASS: ${arg}`;
        }
        break;
      default:
        croak(`argStr(): unknown type ${type}`);
    }
    if (this.detailed) {
      return `(${arg}) ${result}`;
    } else {
      return result;
    }
  }

  // ..........................................................
  opStr(lOpcodes) {
    var arg, i, infoStr, j, lArgDesc, lArgInfo, lArgs, lInfo, lLines, lSubOps, label, len, nOpcodes, name, numArgs, op, pos, type;
    lLines = [];
    pos = 0;
    nOpcodes = lOpcodes.length;
    while (pos < nOpcodes) {
      op = lOpcodes[pos];
      pos += 1;
      lInfo = this.getOpInfo(op);
      if (notdefined(lInfo)) {
        lLines.push(`OPCODE ${op}`);
        continue;
      }
      name = lInfo[0];
      if (lInfo[1]) {
        lArgInfo = lInfo.slice(1);
      } else {
        lArgInfo = [];
      }
      if (notdefined(lArgInfo)) {
        lArgInfo = [];
      }
      numArgs = lArgInfo.length;
      lArgs = lOpcodes.slice(pos, pos + numArgs);
      pos += numArgs;
      lArgDesc = lArgs.map((arg, i) => {
        return this.argStr(arg, lArgInfo[i]);
      });
      if (this.detailed) {
        lLines.push(`(${op}) ${name}${' ' + lArgDesc.join(' ')}`);
      } else {
        lLines.push(`${name}${' ' + lArgDesc.join(' ')}`);
      }
      for (i = j = 0, len = lArgs.length; j < len; i = ++j) {
        arg = lArgs[i];
        infoStr = lArgInfo[i];
        if (notdefined(infoStr)) {
          continue;
        }
        if (infoStr.includes('/')) {
          [label, type] = infoStr.split('/');
          if (type === 'block') {
            lLines.push(indented(`[${label}]`));
            // --- NOTE: arg is the length of the block in bytes
            lSubOps = lOpcodes.slice(pos, pos + arg);
            pos += arg;
            lLines.push(indented(this.opStr(lSubOps), 2));
          }
        }
      }
    }
    return lLines.join("\n");
  }

  // ..........................................................
  add(ruleName, lOpcodes) {
    assert(typeof ruleName === 'string', "not a string");
    assert(Array.isArray(lOpcodes), "not an array");
    assert(!this.hRules[ruleName], `rule ${ruleName} already defined`);
    this.hRules[ruleName] = lOpcodes;
  }

  // ..........................................................
  write() {
    var fileName, j, lOpcodes, lParts, len, ref, ruleName;
    lParts = [];
    ref = Object.keys(this.hRules);
    for (j = 0, len = ref.length; j < len; j++) {
      ruleName = ref[j];
      lParts.push(`${ruleName}:`);
      lOpcodes = this.hRules[ruleName];
      lParts.push(indented(this.opStr(lOpcodes)));
      lParts.push('');
    }
    fileName = `./${this.name}.bytecodes.txt`;
    console.log(`Writing bytecodes to ${fileName}`);
    fs.writeFileSync(fileName, lParts.join("\n"));
  }

};

//# sourceMappingURL=ByteCodeWriter.js.map
