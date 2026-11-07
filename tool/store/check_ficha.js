// Checks every field in store/ficha.md against its store character limit.
//   node tool/store/check_ficha.js
const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, '..', '..', 'store', 'ficha.md');
const text = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
const re = /<!-- field:(\S+) max:(\d+) -->\n([\s\S]*?)\n<!-- \/field -->/g;

let failed = false;
for (const [, name, max, body] of text.matchAll(re)) {
  // Stores count characters, not bytes; spread handles accents and emoji.
  const length = [...body].length;
  const ok = length <= Number(max);
  if (!ok) failed = true;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name.padEnd(18)} ${String(length).padStart(4)}/${max}`);
}
process.exit(failed ? 1 : 0);
