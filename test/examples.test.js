/**
 * @file        test/examples.test.js
 * @description Checks the examples: scripts parse, Client configs are valid and render their udev rules, and — in the
 *              TestHub monorepo — the README and the Help page show every script exactly as it is in this repository
 *
 * @author      Andrian Yablonskyy
 * @copyright   Copyright (c) 2026 Andrian Yablonskyy. MIT License (see LICENSE).
 */

'use strict';

const test = require('node:test'),
  assert = require('node:assert/strict'),
  fs = require('node:fs'),
  path = require('node:path'),
  { execFileSync, spawnSync } = require('node:child_process');

const ROOT = path.join(__dirname, '..'),
  // In the monorepo: packages/client-examples, next to the docs and the Client.
  MONOREPO = path.join(ROOT, '..', '..'),
  README = path.join(MONOREPO, 'README.md'),
  HELP_DIR = path.join(MONOREPO, 'packages', 'coordinator', 'views', 'help'),
  REPO_URL = 'https://github.com/andrianyablonskyy/thub-examples/blob/main/',
  inMonorepo = fs.existsSync(README) && fs.existsSync(HELP_DIR),
  read = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8'),
  list = (dir, ext) => fs.readdirSync(path.join(ROOT, dir)).filter((f) => f.endsWith(ext)).map((f) => `${dir}/${f}`),
  has = (cmd) => spawnSync(cmd, ['--version'], { stdio: 'ignore' }).status === 0,
  // Optional: these come from the monorepo (or an npm install of them).
  optional = (id) => {
    try {
      return require(id);
    }
    catch {
      return null;
    }
  };

test('shell scripts parse and are executable', () => {
  for (const file of [...list('ci', '.sh'), ...list('host', '.sh')]){
    execFileSync('sh', ['-n', path.join(ROOT, file)]);
    assert.ok(fs.statSync(path.join(ROOT, file)).mode & 0o111, `${file} is executable`);
    assert.match(read(file), /^#!\/bin\/sh\n# [\w/.-]+/, `${file} starts with #!/bin/sh and a comment naming it`);
  }
});

test('Python scripts parse', { skip: !has('python3') && 'no python3' }, () => {
  for (const file of [...list('ci', '.py'), ...list('tests', '.py')]){
    execFileSync('python3', ['-c', 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])', path.join(ROOT, file)]);
  }
});

test('Client configs: valid hw-devices, and the udev rules they generate', () => {
  const common = optional('@andrian.yablonskyy/thub-common'),
    clientConfig = optional(path.join(MONOREPO, 'packages', 'client', 'src', 'config')),
    udev = optional(path.join(MONOREPO, 'packages', 'client', 'src', 'udev'));
  for (const file of list('config', '.json')){
    const cfg = JSON.parse(read(file));
    assert.ok(['hw', 'sw'].includes(cfg.type), `${file}: type`);
    assert.ok(Array.isArray(cfg.labels) && cfg.labels.length, `${file}: labels`);
    if (cfg.type === 'hw' && common){
      const { valid, errors } = common.validateClientConfig('hw', cfg['hw-devices']);
      assert.ok(valid, `${file}: ${errors.join('; ')}`);
    }
    if (clientConfig && udev){
      const rules = udev.renderRules(clientConfig.loadDeviceConfig(path.join(ROOT, file)));
      if (cfg.type === 'sw'){
        assert.equal(rules, null, `${file}: an SW Client gets no udev rules`);
      }
    }
  }
});

// --- in the monorepo: the documentation shows these files as they are -------

// README code blocks that are one of these files: a script whose first lines
// name it (`# ci/nucleo.sh …`, `"""ci/bf-cli.py …`), and the Renode test.
function readmeBlocks(){
  const md = fs.readFileSync(README, 'utf8'),
    blocks = [];
  for (const [, indent, lang, code]of md.matchAll(/^( *)```(\w*)\n([\s\S]*?)^\1```/gm)){
    const text = code.split('\n').map((l) => (l.startsWith(indent) ? l.slice(indent.length) : l)).join('\n'),
      named = text.split('\n').slice(0, 3).join('\n').match(/(?:#|""")\s*((?:ci|tests|host)\/[\w./-]+)/);
    if (text.startsWith('#!') && named){
      blocks.push({ file: named[1], text });
    }
    else if (lang === 'robot'){
      blocks.push({ file: 'tests/renode/self-test.robot', text });
    }
  }
  return blocks;
}

// Help page code blocks whose caption is one of these files:
// +code('ci/run.sh — …') or +code('ci/run.sh', …), body indented below it.
function helpBlocks(){
  const blocks = [];
  for (const name of fs.readdirSync(HELP_DIR).filter((f) => f.endsWith('.pug'))){
    const lines = fs.readFileSync(path.join(HELP_DIR, name), 'utf8').split('\n');
    lines.forEach((line, i) => {
      const m = line.match(/^( *)\+code\('((?:ci|tests|host)\/[\w./-]+)/);
      if (!m){
        return;
      }
      const body = [],
        inner = `${m[1]}  `;
      for (let j = i + 1; j < lines.length && (lines[j] === '' || lines[j].startsWith(inner)); j++){
        body.push(lines[j].slice(inner.length));
      }
      while (body.length && body.at(-1) === ''){
        body.pop();
      }
      const text = `${body.join('\n')}\n`.replace(/&lt;/g, '<').replace(/\\#([{[])/g, '#$1');
      blocks.push({ file: m[2], text, where: `views/help/${name}:${i + 1}` });
    });
  }
  return blocks;
}

test('README shows each script as it is here', { skip: !inMonorepo && 'not in the TestHub monorepo' }, () => {
  const blocks = readmeBlocks();
  assert.ok(blocks.length >= 15, `found ${blocks.length} script blocks`);
  for (const { file, text }of blocks){
    assert.ok(fs.existsSync(path.join(ROOT, file)), `README shows ${file}, which isn't in client-examples`);
    assert.equal(text, read(file), `README's ${file} differs from client-examples/${file}`);
  }
});

test('the Help page shows each script as it is here', { skip: !inMonorepo && 'not in the TestHub monorepo' }, () => {
  const blocks = helpBlocks();
  assert.ok(blocks.length >= 15, `found ${blocks.length} script blocks`);
  for (const { file, text, where }of blocks){
    assert.ok(fs.existsSync(path.join(ROOT, file)), `${where} shows ${file}, which isn't in client-examples`);
    assert.equal(text, read(file), `${where}: ${file} differs from client-examples/${file}`);
  }
});

test('links to this repository point at files that exist', { skip: !inMonorepo && 'not in the TestHub monorepo' }, () => {
  const docs = [README, ...fs.readdirSync(HELP_DIR).map((f) => path.join(HELP_DIR, f))].map((f) => fs.readFileSync(f, 'utf8')).join('\n'),
    linked = new Set([
      ...[...docs.matchAll(new RegExp(`${REPO_URL.replace(/[.]/g, '\\.')}([\\w./-]+)`, 'g'))].map((m) => m[1]),
      // The Help page links them with +example('…') (views/help/_mixins.pug).
      ...[...docs.matchAll(/\+example\('([^']+)'\)/g)].map((m) => m[1])
    ]);
  assert.ok(linked.size > 0, 'the docs link to the examples');
  for (const file of linked){
    assert.ok(fs.existsSync(path.join(ROOT, file)), `the docs link to ${file}, which isn't in client-examples`);
  }
});
