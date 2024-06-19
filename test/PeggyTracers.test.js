// --- PeggyTracers.test.offee
import * as lib from '@jdeighan/peggy-utils/PeggyTracers';

Object.assign(global, lib);

import test from 'ava';

test("line 7", (t) => {
  t.is(rpad('abc', 8), 'abc     ');
  t.is(lpad('abc', 8), '     abc');
  return t.is(zpad(23, 8), '00000023');
});

//# sourceMappingURL=PeggyTracers.test.js.map
