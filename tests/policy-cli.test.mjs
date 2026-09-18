import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync, rmdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

function check(document, expected, env = process.env) {
  const directory = mkdtempSync(join(tmpdir(), 'landing-zone-policy-'));
  try {
    const file = join(directory, 'plan.json');
    writeFileSync(file, typeof document === 'string' ? document : JSON.stringify(document));
    const result = spawnSync(process.execPath, [resolve('scripts/check-plan.mjs'), file], {encoding:'utf8', env});
    assert.equal(result.status, expected, result.stderr);
    assert.ok(!(result.stdout + result.stderr).includes('sensitive-fixture-value'));
  } finally { rmSync(join(directory, 'plan.json'), {force:true}); rmdirSync(directory); }
}
test('permits an empty valid Terraform plan', () => check({format_version:'1.2',resource_changes:[]}, 0));
test('blocks the wrong input schema', () => check({resource:{}}, 1));
test('blocks malformed JSON', () => check('{broken', 2));
test('blocks public storage without printing plan secrets', () => check({format_version:'1.2',resource_changes:[{
  address:'module.data.azurerm_storage_account.example', mode:'managed', type:'azurerm_storage_account',
  change:{after:{public_network_access_enabled:true,secret:'sensitive-fixture-value'}}
}]}, 1));
test('blocks execution if OPA is unavailable', () => check({format_version:'1.2',resource_changes:[]}, 2, {...process.env, PATH:''}));
