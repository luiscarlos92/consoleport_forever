// Compare parsed Lua structure, retaining string/number literal values. This
// classifies formatting/comments only; it is not a behavioral equivalence proof.
const parser=require('luaparse');
const fs=require('fs');
function tree(text) {
  const ast=parser.parse(text,{luaVersion:'5.1',comments:false,encodingMode:'pseudo-latin1'});
  return JSON.stringify(ast,(key,value)=>key==='raw' ? undefined : value);
}
const pairs=JSON.parse(fs.readFileSync(0,'utf8'));
process.stdout.write(JSON.stringify(pairs.map(([a,b])=>{
  try {return tree(a)===tree(b);} catch {return null;}
})));
