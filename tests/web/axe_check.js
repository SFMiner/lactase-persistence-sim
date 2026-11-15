// axe-core check of the HTML shell around the canvas (not of the game inside the canvas, which axe cannot see).
//   $env:NODE_PATH = "<game-sim-server>\node_modules"; $env:PORT = "8793"; node tests/web/axe_check.js
// Exits 1 on any violation. Same check as cell-designer and data-detectives tests/web/axe_check.js.
const { chromium } = require('playwright');
const { AxeBuilder } = require('@axe-core/playwright');
const port = process.env.PORT || '8793';

(async () => {
	const browser = await chromium.launch({ channel: 'chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
	const context = await browser.newContext({ viewport: { width: 1180, height: 500 } });
	const page = await context.newPage();
	let total = 0;
	for (const [label, wait] of [['loading', 300], ['running', 8000]]) {
		await page.goto('http://127.0.0.1:' + port + '/game/index.html');
		await page.waitForTimeout(wait);
		const result = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa']).analyze();
		for (const v of result.violations) {
			console.log('  FAIL ' + label + ': ' + v.id + ' (' + v.impact + '): ' + v.help + ' -> ' + v.nodes.map((n) => n.target.join(' ')).join(', '));
		}
		console.log('  ' + label + ': ' + result.violations.length + ' violations, ' + result.passes.length + ' rules passed');
		total += result.violations.length;
	}
	console.log('AXE ' + (total === 0 ? 'PASS' : 'FAIL'));
	await browser.close();
	process.exit(total === 0 ? 0 : 1);
})();
