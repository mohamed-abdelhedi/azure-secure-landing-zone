import { spawnSync } from 'node:child_process';
import { existsSync, writeFileSync, rmSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline/promises';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const [environment, action = 'plan'] = process.argv.slice(2);
if (!['dev', 'prod'].includes(environment) || !['plan', 'apply', 'destroy', 'validate', 'fmt'].includes(action)) {
  console.error('Usage: node scripts/deploy.mjs <dev|prod> <plan|apply|destroy|validate|fmt>');
  process.exit(2);
}
const cwd = resolve(repo, 'environments', environment);
function run(command, args, capture = false, directory = cwd) {
  const result = spawnSync(command, args, { cwd: directory, encoding: 'utf8', stdio: capture ? 'pipe' : 'inherit', maxBuffer: 32 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw new Error(`${command} failed; no further commands will run.`);
  return result.stdout;
}
async function confirm(text, expected) {
  const prompt = createInterface({input: process.stdin, output: process.stdout});
  try {
    if ((await prompt.question(`${text}\nType '${expected}' to continue: `)) !== expected) throw new Error('Cancelled.');
  } finally { prompt.close(); }
}
try {
  if (action === 'fmt') {
    run('terraform', ['fmt', '-recursive'], false, repo);
  } else {
    run('terraform', ['fmt', '-check', '-recursive'], false, repo);
    if (action !== 'validate' && !existsSync(resolve(cwd, 'backend.hcl'))) {
      throw new Error(`Create environments/${environment}/backend.hcl from backend.hcl.example first.`);
    }
    run('terraform', action === 'validate' ? ['init', '-backend=false', '-input=false'] : ['init', '-input=false', '-backend-config=backend.hcl']);
    run('terraform', ['validate']);
    if (action !== 'validate') {
      // Always regenerate the plan. Never apply a stale, unchecked binary.
      rmSync(resolve(cwd, 'tfplan'), {force:true});
      run('terraform', ['plan', '-input=false', '-out=tfplan', ...(action === 'destroy' ? ['-destroy'] : [])]);
      try {
        writeFileSync(resolve(cwd, 'tfplan.json'), run('terraform', ['show', '-json', 'tfplan'], true), {mode:0o600});
        run(process.execPath, [resolve(repo, 'scripts/check-plan.mjs'), 'tfplan.json']);
      } finally { rmSync(resolve(cwd, 'tfplan.json'), {force:true}); }
      if (action !== 'plan') {
        await confirm(`Review the ${environment} plan above. Azure resources and charges may change.`, `${action}-${environment}`);
        run('terraform', ['apply', '-input=false', 'tfplan']);
        rmSync(resolve(cwd, 'tfplan'), {force:true});
      }
    }
  }
} catch (error) {
  rmSync(resolve(cwd, 'tfplan.json'), {force:true});
  rmSync(resolve(cwd, 'tfplan'), {force:true});
  console.error(error.message);
  process.exit(1);
}
