#!/usr/bin/env node
// Deterministic replacement for the TODO lint agent (lint-agent.md).
// Usage: node ~/.claude/skills/todo/lint.mjs [--dry-run] [--todo-dir <path>]
//
// Does everything lint-agent.md specifies EXCEPT the git commit (the
// orchestrator reviews the report and commits):
//   1. Move tasks to their status directory (git mv, atomic renames)
//   2. Auto-archive done/closed (>24h or count>30) — never anything with an
//      open REVIEW-QUEUE line (file OR directory link) or human-validation: pending
//   3. Regenerate INDEX.md (sections keyed on actual status, counts = rows)
//   4. Rewrite REVIEW-QUEUE.md links for files that moved
//   5. Self-check: link resolution, status enum, clean renames
// Exits 0 on success (report on stdout), 1 on any self-check failure.

import { execFileSync } from 'node:child_process';
import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

const args = process.argv.slice(2);
const DRY = args.includes('--dry-run');
const dirFlag = args.indexOf('--todo-dir');
const TODO = resolve(dirFlag >= 0 ? args[dirFlag + 1] : '.agents/TODO');
const REPO = execFileSync('git', ['rev-parse', '--show-toplevel'], { cwd: TODO, encoding: 'utf8' }).trim();

const NON_TASK = new Set(['INDEX.md', 'REVIEW-QUEUE.md', 'CONTINUATION.md']);
const STATUSES = new Set(['pending', 'in-progress', 'blocked', 'done', 'closed', 'backlog']);
const PRIORITIES = ['P0', 'P1', 'P2', 'P3', 'P4', 'P5'];
const PRIORITY_NAMES = { P0: 'Critical', P1: 'High', P2: 'Normal', P3: 'Low', P4: 'Someday', P5: 'Wishlist' };

const warnings = [];
const errors = [];
const moves = []; // {from, to, slug}

function git(...a) {
  return execFileSync('git', a, { cwd: REPO, encoding: 'utf8' });
}

function listTasks(dir) {
  const abs = join(TODO, dir);
  if (!existsSync(abs)) return [];
  return readdirSync(abs)
    .filter((f) => f.endsWith('.md') && !NON_TASK.has(f) && !f.startsWith('.'))
    .map((f) => parseTask(join(dir, f)));
}

function parseTask(rel) {
  const abs = join(TODO, rel);
  const text = readFileSync(abs, 'utf8');
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  const fm = {};
  if (!m) {
    warnings.push(`NO FRONTMATTER: ${rel}`);
  } else {
    for (const line of m[1].split('\n')) {
      const kv = line.match(/^([A-Za-z-]+):\s*(.*)$/);
      if (!kv) continue;
      let v = kv[2].trim();
      if (v.startsWith('[') && v.endsWith(']')) {
        fm[kv[1]] = v.slice(1, -1).split(',').map((s) => s.trim()).filter(Boolean);
      } else {
        fm[kv[1]] = v.replace(/\s+#.*$/, '').replace(/^["']|["']$/g, '');
      }
    }
  }
  return { rel, file: rel.split('/').pop(), slug: fm.slug ?? rel.split('/').pop().replace(/\.md$/, ''), fm };
}

function validate(t) {
  for (const req of ['slug', 'title', 'priority', 'status', 'created', 'updated']) {
    if (!t.fm[req]) warnings.push(`MISSING ${req}: ${t.rel}`);
  }
  if (t.fm.status && !STATUSES.has(t.fm.status)) errors.push(`BAD STATUS '${t.fm.status}': ${t.rel} (schema is kebab-case: ${[...STATUSES].join(', ')})`);
  if (t.fm.slug && t.fm.slug !== t.file.replace(/\.md$/, '')) warnings.push(`SLUG/FILENAME MISMATCH: ${t.rel} (slug: ${t.fm.slug})`);
}

function gitMv(fromRel, toRel) {
  const from = relative(REPO, join(TODO, fromRel));
  const to = relative(REPO, join(TODO, toRel));
  moves.push({ from: fromRel, to: toRel });
  if (DRY) return;
  const destDir = join(TODO, toRel, '..');
  if (!existsSync(destDir)) mkdirSync(destDir, { recursive: true });
  git('mv', from, to);
}

// ---------- 1. Moves by status ----------
for (const t of listTasks('.')) {
  validate(t);
  const s = t.fm.status;
  if (s === 'done') gitMv(t.rel, `done/${t.file}`);
  else if (s === 'closed') gitMv(t.rel, `closed/${t.file}`);
  else if (s === 'backlog') gitMv(t.rel, `backlog/${t.file}`);
}
for (const t of listTasks('backlog')) {
  validate(t);
  if (t.fm.status === 'closed') gitMv(t.rel, `closed/${t.file}`);
  else if (t.fm.status !== 'backlog') gitMv(t.rel, t.file); // promoted
}
for (const t of listTasks('done')) validate(t);
for (const t of listTasks('closed')) validate(t);

// ---------- 2. Archive (guarded) ----------
const rqPath = join(TODO, 'REVIEW-QUEUE.md');
const rqText = existsSync(rqPath) ? readFileSync(rqPath, 'utf8') : '';
// Open review lines protect their link targets; a directory target protects the whole dir.
const protectedFiles = new Set();
const protectedDirs = new Set();
const openLines = [];
for (const line of rqText.split('\n')) {
  if (!/^\s*- \[ \]/.test(line)) continue;
  openLines.push(line);
  for (const lm of line.matchAll(/\]\(([^)]+)\)/g)) {
    const target = lm[1];
    if (target.endsWith('/') || !target.endsWith('.md')) protectedDirs.add(target.replace(/\/$/, ''));
    else protectedFiles.add(target);
  }
}
const openText = openLines.join('\n');
function isProtected(rel, fm, slug) {
  if (fm['human-validation'] === 'pending') return true;
  if (protectedFiles.has(rel)) return true;
  for (const d of protectedDirs) if (rel.startsWith(d + '/')) return true;
  // Batch review lines (e.g. sweep-chunk-N) cover tasks by prose mention, not
  // link — a slug appearing ANYWHERE in an open line keeps the task unarchived.
  if (slug && openText.includes(slug)) return true;
  return false;
}
const now = new Date();
const cutoff = new Date(now.getTime() - 24 * 3600 * 1000);
const cutoffStr = `${cutoff.getFullYear()}-${String(cutoff.getMonth() + 1).padStart(2, '0')}-${String(cutoff.getDate()).padStart(2, '0')}_${String(cutoff.getHours()).padStart(2, '0')}:${String(cutoff.getMinutes()).padStart(2, '0')}`;
let archived = 0;
for (const dir of ['done', 'closed']) {
  // Re-list AFTER moves so newly moved files are seen (they are protected anyway if under review).
  const tasks = listTasks(dir).filter((t) => !moves.some((m) => m.to === t.rel && DRY)); // dry-run: moved files not on disk yet
  const eligible = tasks.filter((t) => !isProtected(t.rel, t.fm, t.slug));
  const old = eligible.filter((t) => (t.fm.updated ?? '9999') < cutoffStr);
  let toArchive = new Set(old.map((t) => t.rel));
  if (tasks.length - toArchive.size > 30) {
    const remaining = eligible.filter((t) => !toArchive.has(t.rel)).sort((a, b) => (a.fm.updated ?? '').localeCompare(b.fm.updated ?? ''));
    for (const t of remaining) {
      if (tasks.length - toArchive.size <= 30) break;
      toArchive.add(t.rel);
    }
  }
  for (const t of tasks.filter((t) => toArchive.has(t.rel))) {
    const day = (t.fm.updated ?? '0000-00-00').slice(0, 10);
    gitMv(t.rel, `archive/${dir}/${day}/${t.file}`);
    archived++;
  }
}

// ---------- 4. Rewrite REVIEW-QUEUE links for moved files ----------
let rqNew = rqText;
for (const m of moves) {
  rqNew = rqNew.split(`](${m.from})`).join(`](${m.to})`);
}
if (rqNew !== rqText && !DRY) writeFileSync(rqPath, rqNew);

// ---------- 3. Regenerate INDEX ----------
// In dry-run, moved files are still at their old path; compute virtual placement.
function virtualRel(t) {
  const m = moves.find((mv) => mv.from === t.rel);
  return m ? m.to : t.rel;
}
const all = [];
for (const dir of ['.', 'backlog', 'done', 'closed']) {
  for (const t of listTasks(dir)) {
    if (moves.some((m) => m.from === t.rel)) t.rel = virtualRel(t); // reflect final placement
    if (t.rel.startsWith('archive/')) continue;
    all.push(t);
  }
}
// De-dup (a file may appear at old+new path timing in non-dry runs it's already moved)
const seen = new Set();
const tasks = all.filter((t) => (seen.has(t.rel) ? false : (seen.add(t.rel), true)));

const byStatus = {};
for (const t of tasks) (byStatus[t.fm.status] ??= []).push(t);
const prioSort = (a, b) =>
  PRIORITIES.indexOf(a.fm.priority) - PRIORITIES.indexOf(b.fm.priority) || String(a.fm.created ?? '').localeCompare(String(b.fm.created ?? ''));

function rows(list, marker, withDeps = false) {
  return list
    .map((t) => {
      const deps = withDeps && Array.isArray(t.fm['depends-on']) && t.fm['depends-on'].length ? ` (blocked by: ${t.fm['depends-on'].join(', ')})` : '';
      return marker === null
        ? `- [${t.slug}](${t.rel}) - ${t.fm.title ?? t.slug}${deps}`
        : `- [${marker}] [${t.slug}](${t.rel}) - ${t.fm.title ?? t.slug}${deps}`;
    })
    .join('\n');
}
function prioritySection(list, marker) {
  const out = [];
  for (const p of PRIORITIES) {
    const sub = list.filter((t) => t.fm.priority === p);
    if (!sub.length) continue;
    out.push(`### ${p} - ${PRIORITY_NAMES[p]}\n${rows(sub.sort(prioSort), marker)}`);
  }
  return out.join('\n\n');
}
const sections = [];
const push = (title, body, n) => { if (n) sections.push(`## ${title} (${n})\n\n${body}`); };
const pend = (byStatus['pending'] ?? []).sort(prioSort);
push('Pending', prioritySection(pend, ' '), pend.length);
const prog = (byStatus['in-progress'] ?? []).sort(prioSort);
push('In Progress', rows(prog, '~'), prog.length);
const blocked = (byStatus['blocked'] ?? []).sort(prioSort);
push('Blocked', rows(blocked, '!', true), blocked.length);
const done = (byStatus['done'] ?? []).sort(prioSort);
push('Done', rows(done, 'x'), done.length);
const closed = (byStatus['closed'] ?? []).sort(prioSort);
push('Closed', rows(closed, null), closed.length);
const back = (byStatus['backlog'] ?? []).sort(prioSort);
push('Backlog', prioritySection(back, '-'), back.length);

const index = `# TODO Index\n> Auto-generated. Run \`/todo lint\` to regenerate.\n\n${sections.join('\n\n')}\n`;
if (!DRY) writeFileSync(join(TODO, 'INDEX.md'), index);

// ---------- 5. Self-check ----------
if (!DRY) {
  for (const [name, text] of [['INDEX.md', index], ['REVIEW-QUEUE.md', rqNew]]) {
    for (const lm of text.matchAll(/\]\(([^)]+)\)/g)) {
      const target = lm[1];
      if (/^https?:/.test(target)) continue;
      const p = join(TODO, target);
      if (!existsSync(p)) errors.push(`BROKEN LINK in ${name}: ${target}`);
    }
  }
  const status = git('status', '--short', '--', relative(REPO, TODO)).trim();
  for (const line of status.split('\n').filter(Boolean)) {
    if (/^.?D /.test(line) && !/^R/.test(line)) errors.push(`UNSTAGED DELETE: ${line.trim()} (move was not a clean rename)`);
  }
}

// ---------- Report ----------
const count = (s) => (byStatus[s] ?? []).length;
console.log(`Lint ${DRY ? '(dry-run) ' : ''}Complete
─────────────
Active: ${count('pending') + count('in-progress') + count('blocked')} (pending ${count('pending')}, in-progress ${count('in-progress')}, blocked ${count('blocked')}) | Backlog: ${count('backlog')} | Done: ${count('done')} | Closed: ${count('closed')} | Archived this run: ${archived}
Moves: ${moves.length ? moves.map((m) => `${m.from} -> ${m.to}`).join('; ') : 'none'}
INDEX.md: ${DRY ? 'would regenerate' : 'regenerated'} · REVIEW-QUEUE links: ${DRY ? 'n/a' : errors.some((e) => e.includes('BROKEN')) ? 'BROKEN — see errors' : 'all resolve'}`);
if (warnings.length) console.log(`\nWarnings:\n${warnings.map((w) => `  - ${w}`).join('\n')}`);
if (errors.length) {
  console.error(`\nERRORS (fix before committing):\n${errors.map((e) => `  - ${e}`).join('\n')}`);
  process.exit(1);
}
if (!DRY) console.log(`\nTo commit: git add -A ':(top)${relative(REPO, TODO)}' && git commit -m "[todo] Lint: ..."`);
