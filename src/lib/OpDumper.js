// OpDumper.coffee
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
    this.out('OPCODES:' + lByteCodes.map((x) => {
      return x.toString();
    }).join(' '));
  }

  // ..........................................................
  contents() {
    return this.lLines.join("\n");
  }

  // ..........................................................
  write() {
    var fileName;
    fileName = `./${this.name}.opcodes.txt`;
    console.log(`Writing opcodes to ${fileName}`);
    fs.writeFileSync(fileName, this.contents());
  }

};

//# sourceMappingURL=OpDumper.js.map
