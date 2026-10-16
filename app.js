// ULTRON desktop launcher: starts the local server and opens ULTRON in its own app window (no tabs, own profile).
// A random per-launch token means only that window can use the server's API.
const {spawn}=require('child_process'),crypto=require('crypto'),net=require('net'),fs=require('fs'),path=require('path');
const ROOT=process.pkg?path.dirname(process.execPath):__dirname;
process.on('uncaughtException',e=>console.error('\nULTRON error:',e&&e.stack||e));
const free=p=>new Promise(r=>{const s=net.createServer().once('error',()=>r(false)).once('listening',()=>s.close(()=>r(true))).listen(p,'127.0.0.1')});
(async()=>{
 let port=+(process.env.PORT||4777);for(let i=0;i<20&&!await free(port);i++){console.log('Port '+port+' is busy, trying '+(port+1));port++}
 process.env.PORT=String(port);const TOKEN=crypto.randomBytes(24).toString('hex');process.env.ULTRON_TOKEN=TOKEN;
 require('./server.js');
 const up=()=>new Promise(r=>{const s=net.connect(port,'127.0.0.1');s.on('connect',()=>{s.destroy();r(true)});s.on('error',()=>r(false))});
 for(let i=0;i<40&&!await up();i++)await new Promise(r=>setTimeout(r,250));
 if(!await up()){console.error('The server did not start. See the error above.');return}
 const url=`http://localhost:${port}/?t=${TOKEN}`,E=process.env;
 if(process.argv.includes('--browser')){spawn('cmd',['/c','start','',url],{stdio:'ignore',detached:true}).unref();console.log('Opened in your default browser. Close this window to stop ULTRON.');return}
 const exe=[E['ProgramFiles(x86)'],E.ProgramFiles,E.LOCALAPPDATA].filter(Boolean).flatMap(b=>[path.join(b,'Microsoft','Edge','Application','msedge.exe'),path.join(b,'Google','Chrome','Application','chrome.exe')]).find(p=>fs.existsSync(p));
 if(!exe){console.log('Edge/Chrome not found. Open this address in a browser (valid for this session):\n'+url);return}
 const t0=Date.now(),c=spawn(exe,['--app='+url,'--user-data-dir='+path.join(ROOT,'app-profile'),'--window-size=1600,900','--no-first-run','--no-default-browser-check'],{stdio:'ignore'});
 c.on('error',e=>console.error('Could not start the app window:',e.message,'\nTry start-in-browser.bat'));
 c.on('exit',()=>{if(Date.now()-t0<3000){console.log('The app window handed off to another process. ULTRON is still running at:\n'+url)}else{console.log('ULTRON window closed — shutting down.');process.exit(0)}})
})();
