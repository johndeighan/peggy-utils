// ByteCodeWriter.coffee
import fs from 'node:fs';

import {
  undef,
  defined,
  notdefined,
  isString,
  untabify,
  assert,
  croak,
  range,
  pass
} from '@jdeighan/llutils';

import {
  indented,
  undented
} from '@jdeighan/llutils/indent';

// pass = () =>

  // ---------------------------------------------------------------------------
export var ByteCodeWriter = class ByteCodeWriter {
  constructor(name1, hOptions = {}) {
    this.name = name1;
    this.lRuleNames = [];
    this.hRules = {};
    // --- These are set when the AST is known
    this.literals = undef;
    this.expectations = undef;
    // --- options
    this.detailed = hOptions.detailed;
  }

  // ..........................................................
  setAST(ast) {
    assert(ast.type === 'grammar', "not a grammar");
    assert(ast.rules.length > 0, "no rules");
    this.literals = ast.literals;
    this.expectations = ast.expectations;
  }

  // ..........................................................
  add(ruleName, lOpcodes) {
    assert(typeof ruleName === 'string', "not a string");
    assert(Array.isArray(lOpcodes), "not an array");
    assert(!this.hRules[ruleName], `rule ${ruleName} already defined`);
    this.lRuleNames.push(ruleName);
    this.hRules[ruleName] = lOpcodes;
  }

  // ..........................................................
  getOpInfo(op, pos) {
    switch (op) {
      case 35:
        return ['PUSH_EMPTY_STRING', [], []];
      case 5:
        return ['PUSH_CUR_POS', [], []];
      case 1:
        return ['PUSH_UNDEFINED', [], []];
      case 2:
        return ['PUSH_NULL', [], []];
      case 3:
        return ['PUSH_FAILED', [], []];
      case 4:
        return ['PUSH_EMPTY_ARRAY', [], []];
      case 6:
        return ['POP', [], []];
      case 7:
        return ['POP_CUR_POS', [], []];
      case 8:
        return ['POP_N', ['/'], []];
      case 9:
        return ['NIP', [], []];
      case 10:
        return ['APPEND', [], []];
      case 11:
        return ['WRAP', [''], []];
      case 12:
        return ['TEXT', [], []];
      case 36:
        return ['PLUCK', ['/', '/', '/', 'p'], []];
      case 13:
        return ['IF', [], ['THEN', 'ELSE']];
      case 14:
        return ['IF_ERROR', [], ['THEN', 'ELSE']];
      case 15:
        return ['IF_NOT_ERROR', [], ['THEN', 'ELSE']];
      case 30:
        return ['IF_LT', [], ['THEN', 'ELSE']];
      case 31:
        return ['IF_GE', [], ['THEN', 'ELSE']];
      case 32:
        return ['IF_LT_DYNAMIC', [], ['THEN', 'ELSE']];
      case 33:
        return ['IF_GE_DYNAMIC', [], ['THEN', 'ELSE']];
      case 16:
        return ['WHILE_NOT_ERROR', [], ['THEN']];
      case 17:
        return ['MATCH_ANY', [], ['THEN', 'ELSE']];
      case 18:
        return ['MATCH_STRING', ['/lit'], ['THEN', 'ELSE']];
      case 19:
        return ['MATCH_STRING_IC', ['/lit'], ['THEN', 'ELSE']];
      case 20:
        return ['MATCH_CHAR_CLASS', ['/class'], []];
      case 21:
        return ['ACCEPT_N', ['/num'], []];
      case 22:
        return ['ACCEPT_STRING', ['/lit'], []];
      case 23:
        return ['FAIL', ['/expectation'], []];
      case 24:
        return ['LOAD_SAVED_POS', ['pos/num'], []];
      case 25:
        return ['UPDATE_SAVED_POS', ['pos/num'], []];
      case 26:
        return ['CALL', [], []];
      case 27:
        return ['RULE', ['/rule'], []];
      default:
        return croak(`Unknown opcode: ${op} at pos ${pos}`);
    }
  }

  // ..........................................................
  argStr(arg, infoStr) {
    var hExpect, label, result, type, value;
    if (infoStr === '/') {
      return arg.toString();
    }
    [label, type] = infoStr.split('/');
    switch (type) {
      case 'rule':
        if (arg < this.lRuleNames.length) {
          result = `<${this.lRuleNames[arg]}>`;
        } else {
          result = `<#${arg}>`;
        }
        break;
      case 'lit':
        result = `'${this.literals[arg]}'`;
        break;
      case 'num':
      case 'i':
        result = arg.toString();
        break;
      case 'expectation':
        hExpect = this.expectations[arg];
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
    debugger;
    var blockBase, blockLen, i, j, lArgDesc, lArgInfo, lArgs, lBlockInfo, lLines, lSubOps, label, len, name, numArgs, op, pos;
    lLines = [];
    pos = 0;
    while (pos < lOpcodes.length) {
      op = lOpcodes[pos];
      pos += 1;
      [name, lArgInfo, lBlockInfo] = this.getOpInfo(op, pos);
      numArgs = lArgInfo.length;
      if (numArgs === 0) {
        if (this.detailed) {
          lLines.push(`(${op}) ${name}`);
        } else {
          lLines.push(`${name}`);
        }
      } else {
        lArgs = lOpcodes.slice(pos, pos + numArgs);
        pos += numArgs;
        lArgDesc = lArgs.map((arg, i) => {
          return this.argStr(arg, lArgInfo[i]);
        });
        if (this.detailed) {
          lLines.push(`(${op}) ${name} ${lArgDesc.join(' ')}`);
        } else {
          lLines.push(`${name} ${lArgDesc.join(' ')}`);
        }
      }
      blockBase = pos + lBlockInfo.length;
      for (i = j = 0, len = lBlockInfo.length; j < len; i = ++j) {
        label = lBlockInfo[i];
        blockLen = lOpcodes[pos];
        pos += 1;
        switch (label) {
          case 'ELSE':
            if (blockLen > 0) {
              lLines.push('ELSE');
            }
            break;
          case 'THEN':
            pass();
            break;
          default:
            croak(`Bad block label: ${label}`);
        }
        lSubOps = lOpcodes.slice(blockBase, blockBase + blockLen);
        lLines.push(indented(this.opStr(lSubOps)));
        blockBase += blockLen;
      }
      pos = blockBase;
    }
    return lLines.join("\n");
  }

  // ..........................................................
  getBlock() {
    var block, j, lOpcodes, lParts, len, ref, ruleName;
    lParts = [];
    ref = Object.keys(this.hRules);
    for (j = 0, len = ref.length; j < len; j++) {
      ruleName = ref[j];
      lParts.push(`<${ruleName}>`);
      lOpcodes = this.hRules[ruleName];
      block = this.opStr(lOpcodes).trimEnd();
      if (block !== '') {
        lParts.push(indented(block));
      }
      lParts.push('');
    }
    return lParts.join("\n").trimEnd();
  }

  // ..........................................................
  writeTo(filePath) {
    console.log(`Writing bytecodes to ${filePath}`);
    fs.writeFileSync(filePath, this.getBlock());
  }

};

//# sourceMappingURL=ByteCodeWriter.js.map
