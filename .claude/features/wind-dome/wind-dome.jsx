import { useState, useEffect, useRef } from "react";
import * as THREE from "three";

function generateWindField(hoursAhead) {
  const t = hoursAhead / 72;
  const baseDirection = (60 + hoursAhead * 3.8) % 360;
  const baseDeg = (baseDirection * Math.PI) / 180;
  return [
    { altitude: 10,   label: "10 m",   speed: 3.2 + Math.sin(t * Math.PI * 2) * 1.5,       dirRad: baseDeg + 0.00 },
    { altitude: 80,   label: "80 m",   speed: 5.8 + Math.cos(t * Math.PI * 1.5) * 2.0,     dirRad: baseDeg + 0.12 },
    { altitude: 300,  label: "300 m",  speed: 8.1 + Math.sin(t * Math.PI * 2.5 + 1) * 2.5, dirRad: baseDeg + 0.30 },
    { altitude: 800,  label: "800 m",  speed: 12.4 + Math.cos(t * Math.PI * 3) * 3.0,       dirRad: baseDeg + 0.55 },
    { altitude: 1500, label: "1500 m", speed: 18.0 + Math.sin(t * Math.PI * 2 + 2) * 4.0,   dirRad: baseDeg + 0.90 },
  ];
}

function sampleWindAtHeight(layers, y, domeHeight) {
  const normY = Math.max(0, Math.min(1, y / domeHeight));
  const idx = normY * (layers.length - 1);
  const lo = Math.floor(idx);
  const hi = Math.min(lo + 1, layers.length - 1);
  const frac = idx - lo;
  const speed = layers[lo].speed * (1 - frac) + layers[hi].speed * frac;
  const dir   = layers[lo].dirRad * (1 - frac) + layers[hi].dirRad * frac;
  return { vx: Math.cos(dir) * speed * 0.012, vz: Math.sin(dir) * speed * 0.012 };
}

// Check if point is inside the dome (ellipsoid)
function isInsideDome(x, y, z, R, H) {
  return (x * x + z * z) / (R * R) + (y * y) / (H * H) <= 1.0;
}

function createScene(canvas, windLayers) {
  const DOME_R = 18;  // wider radius
  const DOME_H = 14;  // half-ellipsoid height
  const PARTICLE_COUNT = 2000;
  const TRAIL_LENGTH = 10;

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(canvas.clientWidth, canvas.clientHeight);
  renderer.setClearColor(0x000000, 1);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(48, canvas.clientWidth / canvas.clientHeight, 0.1, 1000);

  // Camera: angled down like looking at a map
  let phi = Math.PI / 2.8, theta = Math.PI / 6;
  let isDragging = false, lastX = 0, lastY = 0;
  const CAM_R = DOME_R * 2.8;

  function updateCamera() {
    camera.position.set(
      CAM_R * Math.sin(phi) * Math.sin(theta),
      CAM_R * Math.cos(phi),
      CAM_R * Math.sin(phi) * Math.cos(theta)
    );
    camera.lookAt(0, DOME_H * 0.2, 0);
  }
  updateCamera();

  const onMouseDown = e => { isDragging = true; lastX = e.clientX; lastY = e.clientY; canvas.style.cursor = "grabbing"; };
  const onMouseUp   = () => { isDragging = false; canvas.style.cursor = "grab"; };
  const onMouseMove = e => {
    if (!isDragging) return;
    theta -= (e.clientX - lastX) * 0.007;
    phi    = Math.max(0.15, Math.min(Math.PI * 0.46, phi - (e.clientY - lastY) * 0.005));
    lastX = e.clientX; lastY = e.clientY;
    updateCamera();
  };
  const onTouchStart = e => { if (e.touches.length === 1) { isDragging = true; lastX = e.touches[0].clientX; lastY = e.touches[0].clientY; } };
  const onTouchEnd   = () => { isDragging = false; };
  const onTouchMove  = e => {
    if (!isDragging || e.touches.length !== 1) return;
    theta -= (e.touches[0].clientX - lastX) * 0.007;
    phi    = Math.max(0.15, Math.min(Math.PI * 0.46, phi - (e.touches[0].clientY - lastY) * 0.005));
    lastX = e.touches[0].clientX; lastY = e.touches[0].clientY;
    updateCamera();
  };

  canvas.addEventListener("mousedown", onMouseDown);
  window.addEventListener("mouseup", onMouseUp);
  window.addEventListener("mousemove", onMouseMove);
  canvas.addEventListener("touchstart", onTouchStart, { passive: true });
  canvas.addEventListener("touchend", onTouchEnd);
  canvas.addEventListener("touchmove", onTouchMove, { passive: true });

  // ── MAP GROUND PLANE ──────────────────────────────────────────────────────
  // Dark base extending beyond dome
  const mapGeo = new THREE.PlaneGeometry(DOME_R * 5, DOME_R * 5, 24, 24);
  const mapMat = new THREE.MeshBasicMaterial({ color: 0x0d0d0d, side: THREE.DoubleSide });
  const mapMesh = new THREE.Mesh(mapGeo, mapMat);
  mapMesh.rotation.x = -Math.PI / 2;
  mapMesh.position.y = -0.01;
  scene.add(mapMesh);

  // Grid lines simulating map streets
  const gridHelper = new THREE.GridHelper(DOME_R * 5, 30, 0x1a1a1a, 0x141414);
  gridHelper.position.y = 0.01;
  scene.add(gridHelper);

  // Road-like lines (thicker, brighter grid at block intervals)
  for (let i = -4; i <= 4; i++) {
    const spacing = DOME_R * 0.7;
    // horizontal
    const hPts = [new THREE.Vector3(-DOME_R * 3.5, 0.02, i * spacing), new THREE.Vector3(DOME_R * 3.5, 0.02, i * spacing)];
    scene.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(hPts), new THREE.LineBasicMaterial({ color: 0x1f1f1f, transparent: true, opacity: 0.8 })));
    // vertical
    const vPts = [new THREE.Vector3(i * spacing, 0.02, -DOME_R * 3.5), new THREE.Vector3(i * spacing, 0.02, DOME_R * 3.5)];
    scene.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(vPts), new THREE.LineBasicMaterial({ color: 0x1f1f1f, transparent: true, opacity: 0.8 })));
  }

  // Dome footprint circle on the ground
  {
    const pts = [];
    for (let i = 0; i <= 128; i++) {
      const a = (i / 128) * Math.PI * 2;
      pts.push(new THREE.Vector3(Math.cos(a) * DOME_R, 0.03, Math.sin(a) * DOME_R));
    }
    scene.add(new THREE.Line(
      new THREE.BufferGeometry().setFromPoints(pts),
      new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.5 })
    ));
  }

  // Filled dome footprint (slightly tinted ground inside dome)
  const footGeo = new THREE.CircleGeometry(DOME_R, 64);
  const footMat = new THREE.MeshBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.5, side: THREE.DoubleSide });
  const footMesh = new THREE.Mesh(footGeo, footMat);
  footMesh.rotation.x = -Math.PI / 2;
  footMesh.position.y = 0.02;
  scene.add(footMesh);

  // ── USER POSITION MARKER ─────────────────────────────────────────────────
  // Outer pulsing ring
  const markerRingGeo = new THREE.RingGeometry(1.1, 1.5, 48);
  const markerRingMat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.9, side: THREE.DoubleSide });
  const markerRing = new THREE.Mesh(markerRingGeo, markerRingMat);
  markerRing.rotation.x = -Math.PI / 2;
  markerRing.position.y = 0.05;
  scene.add(markerRing);

  // Inner filled dot
  const markerDotGeo = new THREE.CircleGeometry(0.7, 32);
  const markerDotMat = new THREE.MeshBasicMaterial({ color: 0xffffff, side: THREE.DoubleSide });
  const markerDot = new THREE.Mesh(markerDotGeo, markerDotMat);
  markerDot.rotation.x = -Math.PI / 2;
  markerDot.position.y = 0.06;
  scene.add(markerDot);

  // Second outer ring (accuracy halo)
  const haloGeo = new THREE.RingGeometry(2.5, 2.8, 64);
  const haloMat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.2, side: THREE.DoubleSide });
  const halo = new THREE.Mesh(haloGeo, haloMat);
  halo.rotation.x = -Math.PI / 2;
  halo.position.y = 0.04;
  scene.add(halo);

  // Vertical axis line from user position up
  {
    const axisPts = [new THREE.Vector3(0, 0.1, 0), new THREE.Vector3(0, DOME_H * 0.95, 0)];
    scene.add(new THREE.Line(
      new THREE.BufferGeometry().setFromPoints(axisPts),
      new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.08 })
    ));
  }

  // ── DOME WIREFRAME (half ellipsoid) ───────────────────────────────────────
  // Latitude rings
  const DOME_SEGS_LAT = 8;
  for (let li = 1; li <= DOME_SEGS_LAT; li++) {
    const normY = li / DOME_SEGS_LAT;
    const y = normY * DOME_H;
    const r = DOME_R * Math.sqrt(Math.max(0, 1 - normY * normY));
    if (r < 0.5) continue;
    const pts = [];
    for (let i = 0; i <= 80; i++) {
      const a = (i / 80) * Math.PI * 2;
      pts.push(new THREE.Vector3(Math.cos(a) * r, y, Math.sin(a) * r));
    }
    const opacity = li === DOME_SEGS_LAT ? 0.0 : 0.06 + (1 - normY) * 0.04;
    scene.add(new THREE.Line(
      new THREE.BufferGeometry().setFromPoints(pts),
      new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity })
    ));
  }

  // Longitude lines (meridians)
  const DOME_SEGS_LON = 16;
  for (let li = 0; li < DOME_SEGS_LON; li++) {
    const a = (li / DOME_SEGS_LON) * Math.PI * 2;
    const pts = [];
    for (let j = 0; j <= 32; j++) {
      const normY = j / 32;
      const r = DOME_R * Math.sqrt(Math.max(0, 1 - normY * normY));
      pts.push(new THREE.Vector3(Math.cos(a) * r, normY * DOME_H, Math.sin(a) * r));
    }
    scene.add(new THREE.Line(
      new THREE.BufferGeometry().setFromPoints(pts),
      new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.05 })
    ));
  }

  // ── WIND STREAK PARTICLES ─────────────────────────────────────────────────
  const TOTAL_VERTS = PARTICLE_COUNT * TRAIL_LENGTH * 2;
  const streakPositions = new Float32Array(TOTAL_VERTS * 3);
  const streakColors    = new Float32Array(TOTAL_VERTS * 3);
  const streakGeo = new THREE.BufferGeometry();
  streakGeo.setAttribute("position", new THREE.BufferAttribute(streakPositions, 3));
  streakGeo.setAttribute("color",    new THREE.BufferAttribute(streakColors,    3));
  scene.add(new THREE.LineSegments(streakGeo, new THREE.LineBasicMaterial({ vertexColors: true, transparent: true, opacity: 1 })));

  // Random point inside the dome (half-ellipsoid y >= 0)
  function randomInDome() {
    for (let attempt = 0; attempt < 400; attempt++) {
      const x = (Math.random() * 2 - 1) * DOME_R;
      const y = Math.random() * DOME_H;
      const z = (Math.random() * 2 - 1) * DOME_R;
      if (isInsideDome(x, y, z, DOME_R, DOME_H)) return { x, y, z };
    }
    return { x: 0, y: DOME_H * 0.3, z: 0 };
  }

  const pState = Array.from({ length: PARTICLE_COUNT }, () => {
    const p = randomInDome();
    return { x: p.x, y: p.y, z: p.z, history: Array(TRAIL_LENGTH + 1).fill(null).map(() => ({ ...p })) };
  });

  let currentLayers = windLayers;
  let frameId;
  let time = 0;

  function animate() {
    frameId = requestAnimationFrame(animate);
    time += 0.016;

    // Pulse the user marker rings
    markerRing.material.opacity = 0.6 + Math.sin(time * 2.5) * 0.3;
    halo.material.opacity = 0.08 + Math.sin(time * 1.8 + 1) * 0.06;

    const pos = streakGeo.attributes.position.array;
    const col = streakGeo.attributes.color.array;

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      const p = pState[i];
      const w = sampleWindAtHeight(currentLayers, p.y, DOME_H);
      p.x += w.vx;
      p.z += w.vz;
      p.y += 0.002 + (p.y / DOME_H) * 0.003;

      // Strict dome containment
      if (!isInsideDome(p.x, p.y, p.z, DOME_R * 1.02, DOME_H * 1.02) || p.y < 0) {
        const np = randomInDome();
        p.x = np.x; p.y = np.y; p.z = np.z;
        for (let t = 0; t <= TRAIL_LENGTH; t++) p.history[t] = { x: p.x, y: p.y, z: p.z };
      }

      p.history.unshift({ x: p.x, y: p.y, z: p.z });
      if (p.history.length > TRAIL_LENGTH + 1) p.history.pop();

      const spd = Math.sqrt(w.vx * w.vx + w.vz * w.vz);
      const speedNorm = Math.min(spd / 0.22, 1);

      for (let seg = 0; seg < TRAIL_LENGTH; seg++) {
        const h0 = p.history[seg]     || p.history[0];
        const h1 = p.history[seg + 1] || h0;
        const vi = (i * TRAIL_LENGTH + seg) * 2;

        pos[vi * 3]         = h0.x; pos[vi * 3 + 1]     = h0.y; pos[vi * 3 + 2]     = h0.z;
        pos[(vi+1) * 3]     = h1.x; pos[(vi+1) * 3 + 1] = h1.y; pos[(vi+1) * 3 + 2] = h1.z;

        const altBright  = 0.4 + (h0.y / DOME_H) * 0.6;
        const trailFade  = 1.0 - (seg / TRAIL_LENGTH) * 0.93;
        const b0 = trailFade * altBright * (0.5 + speedNorm * 0.5);
        const b1 = Math.max(0, b0 - 0.1);

        col[vi * 3] = b0; col[vi * 3 + 1] = b0; col[vi * 3 + 2] = b0;
        col[(vi+1) * 3] = b1; col[(vi+1) * 3 + 1] = b1; col[(vi+1) * 3 + 2] = b1;
      }
    }

    streakGeo.attributes.position.needsUpdate = true;
    streakGeo.attributes.color.needsUpdate    = true;
    renderer.render(scene, camera);
  }

  animate();

  return {
    updateLayers(layers) { currentLayers = layers; },
    resize() {
      renderer.setSize(canvas.clientWidth, canvas.clientHeight);
      camera.aspect = canvas.clientWidth / canvas.clientHeight;
      camera.updateProjectionMatrix();
    },
    destroy() {
      cancelAnimationFrame(frameId);
      canvas.removeEventListener("mousedown", onMouseDown);
      window.removeEventListener("mouseup", onMouseUp);
      window.removeEventListener("mousemove", onMouseMove);
      canvas.removeEventListener("touchstart", onTouchStart);
      canvas.removeEventListener("touchend", onTouchEnd);
      canvas.removeEventListener("touchmove", onTouchMove);
      renderer.dispose();
    },
  };
}

function formatHour(h) {
  if (h === 0) return "Now";
  const d = Math.floor(h / 24), hr = h % 24;
  if (d > 0 && hr === 0) return `+${d}d`;
  if (d > 0) return `+${d}d ${hr}h`;
  return `+${h}h`;
}

const HOURS = 72;

export default function WindDome() {
  const canvasRef = useRef(null);
  const sceneRef  = useRef(null);
  const [hours, setHours] = useState(0);
  const [hintVisible, setHintVisible] = useState(true);
  const windLayers = generateWindField(hours);

  useEffect(() => {
    if (!canvasRef.current) return;
    const s = createScene(canvasRef.current, windLayers);
    sceneRef.current = s;
    const ro = new ResizeObserver(() => s.resize());
    ro.observe(canvasRef.current);
    const t = setTimeout(() => setHintVisible(false), 4000);
    return () => { s.destroy(); ro.disconnect(); clearTimeout(t); };
  }, []);

  useEffect(() => { sceneRef.current?.updateLayers(windLayers); }, [hours]);

  const windDir    = ((windLayers[0].dirRad * 180) / Math.PI + 360) % 360;
  const compassDir = ["N","NE","E","SE","S","SW","W","NW"][Math.round(windDir / 45) % 8];
  const forecastDate = new Date(Date.now() + hours * 3600000);
  const dateStr = hours === 0 ? "" : forecastDate.toLocaleString("en-US", { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });

  return (
    <div style={{
      width: "100%", height: "100vh",
      background: "#000",
      fontFamily: "'Courier New', monospace",
      display: "flex", flexDirection: "column",
      overflow: "hidden", color: "#fff",
      userSelect: "none",
    }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 18px", borderBottom: "1px solid rgba(255,255,255,0.07)" }}>
        <div>
          <div style={{ fontSize: 9, letterSpacing: "0.35em", color: "rgba(255,255,255,0.25)", textTransform: "uppercase" }}>Wind Lens</div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase" }}>Wind Dome</div>
        </div>
        <div style={{ display: "flex", gap: 18, alignItems: "center" }}>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", letterSpacing: "0.15em", marginBottom: 1 }}>SURFACE</div>
            <div style={{ fontSize: 14, fontWeight: 700 }}>{windLayers[0].speed.toFixed(1)}<span style={{ fontSize: 9, fontWeight: 400, color: "rgba(255,255,255,0.4)", marginLeft: 3 }}>m/s</span></div>
            <div style={{ fontSize: 9, color: "rgba(255,255,255,0.35)" }}>{windDir.toFixed(0)}° {compassDir}</div>
          </div>
          <div style={{
            padding: "4px 10px",
            border: `1px solid ${hours === 0 ? "rgba(255,255,255,0.4)" : "rgba(255,255,255,0.18)"}`,
            fontSize: 8, letterSpacing: "0.25em", textTransform: "uppercase",
            color: hours === 0 ? "#fff" : "rgba(255,255,255,0.4)",
          }}>
            {hours === 0 ? "● Live" : "▶ Fcst"}
          </div>
        </div>
      </div>

      {/* Altitude bars */}
      <div style={{ display: "flex", borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
        {windLayers.map((l, i) => (
          <div key={l.label} style={{ flex: 1, padding: "5px 10px", borderRight: i < windLayers.length - 1 ? "1px solid rgba(255,255,255,0.04)" : "none" }}>
            <div style={{ fontSize: 8, color: "rgba(255,255,255,0.22)", letterSpacing: "0.08em", marginBottom: 3 }}>{l.label}</div>
            <div style={{ height: 1, background: "rgba(255,255,255,0.07)", marginBottom: 3 }}>
              <div style={{ width: `${Math.min(l.speed / 22, 1) * 100}%`, height: "100%", background: "rgba(255,255,255,0.65)", transition: "width 0.4s" }} />
            </div>
            <div style={{ fontSize: 8, color: "rgba(255,255,255,0.5)" }}>{l.speed.toFixed(1)}</div>
          </div>
        ))}
      </div>

      {/* Canvas */}
      <div style={{ position: "relative", flex: 1 }}>
        <canvas ref={canvasRef} style={{ width: "100%", height: "100%", display: "block", cursor: "grab" }} />
        {hintVisible && (
          <div style={{
            position: "absolute", bottom: 14, left: "50%", transform: "translateX(-50%)",
            fontSize: 9, letterSpacing: "0.22em", color: "rgba(255,255,255,0.18)",
            textTransform: "uppercase", pointerEvents: "none",
          }}>
            drag to rotate
          </div>
        )}
      </div>

      {/* Forecast slider */}
      <div style={{ borderTop: "1px solid rgba(255,255,255,0.07)", padding: "11px 18px 15px", background: "#000" }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
          {[0, 12, 24, 36, 48, 60, 72].map(h => (
            <span key={h} style={{
              fontSize: 8, letterSpacing: "0.08em", textTransform: "uppercase",
              color: h === hours ? "#fff" : "rgba(255,255,255,0.18)",
              transition: "color 0.2s",
            }}>
              {h === 0 ? "now" : `+${h}h`}
            </span>
          ))}
        </div>

        <input
          type="range" min={0} max={HOURS} step={1} value={hours}
          onChange={e => setHours(Number(e.target.value))}
          style={{ width: "100%", appearance: "none", WebkitAppearance: "none", background: "transparent", cursor: "pointer", display: "block" }}
        />

        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 7, alignItems: "center" }}>
          <span style={{ fontSize: 8, color: "rgba(255,255,255,0.18)", letterSpacing: "0.1em" }}>47.2°N 96.8°W</span>
          <span style={{ fontSize: 10, color: hours === 0 ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.4)", letterSpacing: "0.05em" }}>
            {hours === 0 ? "Live" : `${formatHour(hours)} — ${dateStr}`}
          </span>
          <span style={{ fontSize: 8, color: "rgba(255,255,255,0.18)", letterSpacing: "0.1em" }}>72 hr</span>
        </div>
      </div>

      <style>{`
        input[type=range]::-webkit-slider-runnable-track { height:1px; background:rgba(255,255,255,0.15); }
        input[type=range]::-webkit-slider-thumb {
          -webkit-appearance:none; width:12px; height:12px; border-radius:50%;
          background:#fff; margin-top:-5.5px;
          box-shadow: 0 0 5px rgba(255,255,255,0.3);
          transition: transform 0.1s;
        }
        input[type=range]:active::-webkit-slider-thumb { transform:scale(1.5); }
        input[type=range]::-moz-range-track { height:1px; background:rgba(255,255,255,0.15); }
        input[type=range]::-moz-range-thumb { width:12px; height:12px; border-radius:50%; background:#fff; border:none; }
      `}</style>
    </div>
  );
}
