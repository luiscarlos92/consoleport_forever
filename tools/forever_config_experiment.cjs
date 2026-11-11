// Exercise Forever configuration and pinned DynamicCam source in an inert Lua VM.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
function functions(file,names){
  const source=read(file).replace(/\r\n/g,'\n');
  return names.map(name=>{
    const escaped=name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
    const start=source.search(new RegExp('function '+escaped+'\\s*\\('));
    const end=source.indexOf('\nend',start)+4;
    if(start<0||end<start)throw Error('Missing native function '+name);
    const body=source.slice(start,end);parser.parse(body,{luaVersion:'5.1'});return body;
  }).join('\n');
}
function execute(source){
  const L=lauxlib.luaL_newstate();
  for(const [n,open]of [['_G',lualib.luaopen_base],['table',lualib.luaopen_table],['string',lualib.luaopen_string],['math',lualib.luaopen_math]]){lauxlib.luaL_requiref(L,to_luastring(n),open,1);lua.lua_pop(L,1);}
  let rc=lauxlib.luaL_loadstring(L,to_luastring(source));if(rc===lua.LUA_OK)rc=lua.lua_pcall(L,0,0,0);
  const error=rc===lua.LUA_OK?null:to_jsstring(lua.lua_tostring(L,-1));lua.lua_close(L);if(error)throw Error(error);
}
function run(){
  const folder='addon/ForeverConfig_Extended/';
  const toc=read(folder+'ForeverConfig_Extended.toc');
  const entries=toc.split(/\r?\n/).map(line=>line.trim()).filter(line=>line.endsWith('.lua'));
  if (entries.join()!=='Core.lua,Bootstrap.lua' || /^## OptionalDeps:.*\bBetterBags\b/m.test(toc)) {
    throw Error('Retired settings or bridge remains in the configuration load path');
  }
  const controls={
    'profile-write': ['Plater.db.profile.ui_parent_scale_tune = 1.428571452899855', 'configuration wrote a Plater profile field'],
    'bag-hook': ['hooksecurefunc("OpenBackpack", function() end)', 'configuration registered a bag hook'],
  };
  const fixture=mutation=>read('tests/harness/forever_config.lua').replace('--@PRODUCT',()=>entries.map(name=>{
    let source=read(folder+name);
    if (name==='Bootstrap.lua'&&mutation) {
      source=source.replace('Addon:Snapshot() end',controls[mutation][0]+'; Addon:Snapshot() end');
    }
    parser.parse(source,{luaVersion:'5.1'});
    return 'assert(load('+JSON.stringify(source)+','+JSON.stringify(name)+'))("ForeverConfig_Extended",A)';
  }).join('\n'));
  execute(fixture());
  for (const [mutation,[,expected]] of Object.entries(controls)) {
    let rejected=false;
    try { execute(fixture(mutation)); } catch(error) { rejected=String(error).includes(expected); }
    if (!rejected) throw Error('Configuration retirement control survived: '+mutation);
  }
  return {passed:true,diagnostics:true,retiredSettings:true,retiredBridge:true};
}
function runDynamicCam(){
  const lock=JSON.parse(read('dependencies/lock.json'));
  const owner=lock.packages.find(p=>p.repo==='curseforge/DynamicCam');
  const base=owner.unpacked+'/DynamicCam/';
  const load=(relative)=>{
    const full='DynamicCam/'+relative,body=read(base+relative);
    if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,base+relative))).digest('hex')!==owner.files[full])throw Error('DynamicCam source drift');
    return `assert(load(${JSON.stringify(body)},${JSON.stringify(relative)}))('DynamicCam')`;
  };
  const build=(mode)=>read('tests/harness/dynamiccam_forever.lua')
    .replace('profile.situations[id]={enabled=true',mode==='old-disabled-profile'?'profile.situations[id]={enabled=false':'profile.situations[id]={enabled=true')
    .replace('--@LIBS',()=>['Libs/LibStub/LibStub.lua','Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua','Libs/AceDB-3.0/AceDB-3.0.lua'].map(load).join('\n'))
    .replace('--@DEFAULTS',()=>load('DefaultSettings.lua'))
    .replace('--@STARTUP',()=>{
      const body=functions(base+'Core.lua',['DynamicCam:Startup']);
      return mode==='missing-initial-evaluation'?body.replace('self:ScheduleTimer("EvaluateSituations", 0.2)','-- omitted evaluation'):body;
    })
    .replace('--@EVALUATOR',()=>functions(base+'SituationManager.lua',['DynamicCam:EvaluateSituations']));
  execute(build());
  for(const [mode,expected]of Object.entries({'old-disabled-profile':'enabled contexts lost','missing-initial-evaluation':'startup never evaluated'})){
    let rejected=false;try{execute(build(mode));}catch(error){rejected=String(error).includes(expected);}
    if(!rejected)throw Error('DynamicCam negative control survived: '+mode);
  }
  return {passed:true,nativeStartup:true,nativeEvaluator:true,enabledContexts:20,transitions:7,actualAceDBLogout:true,
    limits:'Camera application/interpolation, leaf WoW C APIs and UI visibility modeled; actual engine movement remains unverified.'};
}
module.exports={run,runDynamicCam};if(require.main===module)console.log(JSON.stringify({bags:run(),camera:runDynamicCam()}));
