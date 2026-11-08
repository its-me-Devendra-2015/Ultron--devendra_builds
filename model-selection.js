'use strict';
const PRIORITY=[/^qwen3:/i,/^qwen/i,/^kimi/i,/^deepseek/i,/^llama/i,/^mistral/i,/^gemma/i,/^phi/i,/^command-r/i];
function chooseModel(installed,configured=''){
 const names=[...new Set((installed||[]).filter(x=>typeof x==='string'&&!/(?:embed|rerank)/i.test(x)))];
 if(configured&&names.includes(configured))return configured;
 return PRIORITY.map(pattern=>names.find(name=>pattern.test(name))).find(Boolean)||names[0]||null;
}
module.exports={chooseModel};
