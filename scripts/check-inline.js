'use strict';
const fs=require('node:fs');
const vm=require('node:vm');
const html=fs.readFileSync('index.html','utf8');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)];
if(!scripts.length)throw new Error('No inline scripts found');
scripts.forEach((m,i)=>{new vm.Script(m[1],{filename:'index.html:inline-script-'+(i+1)})});
process.stdout.write('Parsed '+scripts.length+' inline renderer scripts successfully.\n');
