import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';

const gitFiles = (args) => {
    const result = spawnSync('git', args, { encoding: 'buffer' });

    if (result.status !== 0) {
        process.stderr.write(result.stderr);
        process.exit(result.status ?? 1);
    }

    return result.stdout.toString().split('\0').filter(Boolean);
};

const files = [
    ...gitFiles(['diff', '--name-only', '--diff-filter=ACMRT', '-z', '--', 'force-app']),
    ...gitFiles(['ls-files', '--others', '--exclude-standard', '-z', '--', 'force-app'])
];
const uniqueFiles = [...new Set(files)];

if (uniqueFiles.length === 0) {
    console.log('No retrieved source files need normalization.');
    process.exit(0);
}

const prettier = process.platform === 'win32' ? 'node_modules\\.bin\\prettier.cmd' : 'node_modules/.bin/prettier';

if (!existsSync(prettier)) {
    console.error('Prettier is not installed. Run npm install before normalizing retrieved source.');
    process.exit(1);
}

const chunkSize = 200;

for (let index = 0; index < uniqueFiles.length; index += chunkSize) {
    const chunk = uniqueFiles.slice(index, index + chunkSize);
    const result = spawnSync(prettier, ['--write', '--ignore-unknown', '--ignore-path', '.prettierignore', ...chunk], {
        stdio: 'inherit'
    });

    if (result.status !== 0) {
        process.exit(result.status ?? 1);
    }
}

// Prettier deliberately skips a small number of legacy source files that it
// cannot parse. Salesforce still removes their final newline on retrieve, so
// normalize that byte-level difference without changing their contents.
const newlineExtensions = ['.cls', '.cmp', '.component', '.css', '.html', '.js', '.json', '.md', '.page', '.trigger'];

for (const file of uniqueFiles) {
    if (!existsSync(file) || !newlineExtensions.some((extension) => file.endsWith(extension))) {
        continue;
    }

    const contents = readFileSync(file);

    if (contents.length > 0 && contents.at(-1) !== 10) {
        writeFileSync(file, Buffer.concat([contents, Buffer.from('\n')]));
    }
}

console.log(`Normalized ${uniqueFiles.length} retrieved source files.`);
