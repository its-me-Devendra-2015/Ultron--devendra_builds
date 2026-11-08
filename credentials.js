'use strict';
const fs=require('fs'),path=require('path'),{execFile}=require('child_process');
const W=process.platform==='win32';
const file=path.join(process.env.ULTRON_HOME||__dirname,'credentials-vault.json');
const runPS=script=>{
 if(!W)throw new Error('Credential vault encryption currently requires Windows DPAPI.');
 const encoded=Buffer.from(script,'utf16le').toString('base64');
 return new Promise((resolve,reject)=>execFile('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',encoded],{timeout:10000,windowsHide:true,maxBuffer:128000},(e,out,err)=>e?reject(new Error((err||e.message).trim().slice(0,300))):resolve(String(out).trim())));
};
const read=()=>{try{const x=JSON.parse(fs.readFileSync(file,'utf8'));return Array.isArray(x)?x:[]}catch{return[]}};
const domainOf=value=>{
 let u;try{u=new URL(value)}catch{throw new Error('Enter a valid https:// website URL')}
 if(u.protocol!=='https:'||u.username||u.password)throw new Error('Credentials are only supported for HTTPS websites');
 return u.hostname.toLowerCase().replace(/\.$/,'');
};
const id=()=>require('crypto').randomBytes(12).toString('hex');
async function save({id:entryId,site,username,password,label}){
 const domain=domainOf(site);username=String(username||'').trim();password=String(password||'');
 if(!username||username.length>320||!password||password.length>2048)throw new Error('Username and password are required');
 const encrypted=await runPS("$s=ConvertTo-SecureString -String '"+password.replace(/'/g,"''")+"' -AsPlainText -Force; ConvertFrom-SecureString -SecureString $s");
 const all=read(),key=entryId||id(),entry={id:key,domain,site:'https://'+domain+'/',username,label:String(label||domain).slice(0,80),encrypted,updatedAt:Date.now()};
 const i=all.findIndex(x=>x.id===key);if(i>=0)all[i]=entry;else all.push(entry);
 fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,JSON.stringify(all,null,2),{mode:0o600});
 if(W)try{await runPS("$p='"+file.replace(/'/g,"''")+"'; icacls $p /inheritance:r /grant:r \"$($env:USERNAME):(R,W)\" | Out-Null")}catch{}
 return {id:key,domain,label:entry.label};
}
function list(){return read().map(({id,domain,username,label,updatedAt})=>({id,domain,username,label,updatedAt}));}
function remove(id){const all=read(),next=all.filter(x=>x.id!==id);if(next.length===all.length)throw new Error('Credential entry not found');fs.writeFileSync(file,JSON.stringify(next,null,2),{mode:0o600});return{ok:true};}
async function reveal({id,origin}){
 const domain=domainOf(origin),entry=read().find(x=>x.id===id);
 if(!entry)throw new Error('Credential entry not found');
 if(domain!==entry.domain)throw new Error('Exact domain mismatch. Credentials were not released.');
 const enc=String(entry.encrypted||'').replace(/'/g,"''");
 const raw=await runPS("$s=ConvertTo-SecureString -String '"+enc+"'; $p=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); try{[Runtime.InteropServices.Marshal]::PtrToStringBSTR($p)}finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($p)}");
 return {username:entry.username,password:raw,domain:entry.domain};
}
module.exports={list,save,remove,reveal,domainOf};
