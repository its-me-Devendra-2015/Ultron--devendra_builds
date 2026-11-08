'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const vault=require('../credentials');
const automation=require('../automation');

test('credential vault only accepts HTTPS origins',()=>{
 assert.equal(vault.domainOf('https://Example.com/login'),'example.com');
 assert.throws(()=>vault.domainOf('http://example.com'),/HTTPS/);
 assert.throws(()=>vault.domainOf('javascript:alert(1)'),/valid https/);
 assert.throws(()=>vault.domainOf('https://user:pass@example.com'),/HTTPS/);
});
test('credential domain matching rejects lookalike hosts',()=>{
 assert.notEqual(vault.domainOf('https://example.com.attacker.test'),'example.com');
 assert.equal(vault.domainOf('https://example.com:443/path'),'example.com');
});
test('automation emergency stop blocks actions until explicitly resumed',async()=>{
 automation.stop();
 await assert.rejects(()=>automation.execute({type:'launch',name:'notepad'}),/Emergency stop/);
 automation.resume();
 await assert.rejects(()=>automation.execute({type:'not-allowed'}),/Unsupported/);
});
test('automation refuses unknown applications',async()=>{
 await assert.rejects(()=>automation.execute({type:'launch',name:'powershell'}),/allowlist/);
});
