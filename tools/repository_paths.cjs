// Guard every Node tooling write, including an existing output file alias.
const fs = require('fs');
const path = require('path');
const ROOT = fs.realpathSync(path.resolve(__dirname, '..'));
function output(relative, scope = ROOT) {
  const base = path.resolve(scope), dest = path.resolve(ROOT, relative);
  const inside = (p, b) => p !== b && !path.relative(b, p).startsWith('..' + path.sep)
    && !path.isAbsolute(path.relative(b, p)) && path.relative(b, p) !== '..';
  if ((base !== ROOT && !inside(base, ROOT)) || fs.realpathSync(base) !== base || !inside(dest, base)) throw Error('output outside canonical scope: ' + dest);
  for (const immutable of ['reference', 'tests/fixtures']) {
    const p = path.join(ROOT, immutable);
    if (dest === p || inside(dest, p)) throw Error('immutable output: ' + dest);
  }
  for (let p = dest; ; p = path.dirname(p)) {
    if (fs.existsSync(p) || (() => {try {fs.lstatSync(p); return true;} catch {return false;}})()) {
      if (fs.lstatSync(p).isSymbolicLink() || fs.realpathSync(p) !== p) throw Error('output ancestor alias: ' + p);
    }
    if (p === base) break;
  }
  return dest;
}
module.exports = {ROOT, output};
