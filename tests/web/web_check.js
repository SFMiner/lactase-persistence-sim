// Browser check of the real web export, driven by Playwright with the installed Google Chrome.
//
// 1. Copy the export to <root>/game/ and tests/web/harness.html to <root>/ (any folder outside the project).
// 2. Serve it:  python -m http.server 8793 --bind 127.0.0.1 --directory <root>   (check the port is free)
// 3. Run:       $env:NODE_PATH = "<game-sim-server>\node_modules"; $env:PORT = "8793"
//               node tests/web/web_check.js <folder for screenshots> [headed]
//    "headed" opens a visible Chrome window (real GPU); without it Chrome runs headless (software GL).
//    QUICK=1 shortens the 60 s no-input wait to 6 s.
// Exit code 0 only if every check passes. Screenshots are for a person to look at afterwards.
// The simulator prints short "lactase-sim: ..." lines to the console; the checks wait for those,
// so a grey canvas with no errors cannot pass.
const { chromium } = require('playwright');
const shots = process.argv[2] || '.';
const headed = process.argv[3] === 'headed';
const port = process.env.PORT || '8793';
const base = 'http://127.0.0.1:' + port;
const idleMs = process.env.QUICK ? 6000 : 60000;

const results = [];
function check(ok, label) {
	results.push({ ok: !!ok, label });
	console.log((ok ? '  ok    ' : '  FAIL  ') + label);
}

(async () => {
	const launch = { channel: 'chrome', headless: !headed };
	if (!headed) {
		launch.args = ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'];
	}
	const browser = await chromium.launch(launch);
	console.log('browser: Google Chrome ' + browser.version() + (headed ? ' (headed window)' : ' (headless)'));

	async function open(context, url) {
		const page = await context.newPage();
		const logs = [];
		const requests = [];
		page.on('console', (m) => logs.push(m.text()));
		page.on('pageerror', (e) => logs.push('pageerror: ' + e.message));
		page.on('request', (r) => requests.push(r.url()));
		await page.goto(url);
		const waitLog = async (text, ms = 30000) => {
			const end = Date.now() + ms;
			while (Date.now() < end) {
				if (logs.some((l) => l.includes(text))) return true;
				await page.waitForTimeout(100);
			}
			return false;
		};
		const count = (text) => logs.filter((l) => l.includes(text)).length;
		return { page, logs, requests, waitLog, count };
	}
	const key = async (page, k, n = 1) => {
		for (let i = 0; i < n; i++) { await page.keyboard.press(k); await page.waitForTimeout(160); }
	};
	const same = (a, b) => Buffer.compare(a, b) === 0;
	const badLogs = (logs) => logs.filter((l) => /SCRIPT ERROR|pageerror|Parse Error|USER ERROR|^ERROR/.test(l));

	// ---------- 1. Standalone tab, 1180x500 ----------
	// Tab order on the menu: Mode, Labels, Help, Settings, then the four tiles.
	// Tab order in a model view: Home, Mode, Labels, Help, Settings, then the view's own controls.
	console.log('standalone 1180x500');
	let ctx = await browser.newContext({ viewport: { width: 1180, height: 500 } });
	let s = await open(ctx, base + '/game/index.html');
	check(await s.waitLog('lactase-sim: boot ok'), 'standalone: console shows "lactase-sim: boot ok"');
	check(s.count('settings mode=explore labels=on motion=normal text=0') === 1, 'standalone: defaults are Explore, labels on, normal motion, normal text');
	check(s.count('lactase-sim: view menu') === 1, 'standalone: opens on Choose a Model');
	check(s.count('layout 1180x500 css=1.00 dpr=1.00') >= 1, 'standalone: 1180 x 500 frame gives a 1180 x 500 layout at 1 CSS px');
	await s.page.waitForTimeout(1500);
	const idleA = await s.page.screenshot({ path: shots + '/web_standalone_menu.png' });
	await s.page.waitForTimeout(idleMs);
	const idleB = await s.page.screenshot();
	check(same(idleA, idleB), 'no auto-play: the menu is pixel-identical after ' + (idleMs / 1000) + ' s without input');
	await s.page.mouse.click(1100, 20); // empty reserved corner: focuses the canvas, presses nothing
	await key(s.page, 'Tab', 5);
	await s.page.screenshot({ path: shots + '/web_standalone_menu_focus.png' });
	await key(s.page, 'Enter');
	check(await s.waitLog('lactase-sim: view molecules', 4000), 'standalone: Tab to the Molecules tile and Enter opens it');
	await s.page.waitForTimeout(800);
	const molA = await s.page.screenshot({ path: shots + '/web_standalone_molecules_start.png' });
	await s.page.waitForTimeout(Math.min(idleMs, 10000));
	const molB = await s.page.screenshot();
	check(same(molA, molB), 'no auto-play: the Molecules view does not move until Run is pressed');
	await key(s.page, 'Tab', 6);
	await key(s.page, 'Enter');
	check(await s.waitLog('lactase-sim: molecules run', 3000), 'standalone: Tab to Run and Enter starts the run');
	await s.page.waitForTimeout(2500);
	const runA = await s.page.screenshot({ path: shots + '/web_standalone_molecules_running.png' });
	await s.page.waitForTimeout(700);
	const runB = await s.page.screenshot();
	check(!same(runA, runB), 'standalone: the picture changes while running');
	await key(s.page, 'Enter'); // focus is still on the same button, now Pause
	await s.page.waitForTimeout(400);
	const pausedA = await s.page.screenshot({ path: shots + '/web_standalone_molecules_paused.png' });
	await s.page.waitForTimeout(4000);
	const pausedB = await s.page.screenshot();
	check(same(pausedA, pausedB), 'standalone: Pause freezes the whole frame for 4 s (pixel-identical)');
	await key(s.page, 'Enter');
	check(await s.waitLog('molecules finished split=50 left=0 lactase=8', 30000), 'standalone: the run finishes with 50 lactose split, 0 left and still 8 lactase');
	await s.page.waitForTimeout(500);
	await s.page.screenshot({ path: shots + '/web_standalone_molecules_finished.png' });
	check(badLogs(s.logs).length === 0, 'standalone: no SCRIPT ERROR or page error in the console (' + badLogs(s.logs).length + ')');
	// data: and blob: URLs are made inside the page and never touch the network.
	const foreign = s.requests.filter((u) => !u.startsWith(base) && !u.startsWith('data:') && !u.startsWith('blob:'));
	console.log('  requests: ' + s.requests.map((u) => u.length > 70 ? u.slice(0, 70) + '...' : u).join(' | '));
	check(foreign.length === 0, 'standalone: every network request stays on the simulator\'s own origin (' + s.requests.length + ' requests, ' + foreign.length + ' elsewhere)');
	await ctx.close();

	// ---------- 2. Class settings in the address, and each model opened directly ----------
	console.log('class settings');
	ctx = await browser.newContext({ viewport: { width: 1180, height: 500 } });
	s = await open(ctx, base + '/game/index.html?model=population&mode=explain&motion=reduced&labels=off');
	check(await s.waitLog('lactase-sim: boot ok'), 'query: boots with all four settings');
	check(s.count('settings mode=explain labels=off motion=reduced') === 1 && s.count('lactase-sim: view population') === 1,
		'query: ?model=population&mode=explain&motion=reduced&labels=off is applied');
	await s.page.mouse.click(1100, 20);
	await key(s.page, 'Tab', 6); // Run 10 generations
	await key(s.page, 'Enter');
	check(await s.waitLog('population run done gen=10 p=0.1000', 4000), 'query: reduced motion shows ten generations at once; with no advantage P stays at 10%');
	await s.page.waitForTimeout(600);
	await s.page.screenshot({ path: shots + '/web_query_population_explain_nolabels.png' });
	check(badLogs(s.logs).length === 0, 'query: no SCRIPT ERROR or page error');
	await s.page.close();
	s = await open(ctx, base + '/game/index.html?model=admin&mode=teacher&labels=maybe&debug=1');
	check(await s.waitLog('lactase-sim: boot ok'), 'query: boots with unknown settings');
	check(s.count('settings mode=explore labels=on motion=normal') === 1 && s.count('lactase-sim: view menu') === 1,
		'query: unknown keys and values fall back to the defaults');
	check(badLogs(s.logs).length === 0, 'query: no SCRIPT ERROR or page error with unknown settings');
	await s.page.close();
	// The browser's own "reduce motion" preference is the default when nothing else is chosen.
	const calm = await browser.newContext({ viewport: { width: 1180, height: 500 }, reducedMotion: 'reduce' });
	const c = await open(calm, base + '/game/index.html');
	check(await c.waitLog('lactase-sim: boot ok') && c.count('settings mode=explore labels=on motion=reduced') === 1,
		'query: with the browser set to reduce motion, the simulator starts with reduced motion');
	check(badLogs(c.logs).length === 0, 'query: no SCRIPT ERROR or page error with the reduced-motion preference');
	await calm.close();
	const calm2 = await browser.newContext({ viewport: { width: 1180, height: 500 }, reducedMotion: 'reduce' });
	const c2 = await open(calm2, base + '/game/index.html?motion=normal');
	check(await c2.waitLog('lactase-sim: boot ok') && c2.count('motion=normal') === 1,
		'query: the class setting motion=normal overrides the browser preference');
	await calm2.close();
	// Generations: change the setting, then step.
	s = await open(ctx, base + '/game/index.html?model=population');
	check(await s.waitLog('lactase-sim: view population'), 'population: opens directly');
	await s.page.mouse.click(1100, 20);
	await key(s.page, 'Tab', 7); // Step 1 generation
	await key(s.page, 'Enter');
	check(await s.waitLog('population step gen=1 p=0.1000', 3000), 'population: Step makes one generation; no advantage, P unchanged');
	await key(s.page, 'Tab', 7); // Reset, Speed, 1%, 10%, 30%, Compare, then "Little or no fresh milk"
	await key(s.page, 'Tab');    // "Fresh milk is an important food"
	await key(s.page, 'Enter');
	await key(s.page, 'Shift+Tab', 8); // back to Step
	await key(s.page, 'Enter');
	check(await s.waitLog('population step gen=2 p=0.1040', 3000), 'population: with fresh milk important (mild), the next generation has P at 10.40%');
	await s.page.waitForTimeout(500);
	await s.page.screenshot({ path: shots + '/web_population_step.png' });
	check(badLogs(s.logs).length === 0, 'population: no SCRIPT ERROR or page error');
	await s.page.close();
	// DNA & Lactase.
	s = await open(ctx, base + '/game/index.html?model=regulation&mode=explain');
	check(await s.waitLog('regulation Adult, typical decline, intestine cell expression=0.10 lactase=2'), 'regulation: opens on an adult with typical regulation, 2 lactase');
	await s.page.mouse.click(1100, 20);
	await key(s.page, 'Tab', 6); // Run
	await key(s.page, 'Enter');
	check(await s.waitLog('lactase-sim: regulation run', 3000), 'regulation: Run starts from the keyboard');
	await s.page.waitForTimeout(3000);
	await s.page.screenshot({ path: shots + '/web_regulation_running.png' });
	check(await s.waitLog('regulation finished split=19 left=31', 30000), 'regulation: a typical adult splits 19 of 50 lactose in the period');
	check(badLogs(s.logs).length === 0, 'regulation: no SCRIPT ERROR or page error');
	await s.page.close();
	// Evidence.
	s = await open(ctx, base + '/game/index.html?model=evidence');
	check(await s.waitLog('evidence person=0 zoom=0'), 'evidence: opens on the chromosome');
	await s.page.mouse.click(1100, 20);
	await key(s.page, 'Tab', 12); // Home..Settings (5), four people, three zoom steps -> Upstream excerpt
	await key(s.page, 'Enter');
	check(await s.waitLog('evidence person=0 zoom=2', 3000), 'evidence: zoom to the upstream excerpt from the keyboard');
	await key(s.page, 'Tab'); // Compare
	await key(s.page, 'Enter');
	check(await s.waitLog('evidence person=0 zoom=2 compare=true', 3000), 'evidence: Compare lines up all four people');
	await key(s.page, 'Shift+Tab', 4); // person buttons are unavailable while comparing; back past Zoom to the table
	await s.page.waitForTimeout(200);
	await s.page.screenshot({ path: shots + '/web_evidence_compare.png' });
	check(badLogs(s.logs).length === 0, 'evidence: no SCRIPT ERROR or page error');
	await ctx.close();

	// ---------- 3. Same-origin iframe, 1180x500: keyboard walk-through ----------
	console.log('iframe 1180x500, keyboard only');
	ctx = await browser.newContext({ viewport: { width: 1240, height: 620 } });
	s = await open(ctx, base + '/harness.html');
	const leaves = () => s.page.evaluate(() => window.leaves);
	const active = () => s.page.evaluate(() => document.activeElement && document.activeElement.id);
	const frame = () => s.page.frames().find((f) => f.url().includes('/game/'));
	const clickEmpty = async () => { await frame().click('canvas', { position: { x: 1100, y: 20 } }); await s.page.waitForTimeout(250); };
	check(await s.waitLog('lactase-sim: boot ok'), 'iframe: console shows "lactase-sim: boot ok"');
	await s.page.waitForTimeout(1000);
	await s.page.screenshot({ path: shots + '/web_iframe_1180x500_menu.png' });
	await clickEmpty();
	await key(s.page, 'Tab', 3); // Help
	await s.page.screenshot({ path: shots + '/web_iframe_focus_help.png' });
	await key(s.page, 'Enter');
	check(await s.waitLog('lactase-sim: help open', 3000), 'iframe: Tab to Help and Enter opens the help box');
	await s.page.waitForTimeout(400);
	await s.page.screenshot({ path: shots + '/web_iframe_help.png' });
	await key(s.page, 'Escape');
	check(await s.waitLog('lactase-sim: overlay closed', 3000) && (await leaves()) === 0, 'iframe: Escape closes Help and does not leave');
	let before = await leaves();
	await key(s.page, 'Escape');
	check((await leaves()) === before + 1 && (await active()) === 'fs', 'iframe: Escape with nothing open leaves; focus lands on the host page\'s Full screen button');
	// Tab past the last control (menu ring has 8 controls).
	await clickEmpty();
	before = await leaves();
	await key(s.page, 'Tab', 8);
	check((await leaves()) === before, 'iframe: Tab walks all eight menu controls without leaving');
	await key(s.page, 'Tab');
	check((await leaves()) === before + 1 && (await active()) === 'fs', 'iframe: Tab past the last control sends exactly one sims:leave-game');
	// Shift+Tab before the first control.
	await clickEmpty();
	await key(s.page, 'Tab');
	before = await leaves();
	await key(s.page, 'Shift+Tab');
	check((await leaves()) === before + 1 && (await active()) === 'fs', 'iframe: Shift+Tab before the first control leaves to the host');
	// Open a model with the mouse, then leave with Escape from inside it.
	await frame().click('canvas', { position: { x: 150, y: 250 } }); // the Molecules tile
	check(await s.waitLog('lactase-sim: view molecules', 4000), 'iframe: a mouse click on the Molecules tile opens it');
	await s.page.waitForTimeout(600);
	await s.page.screenshot({ path: shots + '/web_iframe_1180x500_molecules.png' });
	await frame().click('canvas', { position: { x: 55, y: 78 } }); // Run
	check(await s.waitLog('lactase-sim: molecules run', 3000), 'iframe: a mouse click on Run starts the run');
	await s.page.waitForTimeout(1500);
	before = await leaves();
	await key(s.page, 'Escape');
	check((await leaves()) === before + 1, 'iframe: Escape while a model is running leaves the game');
	const types = await s.page.evaluate(() => window.messageTypes);
	check(types.length > 0 && types.every((t) => t === 'sims:leave-game'), 'iframe: the only messages posted to the host are sims:leave-game (' + types.length + ' in all; no scores or results)');
	check(badLogs(s.logs).length === 0, 'iframe: no SCRIPT ERROR or page error in the console (' + badLogs(s.logs).length + ')');
	await ctx.close();

	// ---------- 4. Other frame sizes (screenshots to inspect; boot, layout line and errors checked) ----------
	const variants = [
		{ name: 'iframe_1180x360', w: 1180, h: 360, dpr: 1, q: 'model=regulation', layout: 'layout 1388x423 css=0.85 dpr=1.00', view: 'regulation' },
		{ name: 'iframe_dpr1_5', w: 1180, h: 500, dpr: 1.5, q: 'model=molecules', layout: 'layout 1180x500 css=1.00 dpr=1.50', view: 'molecules' },
		{ name: 'iframe_zoom200_emulated', w: 590, h: 250, dpr: 2, q: 'model=evidence', layout: 'layout 694x294 css=0.85 dpr=2.00', view: 'evidence' },
		{ name: 'iframe_phone_like_380x640', w: 380, h: 640, dpr: 2, q: 'model=population', layout: 'layout 447x752 css=0.85 dpr=2.00', view: 'population' },
		{ name: 'iframe_1180x500_menu_dpr1_5', w: 1180, h: 500, dpr: 1.5, q: '', layout: 'layout 1180x500 css=1.00 dpr=1.50', view: 'menu' },
	];
	for (const v of variants) {
		console.log(v.name);
		ctx = await browser.newContext({ viewport: { width: v.w + 60, height: v.h + 120 }, deviceScaleFactor: v.dpr });
		s = await open(ctx, base + '/harness.html?w=' + v.w + '&h=' + v.h + '&q=' + encodeURIComponent(v.q));
		check(await s.waitLog('lactase-sim: boot ok'), v.name + ': boots');
		check(await s.waitLog('lactase-sim: view ' + v.view, 3000), v.name + ': opens the ' + v.view + ' view');
		check(await s.waitLog(v.layout, 3000), v.name + ': ' + v.layout);
		await s.page.waitForTimeout(1200);
		await s.page.screenshot({ path: shots + '/web_' + v.name + '.png' });
		// Resize the frame while it is open: the layout must follow.
		const lines = s.count('lactase-sim: layout');
		await s.page.evaluate(() => { const g = document.getElementById('g'); g.width = String(Math.round(g.width * 0.8)); });
		await s.page.waitForTimeout(900);
		check(s.count('lactase-sim: layout') > lines, v.name + ': the layout follows when the frame is resized');
		await s.page.screenshot({ path: shots + '/web_' + v.name + '_resized.png' });
		check(badLogs(s.logs).length === 0, v.name + ': no SCRIPT ERROR or page error');
		await ctx.close();
	}

	await browser.close();
	const failed = results.filter((r) => !r.ok).length;
	console.log('WEB CHECK: ' + (results.length - failed) + '/' + results.length + ' passed -> ' + (failed === 0 ? 'PASS' : 'FAIL'));
	process.exit(failed === 0 ? 0 : 1);
})().catch((e) => { console.error(e); process.exit(2); });
