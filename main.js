// ULTRON desktop app (Electron): its own window, no browser. Hosts the local server and shows it.
const {app,BrowserWindow,Menu,session,shell,ipcMain,desktopCapturer}=require('electron'),crypto=require('crypto'),net=require('net');
const automation=require('./automation');
process.on('uncaughtException',e=>console.error('ULTRON error:',e&&e.stack||e));
if(!app.requestSingleInstanceLock())app.quit();
const free=p=>new Promise(r=>{const s=net.createServer().once('error',()=>r(false)).once('listening',()=>s.close(()=>r(true))).listen(p,'127.0.0.1')});
const up=p=>new Promise(r=>{const s=net.connect(p,'127.0.0.1');s.on('connect',()=>{s.destroy();r(true)});s.on('error',()=>r(false))});
app.whenReady().then(async()=>{
 if(app.isPackaged)process.env.ULTRON_HOME=app.getPath('userData');// installed app keeps .env, apps.json and chat history in %APPDATA%\ULTRON
 process.on('ultron-restart',()=>{app.relaunch();app.exit(0)});
 ipcMain.handle('ultron:screen-sources',async()=>{const sources=await desktopCapturer.getSources({types:['screen','window'],thumbnailSize:{width:320,height:180},fetchWindowIcons:false});return sources.map(s=>({id:s.id,name:s.name,displayId:s.display_id,thumbnail:s.thumbnail.toDataURL()}))});
 ipcMain.on('ultron:emergency-stop',()=>automation.stop());
 ipcMain.handle('ultron:automation-resume',()=>{automation.resume();return true});
 let port=+(process.env.PORT||4777);for(let i=0;i<20&&!await free(port);i++)port++;
 process.env.PORT=String(port);const token=process.env.ULTRON_PASSWORD||crypto.randomBytes(24).toString('hex');process.env.ULTRON_TOKEN=token;
 require('./server.js');for(let i=0;i<40&&!await up(port);i++)await new Promise(r=>setTimeout(r,250));
 const origin=`http://localhost:${port}`,ok=['media','geolocation','clipboard-sanitized-write','fullscreen'];
 const ses=session.defaultSession;
 ses.setPermissionRequestHandler((wc,perm,cb,d)=>cb(String(d.requestingUrl||'').startsWith(origin)&&ok.includes(perm)));
 ses.setPermissionCheckHandler((wc,perm,o)=>String(o||'').startsWith(origin)&&ok.includes(perm));
 Menu.setApplicationMenu(null);
 const win=new BrowserWindow({width:1600,height:900,minWidth:900,minHeight:600,backgroundColor:'#050405',title:'ULTRON',icon:require('path').join(__dirname,'build','icon.png'),autoHideMenuBar:true,webPreferences:{contextIsolation:true,sandbox:true,nodeIntegration:false,preload:require('path').join(__dirname,'preload.js')}});
 win.webContents.setWindowOpenHandler(({url})=>{if(/^https:\/\/(accounts\.google\.com)\//.test(url))shell.openExternal(url);return{action:'deny'}});
 win.webContents.on('will-navigate',(e,url)=>{if(!url.startsWith(origin))e.preventDefault()});
 win.loadURL(`${origin}/?t=${token}`);
});
app.on('window-all-closed',()=>app.quit());
