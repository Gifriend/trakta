import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { svelteAutofixer } from '@sveltejs/mcp';

async function walk(directory) {
	const files = [];
	for (const entry of await readdir(directory, { withFileTypes: true })) {
		const path = join(directory, entry.name);
		if (entry.isDirectory()) files.push(...(await walk(path)));
		else if (entry.name.endsWith('.svelte')) files.push(path);
	}
	return files;
}
for (const filename of await walk('src')) {
	const result = await svelteAutofixer({
		code: await readFile(filename, 'utf8'),
		filename,
		desired_svelte_version: '5.57.2',
		async: false
	});
	console.log(JSON.stringify({ filename, ...result }));
	if (result.issues.length) process.exitCode = 1;
}
