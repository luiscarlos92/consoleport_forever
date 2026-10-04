// Parse saved variables as data. No eval, Lua VM, io or game globals.
const parser = require('luaparse');
function literal(node) {
  if (node.type === 'StringLiteral') {
    const bytes=Buffer.from(node.value,'latin1');
    try { return new TextDecoder('utf-8',{fatal:true}).decode(bytes); }
    catch { return node.value; } // Lua strings can also contain non-UTF-8 bytes.
  }
  if (node.type === 'NumericLiteral' || node.type === 'BooleanLiteral') return node.value;
  if (node.type === 'NilLiteral') return null;
  if (node.type === 'UnaryExpression' && node.operator === '-' && node.argument.type === 'NumericLiteral') return -node.argument.value;
  if (node.type === 'TableConstructorExpression') {
    const result = Object.create(null); let index=1;
    for (const field of node.fields) {
      let key;
      if (field.type === 'TableValue') key=index++;
      else if (field.type === 'TableKeyString') key=field.key.name;
      else if (field.type === 'TableKey') key=literal(field.key);
      else throw Error('unsupported table field');
      if (typeof key !== 'string' && typeof key !== 'number') throw Error('invalid table key');
      result[String(key)] = literal(field.value);
    }
    return result;
  }
  throw Error('Non-data Lua node: '+node.type);
}
function parse(text) {
  // WoW writes UTF-8 character/profile names alongside Lua byte escapes.
  // Present bytes to luaparse, then decode each literal without executing Lua.
  const tree=parser.parse(Buffer.from(text,'utf8').toString('latin1'),{luaVersion:'5.1',encodingMode:'pseudo-latin1'});
  const result=Object.create(null);
  for (const statement of tree.body) {
    if (statement.type !== 'AssignmentStatement' || statement.variables.length !== statement.init.length) throw Error('Only literal saved assignments accepted');
    statement.variables.forEach((v,i)=> {
      if (v.type !== 'Identifier') throw Error('Only global saved names accepted');
      result[v.name]=literal(statement.init[i]);
    });
  }
  return result;
}
module.exports={parse};
