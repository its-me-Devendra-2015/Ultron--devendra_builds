'use strict';
const {execFile,spawn}=require('child_process');
const W=process.platform==='win32';
let stopped=false;
const runPS=async script=>{
 if(!W)throw new Error('Desktop automation is available on Windows only.');
 const encoded=Buffer.from(script,'utf16le').toString('base64');
 return new Promise((resolve,reject)=>execFile('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',encoded],{timeout:15000,windowsHide:true,maxBuffer:1024*1024},(e,out,err)=>e?reject(new Error((err||e.message).trim().slice(0,500))):resolve(String(out).trim())));
};
const safeName=s=>{s=String(s||'').trim();if(!s||s.length>160||/[\r\n\0]/.test(s))throw new Error('Invalid application name');return s};
const check=()=>{if(stopped)throw new Error('Emergency stop is active. Resume automation explicitly first.')};
async function windows(){
 check();
 const raw=await runPS("Get-Process | Where-Object {$_.MainWindowHandle -ne 0} | Select-Object Id,ProcessName,MainWindowTitle | ConvertTo-Json -Compress");
 if(!raw)return [];
 try{const x=JSON.parse(raw);return(Array.isArray(x)?x:[x]).map(v=>({pid:Number(v.Id),process:String(v.ProcessName||''),title:String(v.MainWindowTitle||'')}))}catch{return []}
}
async function controls(title){
 check();title=safeName(title);const q=title.replace(/'/g,"''");
 const script="Add-Type -AssemblyName UIAutomationClient; $root=[Windows.Automation.AutomationElement]::RootElement; $all=$root.FindAll([Windows.Automation.TreeScope]::Children,[Windows.Automation.Condition]::TrueCondition); $w=$null; foreach($e in $all){if($e.Current.Name -like '*"+q+"*'){$w=$e;break}}; if($null -eq $w){throw 'Window not found'}; $items=$w.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition); $out=@(); for($i=0;$i -lt [Math]::Min($items.Count,250);$i++){ $e=$items.Item($i); $n=$e.Current.Name; if($n){$out+=@{name=$n;type=$e.Current.ControlType.ProgrammaticName;enabled=$e.Current.IsEnabled;automationId=$e.Current.AutomationId}} }; $out | ConvertTo-Json -Compress";
 const raw=await runPS(script);
 try{const x=JSON.parse(raw);return Array.isArray(x)?x:[x]}catch{return []}
}
async function execute(action){
 check();if(!action||typeof action!=='object')throw new Error('Invalid automation action');
 const type=String(action.type||'');
 if(type==='launch'){
  const name=safeName(action.name),allowed={'notepad':'notepad.exe','calculator':'calc.exe','file explorer':'explorer.exe','task manager':'taskmgr.exe','settings':'ms-settings:'},exe=allowed[name.toLowerCase()];
  if(!exe)throw new Error('App is not in the built-in launch allowlist');
  spawn('cmd.exe',['/c','start','',exe],{detached:true,stdio:'ignore',windowsHide:true}).unref();return {ok:true,action:'launch',name};
 }
 if(type==='close'){
  const pid=Number(action.pid);if(!Number.isSafeInteger(pid)||pid<=0)throw new Error('A valid window PID is required');
  await runPS("$p=Get-Process -Id "+pid+" -ErrorAction Stop; if(-not $p.MainWindowHandle){throw 'Process has no visible window'}; $p.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 500; if(-not $p.HasExited){throw 'Application did not close gracefully'}");
  return {ok:true,action:'close',pid};
 }
 if(type==='keys'||type==='type'){
  const value=String(action.value||'');if(value.length>2000||/[\0]/.test(value))throw new Error('Text/shortcut is too long or invalid');
  if(type==='keys'&&!/^[\w+^%~{}()[\]]{1,80}$/.test(value))throw new Error('Unsupported shortcut syntax');
  await runPS("Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('"+value.replace(/'/g,"''")+"')");
  return {ok:true,action:type};
 }
 if(type==='click'){
  const title=safeName(action.windowTitle).replace(/'/g,"''"),name=safeName(action.name).replace(/'/g,"''");
  const script="Add-Type -AssemblyName UIAutomationClient; $root=[Windows.Automation.AutomationElement]::RootElement; $all=$root.FindAll([Windows.Automation.TreeScope]::Children,[Windows.Automation.Condition]::TrueCondition); $w=$null; foreach($e in $all){if($e.Current.Name -like '*"+title+"*'){$w=$e;break}}; if($null -eq $w){throw 'Window not found'}; $cond=New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'"+name+"'); $e=$w.FindFirst([Windows.Automation.TreeScope]::Descendants,$cond); if($null -eq $e -or -not $e.Current.IsEnabled){throw 'Enabled control not found'}; $p=$null; if($e.TryGetCurrentPattern([Windows.Automation.InvokePattern]::Pattern,[ref]$p)){$p.Invoke()}else{throw 'Control does not support Invoke'}";
  await runPS(script);return {ok:true,action:'click',name};
 }
 throw new Error('Unsupported automation action');
}
module.exports={windows,controls,execute,stop(){stopped=true},resume(){stopped=false},isStopped:()=>stopped};
