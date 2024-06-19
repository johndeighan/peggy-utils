// --- ByteCodeWriter.test.offee
import * as lib from '@jdeighan/peggy-utils/ByteCodeWriter';

Object.assign(global, lib);

import test from 'ava';

test("line 7", (t) => {
  var byteCodeWriter, info;
  byteCodeWriter = new ByteCodeWriter('dummy');
  byteCodeWriter.setAST({
    type: 'grammar',
    rules: ['abc']
  });
  info = byteCodeWriter.getOpInfo(35);
  return t.deepEqual(info, ['PUSH_EMPTY_STRING']);
});

//# sourceMappingURL=ByteCodeWriter.test.js.map
