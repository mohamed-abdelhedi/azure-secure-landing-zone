import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync, rmdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// Terraform test emits a plan envelope with plan_format_version; normalize only
// that envelope so the same policies inspect the real mocked resource changes.
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const directory = process.argv[2];
if (!['environments/dev', 'environments/prod', 'modules/network-hub'].includes(directory)) {
  console.error('Specify environments/dev, environments/prod or modules/network-hub.');
  process.exit(2);
}
const result = spawnSync('terraform', [`-chdir=${resolve(root, directory)}`, 'test', '-json', '-verbose'], {encoding:'utf8', maxBuffer:32*1024*1024});
if (result.error || result.status !== 0) {
  console.error(result.stdout || result.stderr || 'Terraform test could not run.');
  process.exit(1);
}
const temp = mkdtempSync(join(tmpdir(), 'landing-zone-mock-plans-'));
try {
  const events = result.stdout.trim().split(/\r?\n/).map(line => JSON.parse(line));
  // These two negative tests intentionally stop at variable validation and
  // therefore have no resource plan. Terraform's exit code still tests them.
  const expectedValidationFailures = ['reject_environment_mismatch', 'reject_unapproved_region'];
  const plans = events.filter(event => event.type === 'test_plan' && !expectedValidationFailures.includes(event['@testrun']));
  if (!plans.length) throw new Error('Terraform emitted no plans to check.');
  for (const event of plans) {
    const plan = event.test_plan;
    const input = join(temp, 'mock-plan.json');
    writeFileSync(input, JSON.stringify({format_version:plan.plan_format_version, resource_changes:plan.resource_changes}), {mode:0o600});
    const policy = spawnSync(process.execPath, [resolve(root, 'scripts/check-plan.mjs'), input], {encoding:'utf8'});
    if (policy.status !== 0) throw new Error(`${directory}/${event['@testrun']}: ${policy.stderr}`);
  }
  console.log(`${directory}: Terraform tests passed; ${plans.length} generated plans passed OPA.`);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  rmSync(join(temp, 'mock-plan.json'), {force:true});
  rmdirSync(temp);
}
