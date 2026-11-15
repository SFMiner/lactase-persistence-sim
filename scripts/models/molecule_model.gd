class_name MoleculeModel
extends RefCounted
## Lactose digestion as a deterministic, discrete-event model (GDD section 4).
##
## Science rules, which the tests check:
## - Each cleavage removes exactly one lactose and adds exactly one glucose and one galactose.
## - Lactase is never used up: the number of enzymes is the same before, during and after a run.
## - No product ever appears without a cleavage, so zero lactase gives zero products.
## - Intact lactose is never absorbed; only glucose and galactose cross the lining.
## - Less lactase changes how much is digested in the available time, not how each enzyme works.
##
## The model runs on a fixed tick, so a run with the same settings and seed is identical however
## the frames fall. Positions are illustration only: an enzyme that is free picks the nearest
## unclaimed lactose, and the timing of the reaction never depends on distance.
## All numbers are illustrative classroom units, not measured rates.

# === CONSTANTS ===
const TICK: float = 1.0 / 30.0
## One enzyme cycle: draw the lactose in, cleave it, let the products go.
const BIND_TICKS: int = 18
const CLEAVE_TICKS: int = 15
const RESET_TICKS: int = 12
const CYCLE_TICKS: int = BIND_TICKS + CLEAVE_TICKS + RESET_TICKS
## The "available period": how long this stretch of intestine holds the lactose (15 model seconds).
const PERIOD_TICKS: int = 450
## Products drift for a moment, then cross the lining.
const PRODUCT_DRIFT_TICKS: int = 45
const PRODUCT_ABSORB_TICKS: int = 30
const MAX_LACTOSE: int = 100
const MAX_ENZYMES: int = 20
const MAX_SUPPLEMENT: int = 10
## Lumen box the free molecules drift in (normalised stage coordinates, y grows downward).
const LUMEN_TOP: float = 0.05
const LUMEN_BOTTOM: float = 0.56
const BORDER_Y: float = 1.0

enum Kind { LACTOSE, GLUCOSE, GALACTOSE }
enum EnzymeState { FREE, BINDING, CLEAVING, RESETTING }
enum ParticleState { FREE, CLAIMED, BOUND, DRIFTING, ABSORBING }


# === INNER CLASSES ===
class Enzyme:
	extends RefCounted
	var id: int = 0
	var pos: Vector2 = Vector2.ZERO
	var state: int = EnzymeState.FREE
	var timer: int = 0
	## Ticks to wait before the first search, so the enzymes do not all move in step.
	var delay: int = 0
	var target: int = -1
	## How many lactose molecules this one enzyme has cleaved.
	var turnovers: int = 0
	## True for enzyme added to the gut contents by a supplement, false for enzyme made by the cells.
	var supplement: bool = false


class Particle:
	extends RefCounted
	var id: int = 0
	var kind: int = Kind.LACTOSE
	var state: int = ParticleState.FREE
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	## Where the particle started (used for still pictures when motion is reduced).
	var home: Vector2 = Vector2.ZERO
	var from: Vector2 = Vector2.ZERO
	var to: Vector2 = Vector2.ZERO
	var timer: int = 0
	var enzyme: int = -1
	var angle: float = 0.0


# === PUBLIC VARIABLES ===
var rng_seed: int = 1
var lactose_start: int = 0
var enzyme_count: int = 0
var supplement_count: int = 0
## Lactose not yet cleaved (free, or held by an enzyme that has not finished).
var lactose_remaining: int = 0
var cleaved: int = 0
var glucose_formed: int = 0
var galactose_formed: int = 0
var glucose_absorbed: int = 0
var galactose_absorbed: int = 0
## Never changes from zero: kept as a counter so the tests can prove it.
var lactose_absorbed: int = 0
var tick_count: int = 0
var finished: bool = false
## Goes up by one whenever an enzyme changes phase. Step uses it to stop at the next event.
var event_serial: int = 0
var enzymes: Array[Enzyme] = []
var particles: Array[Particle] = []


# === PRIVATE VARIABLES ===
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_id: int = 0
var _accumulator: float = 0.0


# === PUBLIC METHODS ===
## Starts a fresh run. `enzyme_n` is lactase on the lining; `supplement_n` is extra lactase in the
## gut contents (the optional supplement). Values are clamped to the model's limits.
func setup(lactose: int, enzyme_n: int, run_seed: int = 1, supplement_n: int = 0) -> void:
	rng_seed = run_seed
	_rng.seed = run_seed
	lactose_start = clampi(lactose, 0, MAX_LACTOSE)
	enzyme_count = clampi(enzyme_n, 0, MAX_ENZYMES)
	supplement_count = clampi(supplement_n, 0, MAX_SUPPLEMENT)
	lactose_remaining = lactose_start
	cleaved = 0
	glucose_formed = 0
	galactose_formed = 0
	glucose_absorbed = 0
	galactose_absorbed = 0
	lactose_absorbed = 0
	tick_count = 0
	finished = false
	event_serial = 0
	_next_id = 0
	_accumulator = 0.0
	enzymes.clear()
	particles.clear()
	# Lactose first, so the same seed always gives the same starting picture whatever the enzymes.
	for i: int in range(lactose_start):
		var p: Particle = Particle.new()
		p.id = _take_id()
		p.kind = Kind.LACTOSE
		p.pos = Vector2(_rng.randf_range(0.04, 0.96), _rng.randf_range(LUMEN_TOP, LUMEN_BOTTOM))
		p.home = p.pos
		p.angle = _rng.randf_range(-0.6, 0.6)
		var heading: float = _rng.randf_range(0.0, TAU)
		p.vel = Vector2.from_angle(heading) * _rng.randf_range(0.02, 0.05)
		particles.append(p)
	var total: int = enzyme_count + supplement_count
	for i: int in range(total):
		var e: Enzyme = Enzyme.new()
		e.id = i
		e.supplement = i >= enzyme_count
		e.pos = _enzyme_position(i)
		e.delay = (i * 11) % CYCLE_TICKS
		enzymes.append(e)
	if lactose_start == 0:
		finished = true


## Adds real time and runs as many whole ticks as fit. Returns the number of ticks run.
func advance(delta: float) -> int:
	_accumulator += delta
	var ran: int = 0
	while _accumulator >= TICK and not finished and ran < 240:
		_accumulator -= TICK
		tick()
		ran += 1
	if finished:
		_accumulator = 0.0
	return ran


## Runs until the next enzyme event (bind, cleave or release), or one second if nothing happens.
func step_event() -> void:
	var start: int = event_serial
	var guard: int = 0
	while not finished and event_serial == start and guard < 30:
		tick()
		guard += 1


## Runs to the end of the period without drawing. For tests and comparisons.
func run_to_end() -> void:
	while not finished:
		tick()


## One fixed step of model time.
func tick() -> void:
	if finished:
		return
	tick_count += 1
	for e: Enzyme in enzymes:
		_tick_enzyme(e)
	_tick_particles()
	if tick_count >= PERIOD_TICKS:
		finished = true
	elif lactose_remaining == 0 and glucose_absorbed == glucose_formed and galactose_absorbed == galactose_formed:
		finished = true


func time_seconds() -> float:
	return float(tick_count) * TICK


func period_seconds() -> float:
	return float(PERIOD_TICKS) * TICK


func total_enzymes() -> int:
	return enzymes.size()


func count_particles(kind: int) -> int:
	var n: int = 0
	for p: Particle in particles:
		if p.kind == kind:
			n += 1
	return n


func find_particle(id: int) -> Particle:
	for p: Particle in particles:
		if p.id == id:
			return p
	return null


## Returns "" when every count adds up, or a description of the first rule that is broken.
func check_invariants() -> String:
	if lactose_remaining + cleaved != lactose_start:
		return "lactose remaining + cleaved != starting lactose"
	if glucose_formed != cleaved or galactose_formed != cleaved:
		return "products formed do not equal cleavages"
	if count_particles(Kind.LACTOSE) != lactose_remaining:
		return "lactose particles do not match the counter"
	if count_particles(Kind.GLUCOSE) != glucose_formed - glucose_absorbed:
		return "glucose particles do not match the counters"
	if count_particles(Kind.GALACTOSE) != galactose_formed - galactose_absorbed:
		return "galactose particles do not match the counters"
	if enzymes.size() != enzyme_count + supplement_count:
		return "an enzyme was created or destroyed"
	if lactose_absorbed != 0:
		return "intact lactose was absorbed"
	var turnovers: int = 0
	for e: Enzyme in enzymes:
		turnovers += e.turnovers
	if turnovers != cleaved:
		return "enzyme turnovers do not equal cleavages"
	return ""


## A short record of the whole state, for comparing two runs in tests.
func digest() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("%d|%d|%d|%d|%d|%d" % [tick_count, lactose_remaining, cleaved, glucose_absorbed,
		galactose_absorbed, event_serial])
	for p: Particle in particles:
		parts.append("%d:%d:%d:%.5f:%.5f" % [p.id, p.kind, p.state, p.pos.x, p.pos.y])
	for e: Enzyme in enzymes:
		parts.append("e%d:%d:%d:%d" % [e.id, e.state, e.timer, e.turnovers])
	return "/".join(parts)


## Plain numbers for the "What changed?" summary.
func summary() -> Dictionary:
	return {
		"lactose_start": lactose_start,
		"lactose_left": lactose_remaining,
		"cleaved": cleaved,
		"glucose": glucose_formed,
		"galactose": galactose_formed,
		"enzymes_start": enzyme_count + supplement_count,
		"enzymes_now": enzymes.size(),
		"seconds": time_seconds(),
		"finished": finished,
	}


## Where the lactose sits while an enzyme holds it (the active-site pocket).
static func pocket_of(e: Enzyme) -> Vector2:
	return e.pos + Vector2(0.0, -0.045)


# === PRIVATE METHODS ===
func _take_id() -> int:
	_next_id += 1
	return _next_id


## Lining enzymes sit in one or two staggered rows on the brush border; supplement enzymes float
## in the gut contents.
func _enzyme_position(index: int) -> Vector2:
	if index >= enzyme_count:
		var j: int = index - enzyme_count
		var x: float = (float(j) + 0.5) / float(maxi(supplement_count, 1))
		return Vector2(lerpf(0.06, 0.94, x), 0.66 if j % 2 == 0 else 0.6)
	var per_row: int = enzyme_count if enzyme_count <= 10 else int(ceil(float(enzyme_count) / 2.0))
	var row: int = 0 if index < per_row else 1
	var column: int = index if row == 0 else index - per_row
	var in_row: int = per_row if row == 0 else enzyme_count - per_row
	var fx: float = (float(column) + 0.5) / float(maxi(in_row, 1))
	if row == 1:
		return Vector2(lerpf(0.05, 0.95, fx), 0.78)
	return Vector2(lerpf(0.05, 0.95, fx), 0.92)


func _tick_enzyme(e: Enzyme) -> void:
	match e.state:
		EnzymeState.FREE:
			if e.delay > 0:
				e.delay -= 1
				return
			var target: Particle = _nearest_free_lactose(e.pos)
			if target == null:
				return
			target.state = ParticleState.CLAIMED
			target.enzyme = e.id
			target.from = target.pos
			target.to = pocket_of(e)
			target.timer = 0
			e.target = target.id
			e.state = EnzymeState.BINDING
			e.timer = 0
			event_serial += 1
		EnzymeState.BINDING:
			e.timer += 1
			if e.timer >= BIND_TICKS:
				var held: Particle = find_particle(e.target)
				held.state = ParticleState.BOUND
				held.pos = pocket_of(e)
				held.timer = 0
				e.state = EnzymeState.CLEAVING
				e.timer = 0
				event_serial += 1
		EnzymeState.CLEAVING:
			e.timer += 1
			if e.timer >= CLEAVE_TICKS:
				_cleave(e)
				e.state = EnzymeState.RESETTING
				e.timer = 0
				event_serial += 1
		EnzymeState.RESETTING:
			e.timer += 1
			if e.timer >= RESET_TICKS:
				e.state = EnzymeState.FREE
				e.timer = 0
				event_serial += 1


## The one place where chemistry happens: one lactose out, one glucose and one galactose in.
func _cleave(e: Enzyme) -> void:
	var held: Particle = find_particle(e.target)
	var at: Vector2 = held.pos
	particles.erase(held)
	lactose_remaining -= 1
	cleaved += 1
	e.turnovers += 1
	e.target = -1
	_spawn_product(Kind.GLUCOSE, at + Vector2(-0.012, 0.0), Vector2(-0.05, -0.06))
	glucose_formed += 1
	_spawn_product(Kind.GALACTOSE, at + Vector2(0.012, 0.0), Vector2(0.05, -0.06))
	galactose_formed += 1


func _spawn_product(kind: int, at: Vector2, vel: Vector2) -> void:
	var p: Particle = Particle.new()
	p.id = _take_id()
	p.kind = kind
	p.state = ParticleState.DRIFTING
	p.pos = at
	p.home = at + vel * 0.6
	p.vel = vel
	p.timer = 0
	particles.append(p)


func _nearest_free_lactose(from: Vector2) -> Particle:
	var best: Particle = null
	var best_d: float = INF
	for p: Particle in particles:
		if p.kind != Kind.LACTOSE or p.state != ParticleState.FREE:
			continue
		var d: float = p.pos.distance_squared_to(from)
		if d < best_d:
			best_d = d
			best = p
	return best


func _tick_particles() -> void:
	var absorbed: Array[Particle] = []
	for p: Particle in particles:
		match p.state:
			ParticleState.FREE:
				p.pos += p.vel * TICK
				if p.pos.x < 0.03 or p.pos.x > 0.97:
					p.vel.x = -p.vel.x
					p.pos.x = clampf(p.pos.x, 0.03, 0.97)
				if p.pos.y < LUMEN_TOP or p.pos.y > LUMEN_BOTTOM:
					p.vel.y = -p.vel.y
					p.pos.y = clampf(p.pos.y, LUMEN_TOP, LUMEN_BOTTOM)
			ParticleState.CLAIMED:
				p.timer += 1
				var t: float = clampf(float(p.timer) / float(BIND_TICKS), 0.0, 1.0)
				p.pos = p.from.lerp(p.to, smoothstep(0.0, 1.0, t))
				p.angle = lerpf(p.angle, 0.0, 0.2)
			ParticleState.BOUND:
				p.timer += 1
			ParticleState.DRIFTING:
				p.timer += 1
				p.pos += p.vel * TICK
				p.pos.x = clampf(p.pos.x, 0.02, 0.98)
				if p.timer >= PRODUCT_DRIFT_TICKS:
					p.state = ParticleState.ABSORBING
					p.timer = 0
					p.from = p.pos
					p.to = Vector2(p.pos.x, BORDER_Y + 0.06)
			ParticleState.ABSORBING:
				p.timer += 1
				var u: float = clampf(float(p.timer) / float(PRODUCT_ABSORB_TICKS), 0.0, 1.0)
				p.pos = p.from.lerp(p.to, u)
				if p.timer >= PRODUCT_ABSORB_TICKS:
					absorbed.append(p)
	for p: Particle in absorbed:
		# Only single sugars ever reach this state; lactose has no path to it.
		if p.kind == Kind.GLUCOSE:
			glucose_absorbed += 1
		elif p.kind == Kind.GALACTOSE:
			galactose_absorbed += 1
		particles.erase(p)
