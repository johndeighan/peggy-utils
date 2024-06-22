// OpDumper.coffee
import fs from 'node:fs';

import {
  undef,
  defined,
  notdefined,
  isString,
  assert,
  croak,
  range
} from '@jdeighan/llutils';

import {
  indented,
  undented
} from '@jdeighan/llutils/indent';

// ---------------------------------------------------------------------------
// --- valid options:
//        char - char to use on left and right
//        buffer - num spaces around text when char <> ' '
export var centered = (text, width, hOptions = {}) => {
  var buf, char, left, numBuffer, numLeft, numRight, right, totSpaces;
  ({char} = hOptions);
  numBuffer = hOptions.numBuffer || 2;
  totSpaces = width - text.length;
  if (totSpaces <= 0) {
    return text;
  }
  numLeft = Math.floor(totSpaces / 2);
  numRight = totSpaces - numLeft;
  if (char === ' ') {
    return spaces(numLeft) + text + spaces(numRight);
  } else {
    buf = ' '.repeat(numBuffer);
    left = char.repeat(numLeft - numBuffer);
    right = char.repeat(numRight - numBuffer);
    numLeft -= numBuffer;
    numRight -= numBuffer;
    return left + buf + text + buf + right;
  }
};

// --------------------------------------------------------------------------
export var OpDumper = class OpDumper {
  constructor(name) {
    this.name = name;
    this.level = 0;
    this.lLines = [];
  }

  // ..........................................................
  setStack(stack) {
    this.stack = stack;
  }

  // ..........................................................
  incLevel() {
    return this.level += 1;
  }

  decLevel() {
    return this.level -= 1;
  }

  // ..........................................................
  out(str) {
    this.lLines.push("  ".repeat(this.level) + str);
  }

  // ..........................................................
  outBC(lByteCodes) {
    this.out('OPCODES: ' + lByteCodes.map((x) => {
      return x.toString();
    }).join(' '));
  }

  // ..........................................................
  outCode(lLines, label) {
    var i, len, line, width;
    width = 34;
    if (!label) {
      label = "UNKNOWN";
    }
    this.out(centered(label, width, {
      char: '-'
    }));
    for (i = 0, len = lLines.length; i < len; i++) {
      line = lLines[i];
      this.out(line);
    }
    this.out('-'.repeat(width));
  }

  // ..........................................................
  contents() {
    return this.lLines.join("\n");
  }

  // ..........................................................
  writeTo(filePath) {
    console.log(`Writing opcodes to ${filePath}`);
    fs.writeFileSync(filePath, this.contents());
  }

};

//# sourceMappingURL=OpDumper.js.map
