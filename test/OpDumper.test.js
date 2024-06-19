// --- OpDumper.test.offee
import * as lib from '@jdeighan/peggy-utils/OpDumper';

Object.assign(global, lib);

import test from 'ava';

test("line 7", (t) => {
  var opDumper;
  opDumper = new OpDumper('dummy');
  opDumper.out('line 1');
  opDumper.out('line 2');
  return t.is(opDumper.contents(), "line 1\nline 2");
});

//# sourceMappingURL=OpDumper.test.js.map
