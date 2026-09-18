import { spawnSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// Never print the plan: Terraform JSON can contain secrets in plain text.
const policyDir = resolve(dirname(fileURLToPath(import.meta.url)), '../policies');
const input = process.argv[2];
if (!input) {
  console.error('Usage: node scripts/check-plan.mjs <terraform-plan.json>');
  process.exit(2);
}
const result = spawnSync('opa', ['eval', '--format=json', '--strict-builtin-errors',
  '--data', policyDir, '--input', resolve(input), 'data.landingzone.deny'], { encoding: 'utf8' });
if (result.error || result.status !== 0) {
  console.error('Policy evaluation failed; deployment is blocked. Check OPA, policy syntax and plan JSON.');
  process.exit(2);
}
try {
  const violations = JSON.parse(result.stdout).result?.[0]?.expressions?.[0]?.value;
  if (!Array.isArray(violations)) throw new Error('Missing policy decision');
  if (violations.length) {
    for (const message of violations) console.error(`DENY: ${message}`);
    process.exit(1);
  }
  console.log('Plan passed landing-zone policies.');
} catch {
  console.error('Invalid policy response; deployment is blocked.');
  process.exit(2);
}
