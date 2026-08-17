import { spawnSync } from 'node:child_process';

const sf = process.platform === 'win32' ? 'sf.cmd' : 'sf';
const retrieve = spawnSync(sf, ['project', 'retrieve', 'start', ...process.argv.slice(2)], { stdio: 'inherit' });

if (retrieve.status !== 0) {
    process.exit(retrieve.status ?? 1);
}

const normalize = spawnSync(process.execPath, ['scripts/normalize-retrieved-source.mjs'], { stdio: 'inherit' });

process.exit(normalize.status ?? 1);
