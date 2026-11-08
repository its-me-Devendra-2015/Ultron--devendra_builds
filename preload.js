'use strict';
const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('ultronDesktop',Object.freeze({
 getScreenSources:()=>ipcRenderer.invoke('ultron:screen-sources'),
 emergencyStop:()=>ipcRenderer.send('ultron:emergency-stop'),
 onEmergencyStop:callback=>{if(typeof callback!=='function')return()=>{};const fn=()=>callback();ipcRenderer.on('ultron:emergency-stop',fn);return()=>ipcRenderer.removeListener('ultron:emergency-stop',fn)}
}));
