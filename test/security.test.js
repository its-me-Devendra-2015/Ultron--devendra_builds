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

const {chooseModel}=require('../model-selection');
test('Ollama model selection recognizes Qwen, Kimi and common model families',()=>{
 assert.equal(chooseModel(['qwen3:4b','gemma4:e2b']),'qwen3:4b');
 assert.equal(chooseModel(['kimi-k2:latest','gemma3:4b']),'kimi-k2:latest');
 assert.equal(chooseModel(['deepseek-r1:8b']),'deepseek-r1:8b');
 assert.equal(chooseModel(['llama3.2:3b']),'llama3.2:3b');
});
test('Ollama model selection honors an installed explicit choice and excludes embedding models',()=>{
 assert.equal(chooseModel(['qwen3:4b','kimi-k2:latest'],'kimi-k2:latest'),'kimi-k2:latest');
 assert.equal(chooseModel(['nomic-embed-text:latest','custom-chat:latest']),'custom-chat:latest');
 assert.equal(chooseModel([]),null);
});
