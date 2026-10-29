/*
 * AeroPulse: Horizon Drift — 3D scene, vehicle physics and race logic.
 *
 * Rendering: Three.js. Physics: Cannon.js RaycastVehicle (raycast suspension,
 * separate longitudinal / lateral tyre friction — that is what makes the
 * drifting behave).
 *
 * Flutter -> JS (runJavaScript):
 *   window.__AP.setup(carCfg, trackId, {opponents: 5})
 *   window.__AP.setInput({throttle, brake, steer, handbrake})
 *   window.__AP.start() / pause() / resume() / restart() / setLaps(n)
 *
 * JS -> Flutter (JavaScriptChannel "AeroPulse"):
 *   {type:'ready'} {type:'loaded'} {type:'countdown', value}
 *   {type:'track', path, min, max}
 *   {type:'hud', speed, gear, rpm, lap, laps, lapTime, bestLap, drifting,
 *                pos, total, x, z}
 *   {type:'checkpoint'} {type:'lap'} {type:'finished'} {type:'error'}
 */
(function () {
  'use strict';

  var CHANNEL = 'AeroPulse';
  var LAPS = 3;
  var FIXED_STEP = 1 / 60;
  var ENGINE_SCALE = 3.4;
  var GATE_FRACTIONS = [0, 0.25, 0.5, 0.75];
  var CP_ORDER = [1, 2, 3, 0];
  var CP_RADIUS2 = 13 * 13;

  /* ------------------------------------------------------------------ *
   * Bridge
   * ------------------------------------------------------------------ */
  function post(type, data) {
    var msg = data ? JSON.parse(JSON.stringify(data)) : {};
    msg.type = type;
    try {
      if (window[CHANNEL] && window[CHANNEL].postMessage) {
        window[CHANNEL].postMessage(JSON.stringify(msg));
      }
    } catch (e) { /* channel not attached yet */ }
  }

  window.onerror = function (message) {
    post('error', { message: String(message) });
  };

  /* ------------------------------------------------------------------ *
   * Tuning tables
   * ------------------------------------------------------------------ */
  var THEMES = {
    neon_city: {
      skyTop: 0x03050b, skyHorizon: 0x142440,
      fog: 0x0a1220, fogDensity: 0.0030,
      groundTex: 'asphalt', groundColor: 0x0b0f17,
      roadColor: 0x1a2130, lineColor: 0x2fe4ff,
      rail: 'neon', railColor: 0x0f1826, railEmissive: 0x27d9ff,
      decor: 'city', env: 'neon', skyImage: false,
      sun: 0xbfd8ff, sunIntensity: 1.15, hemiSky: 0x8fd8ff, hemiGround: 0x0b1220,
      exposure: 1.05
    },
    canyon_dust: {
      skyTop: 0x2b4a72, skyHorizon: 0xf0b070,
      fog: 0xd7a26c, fogDensity: 0.0022,
      groundTex: 'sand', groundColor: 0x9a7448,
      roadColor: 0x6a5335, lineColor: 0xf4f0e2,
      rail: 'rail', railColor: 0x9aa0a6, railEmissive: 0x000000,
      decor: 'rocks', env: 'canyon', skyImage: true,
      sun: 0xffd9a0, sunIntensity: 1.7, hemiSky: 0xffe6c0, hemiGround: 0x6b4a2b,
      exposure: 1.0
    },
    alpine_pass: {
      skyTop: 0x2f6fb5, skyHorizon: 0xcfe6f5,
      fog: 0xcfe0ee, fogDensity: 0.0015,
      groundTex: 'grass', groundColor: 0x527c3c,
      roadColor: 0x4a4e55, lineColor: 0xf4f4f4,
      rail: 'rail', railColor: 0xb9c0c7, railEmissive: 0x000000,
      decor: 'forest', env: 'alpine', skyImage: true,
      sun: 0xfff2d8, sunIntensity: 1.9, hemiSky: 0xdfefff, hemiGround: 0x40603a,
      exposure: 1.0
    }
  };

  var LAYOUTS = {
    neon_city: { rx: 96, rz: 78, wob: 0.07, freq: 2, width: 15 },
    canyon_dust: { rx: 112, rz: 76, wob: 0.15, freq: 3, width: 16 },
    alpine_pass: { rx: 122, rz: 92, wob: 0.22, freq: 3, width: 13 }
  };

  var CAR_SHAPES = {
    vortex_gt: { half: [0.92, 0.26, 2.05], cabin: [0.70, 0.25, 0.92], cabinZ: -0.10, wing: true, wheelR: 0.36, roofY: 0.50 },
    titan_x: { half: [1.04, 0.32, 2.20], cabin: [0.84, 0.29, 1.02], cabinZ: -0.35, wing: true, wheelR: 0.41, roofY: 0.58 },
    apex_spider: { half: [0.95, 0.23, 2.12], cabin: [0.68, 0.21, 0.76], cabinZ: 0.10, wing: true, wheelR: 0.35, roofY: 0.44 },
    nomad_r1: { half: [0.98, 0.35, 2.15], cabin: [0.84, 0.35, 1.12], cabinZ: -0.30, wing: false, wheelR: 0.43, roofY: 0.66 }
  };

  var RIVAL_COLORS = [0xe63946, 0xf4a261, 0x9b5de5, 0x2a9d8f, 0xe9c46a, 0xef476f];

  /* ------------------------------------------------------------------ *
   * State
   * ------------------------------------------------------------------ */
  var state = {
    trackId: null,
    car: null,
    opponents: 5,
    phase: 'idle',
    countdown: 0,
    lastCountShown: -1,
    lap: 0,
    cpPtr: 0,
    lapStart: 0,
    bestLap: 0,
    raceStart: 0,
    drifting: 0,
    flipTimer: 0,
    reverseHold: 0,
    pos: 1,
    total: 1
  };

  var input = { throttle: 0, brake: 0, steer: 0, handbrake: 0 };

  /* ------------------------------------------------------------------ *
   * Renderer / scene / camera / lights
   * ------------------------------------------------------------------ */
  var renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
  if ('outputColorSpace' in renderer && THREE.SRGBColorSpace) {
    renderer.outputColorSpace = THREE.SRGBColorSpace;
  } else if ('outputEncoding' in renderer && THREE.sRGBEncoding) {
    renderer.outputEncoding = THREE.sRGBEncoding;
  }
  document.body.appendChild(renderer.domElement);

  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.2, 2200);
  camera.position.set(0, 8, -16);

  var hemi = new THREE.HemisphereLight(0xdfefff, 0x334422, 0.85);
  scene.add(hemi);

  var sun = new THREE.DirectionalLight(0xffffff, 1.6);
  sun.position.set(80, 140, 60);
  sun.castShadow = true;
  sun.shadow.mapSize.width = 2048;
  sun.shadow.mapSize.height = 2048;
  sun.shadow.camera.near = 20;
  sun.shadow.camera.far = 520;
  sun.shadow.camera.left = -150;
  sun.shadow.camera.right = 150;
  sun.shadow.camera.top = 150;
  sun.shadow.camera.bottom = -150;
  sun.shadow.bias = -0.0006;
  scene.add(sun);
  scene.add(sun.target);

  var ambient = new THREE.AmbientLight(0xffffff, 0.25);
  scene.add(ambient);

  /* sky dome — a cheap two-colour gradient, no external HDR needed */
  var skyMat = new THREE.ShaderMaterial({
    uniforms: {
      topColor: { value: new THREE.Color(0x2f6fb5) },
      bottomColor: { value: new THREE.Color(0xcfe6f5) },
      offset: { value: 0.12 },
      exponent: { value: 0.9 }
    },
    vertexShader: [
      'varying vec3 vWorld;',
      'void main() {',
      '  vec4 wp = modelMatrix * vec4(position, 1.0);',
      '  vWorld = wp.xyz;',
      '  gl_Position = projectionMatrix * viewMatrix * wp;',
      '}'
    ].join('\n'),
    fragmentShader: [
      'uniform vec3 topColor;',
      'uniform vec3 bottomColor;',
      'uniform float offset;',
      'uniform float exponent;',
      'varying vec3 vWorld;',
      'void main() {',
      '  float h = normalize(vWorld + vec3(0.0, offset, 0.0)).y;',
      '  float f = pow(max(h, 0.0), exponent);',
      '  gl_FragColor = vec4(mix(bottomColor, topColor, f), 1.0);',
      '}'
    ].join('\n'),
    side: THREE.BackSide,
    depthWrite: false,
    fog: false
  });
  var skyDome = new THREE.Mesh(new THREE.SphereGeometry(1400, 24, 16), skyMat);
  scene.add(skyDome);

  /* a soft environment map so metallic paint has something to reflect */
  var envTarget = null;
  function buildEnvironment() {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 128;
    var ctx = c.getContext('2d');
    var grad = ctx.createLinearGradient(0, 0, 0, 128);
    grad.addColorStop(0, '#9dc4e8');
    grad.addColorStop(0.48, '#e8eef5');
    grad.addColorStop(0.52, '#7c7f74');
    grad.addColorStop(1, '#3a3f34');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 256, 128);

    var tex = new THREE.CanvasTexture(c);
    tex.mapping = THREE.EquirectangularReflectionMapping;
    if ('encoding' in tex && THREE.sRGBEncoding) tex.encoding = THREE.sRGBEncoding;

    var pmrem = new THREE.PMREMGenerator(renderer);
    pmrem.compileEquirectangularShader();
    if (envTarget) envTarget.dispose();
    envTarget = pmrem.fromEquirectangular(tex);
    scene.environment = envTarget.texture;
    tex.dispose();
    pmrem.dispose();
  }
  buildEnvironment();

  /* Real sky + reflection probe per track. The images are embedded as data
     URIs (assets/game/env_data.js) so nothing has to be fetched over XHR,
     which a WebView blocks for file:// pages. */
  var envCache = {};
  var envToken = 0;

  function applyEnvironment(theme) {
    var id = theme.env;
    var token = ++envToken;

    function use(entry) {
      if (token !== envToken) return; // track changed while loading
      if (entry) {
        scene.environment = entry.envMap;
        scene.background = theme.skyImage ? entry.texture : null;
        skyDome.visible = !theme.skyImage;
        hemi.intensity = 0.35;
        ambient.intensity = theme.decor === 'city' ? 0.12 : 0.08;
      } else {
        scene.environment = envTarget ? envTarget.texture : null;
        scene.background = null;
        skyDome.visible = true;
        hemi.intensity = 0.85;
        ambient.intensity = theme.decor === 'city' ? 0.15 : 0.3;
      }
    }

    if (envCache[id]) {
      use(envCache[id]);
      return;
    }
    var dataUri = window.__AP_ENV && window.__AP_ENV[id];
    if (!dataUri) {
      use(null);
      return;
    }

    try {
      new THREE.TextureLoader().load(
        dataUri,
        function (tex) {
          try {
            tex.mapping = THREE.EquirectangularReflectionMapping;
            if ('encoding' in tex && THREE.sRGBEncoding) tex.encoding = THREE.sRGBEncoding;
            var pmrem = new THREE.PMREMGenerator(renderer);
            pmrem.compileEquirectangularShader();
            var rt = pmrem.fromEquirectangular(tex);
            pmrem.dispose();
            envCache[id] = { texture: tex, envMap: rt.texture };
            use(envCache[id]);
          } catch (err) {
            use(null);
          }
        },
        undefined,
        function () { use(null); }
      );
    } catch (err) {
      use(null);
    }
  }

  /* ------------------------------------------------------------------ *
   * Physics world
   * ------------------------------------------------------------------ */
  var world = new CANNON.World();
  world.gravity.set(0, -19.6, 0);
  world.broadphase = new CANNON.SAPBroadphase(world);
  world.solver.iterations = 12;
  world.solver.tolerance = 0.001;
  world.defaultContactMaterial.friction = 0.4;
  world.defaultContactMaterial.restitution = 0.02;

  /* ------------------------------------------------------------------ *
   * Procedural textures
   * ------------------------------------------------------------------ */
  function makeTexture(w, h, draw, repX, repY) {
    var c = document.createElement('canvas');
    c.width = w;
    c.height = h;
    draw(c.getContext('2d'), w, h);
    var t = new THREE.CanvasTexture(c);
    t.wrapS = THREE.RepeatWrapping;
    t.wrapT = THREE.RepeatWrapping;
    t.repeat.set(repX || 1, repY || 1);
    t.anisotropy = 4;
    if ('encoding' in t && THREE.sRGBEncoding) t.encoding = THREE.sRGBEncoding;
    return t;
  }

  function speckle(ctx, w, h, base, spots, spread, size) {
    ctx.fillStyle = base;
    ctx.fillRect(0, 0, w, h);
    for (var i = 0; i < spots; i++) {
      var v = Math.floor((Math.random() - 0.5) * spread);
      ctx.fillStyle = 'rgba(' + (128 + v) + ',' + (128 + v) + ',' + (128 + v) + ',0.10)';
      var s = size * (0.4 + Math.random());
      ctx.fillRect(Math.random() * w, Math.random() * h, s, s);
    }
  }

  var TEXTURES = {};
  function groundTexture(kind, color) {
    var key = kind + '_' + color;
    if (TEXTURES[key]) return TEXTURES[key];

    var tex;
    if (kind === 'grass') {
      tex = makeTexture(256, 256, function (ctx, w, h) {
        speckle(ctx, w, h, '#547f3d', 2600, 90, 3);
        for (var i = 0; i < 400; i++) {
          ctx.strokeStyle = 'rgba(90,140,60,0.35)';
          ctx.lineWidth = 1;
          var x = Math.random() * w;
          var y = Math.random() * h;
          ctx.beginPath();
          ctx.moveTo(x, y);
          ctx.lineTo(x + (Math.random() - 0.5) * 4, y - 3 - Math.random() * 4);
          ctx.stroke();
        }
      }, 90, 90);
    } else if (kind === 'sand') {
      tex = makeTexture(256, 256, function (ctx, w, h) {
        speckle(ctx, w, h, '#a67c4e', 3000, 70, 3);
        for (var i = 0; i < 120; i++) {
          ctx.fillStyle = 'rgba(140,110,70,0.25)';
          ctx.beginPath();
          ctx.ellipse(Math.random() * w, Math.random() * h, 8 + Math.random() * 20, 3 + Math.random() * 6, Math.random() * 3, 0, 6.283);
          ctx.fill();
        }
      }, 70, 70);
    } else {
      tex = makeTexture(256, 256, function (ctx, w, h) {
        speckle(ctx, w, h, '#1a1f2a', 2200, 60, 2);
      }, 90, 90);
    }
    TEXTURES[key] = tex;
    return tex;
  }

  var roadTexture = null;
  function getRoadTexture(color) {
    if (roadTexture) return roadTexture;
    roadTexture = makeTexture(256, 512, function (ctx, w, h) {
      speckle(ctx, w, h, '#4b4f56', 5000, 55, 2);
      for (var i = 0; i < 90; i++) {
        ctx.fillStyle = 'rgba(30,32,36,0.20)';
        ctx.beginPath();
        ctx.ellipse(Math.random() * w, Math.random() * h, 6 + Math.random() * 26, 4 + Math.random() * 14, Math.random() * 3, 0, 6.283);
        ctx.fill();
      }
    }, 1, 1);
    return roadTexture;
  }

  function buildingTexture() {
    return makeTexture(128, 256, function (ctx, w, h) {
      ctx.fillStyle = '#0d1420';
      ctx.fillRect(0, 0, w, h);
      for (var y = 6; y < h - 6; y += 12) {
        for (var x = 6; x < w - 6; x += 12) {
          var lit = Math.random();
          if (lit > 0.62) {
            ctx.fillStyle = lit > 0.9 ? 'rgba(255,225,170,0.95)' : 'rgba(120,190,255,0.75)';
            ctx.fillRect(x, y, 7, 7);
          }
        }
      }
    }, 2, 3);
  }

  /* ------------------------------------------------------------------ *
   * Track
   * ------------------------------------------------------------------ */
  var trackGroup = new THREE.Group();
  scene.add(trackGroup);

  var staticBodies = [];
  var checkpoints = [];
  var startPos = new THREE.Vector3();
  var startAngle = 0;
  var pathData = null;

  function disposeGroup(group) {
    group.traverse(function (o) {
      if (o.isMesh || o.isInstancedMesh) {
        if (o.geometry) o.geometry.dispose();
        if (Array.isArray(o.material)) {
          o.material.forEach(function (m) { m.dispose(); });
        } else if (o.material) {
          o.material.dispose();
        }
      }
    });
  }

  function removeBody(body) {
    if (world.removeBody) world.removeBody(body);
    else world.remove(body);
  }

  function clearTrack() {
    disposeGroup(trackGroup);
    scene.remove(trackGroup);
    trackGroup = new THREE.Group();
    scene.add(trackGroup);
    staticBodies.forEach(removeBody);
    staticBodies = [];
    checkpoints = [];
    pathData = null;
  }

  function buildPath(kind) {
    var layout = LAYOUTS[kind] || LAYOUTS.alpine_pass;
    var n = 72;
    var pts = [];

    for (var i = 0; i < n; i++) {
      var t = (i / n) * Math.PI * 2;
      var wob = layout.wob * Math.sin(layout.freq * t) + layout.wob * 0.4 * Math.cos(5 * t);
      pts.push(new THREE.Vector3(
        Math.cos(t) * layout.rx * (1 + wob),
        0,
        Math.sin(t) * layout.rz * (1 + wob * 0.7)
      ));
    }

    var cumulative = [0];
    var total = 0;
    for (var j = 1; j <= n; j++) {
      total += pts[j % n].distanceTo(pts[j - 1]);
      cumulative.push(total);
    }

    return { pts: pts, cumulative: cumulative, total: total, width: layout.width, n: n };
  }

  function samplePath(data, u) {
    var d = ((u % 1) + 1) % 1 * data.total;
    var i = 0;
    while (i < data.n - 1 && data.cumulative[i + 1] < d) i++;
    var segLen = data.cumulative[i + 1] - data.cumulative[i];
    var f = segLen > 0.0001 ? (d - data.cumulative[i]) / segLen : 0;
    var a = data.pts[i % data.n];
    var b = data.pts[(i + 1) % data.n];
    var pos = new THREE.Vector3().lerpVectors(a, b, f);
    var dir = new THREE.Vector3().subVectors(b, a).normalize();
    return { pos: pos, dir: dir };
  }

  function nearestOnPath(data, x, z) {
    var best = { dist: Infinity, along: 0, point: null };
    for (var i = 0; i < data.n; i++) {
      var a = data.pts[i];
      var b = data.pts[(i + 1) % data.n];
      var abx = b.x - a.x;
      var abz = b.z - a.z;
      var apx = x - a.x;
      var apz = z - a.z;
      var len2 = abx * abx + abz * abz;
      var t = len2 > 0 ? Math.max(0, Math.min(1, (apx * abx + apz * abz) / len2)) : 0;
      var px = a.x + abx * t;
      var pz = a.z + abz * t;
      var dx = x - px;
      var dz = z - pz;
      var dist = dx * dx + dz * dz;
      if (dist < best.dist) {
        best.dist = dist;
        best.along = data.cumulative[i] + Math.sqrt(len2) * t;
        best.point = new THREE.Vector3(px, 0, pz);
      }
    }
    return best;
  }

  function addGround(theme) {
    var tex = groundTexture(theme.groundTex, theme.groundColor);
    var geo = new THREE.PlaneGeometry(2600, 2600);
    var mat = new THREE.MeshStandardMaterial({
      map: tex,
      color: theme.groundColor,
      roughness: 0.95,
      metalness: 0.0
    });
    var mesh = new THREE.Mesh(geo, mat);
    mesh.rotation.x = -Math.PI / 2;
    mesh.receiveShadow = true;
    trackGroup.add(mesh);

    var body = new CANNON.Body({ mass: 0 });
    body.addShape(new CANNON.Plane());
    body.quaternion.setFromEuler(-Math.PI / 2, 0, 0);
    world.add(body);
    staticBodies.push(body);
  }

  /* road ribbon with UVs that follow the curve, plus painted markings */
  function addRoad(data, theme) {
    var n = data.n;
    var positions = [];
    var uvs = [];
    var indices = [];
    var half = data.width / 2;

    for (var i = 0; i < n; i++) {
      var p = data.pts[i];
      var next = data.pts[(i + 1) % n];
      var prev = data.pts[(i - 1 + n) % n];
      var dir = new THREE.Vector3().subVectors(next, prev).normalize();
      var side = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(half);
      var v = data.cumulative[i] / 8;

      positions.push(p.x + side.x, 0.03, p.z + side.z);
      positions.push(p.x - side.x, 0.03, p.z - side.z);
      uvs.push(0, v, 1, v);
    }

    for (var j = 0; j < n; j++) {
      var a = j * 2;
      var b = j * 2 + 1;
      var c = ((j + 1) % n) * 2;
      var d = ((j + 1) % n) * 2 + 1;
      indices.push(a, c, b, b, c, d);
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geo.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
    geo.setIndex(indices);
    geo.computeVertexNormals();

    var mat = new THREE.MeshStandardMaterial({
      map: getRoadTexture(theme.roadColor),
      color: theme.roadColor,
      roughness: 0.9,
      metalness: 0.05,
      side: THREE.DoubleSide
    });
    var mesh = new THREE.Mesh(geo, mat);
    mesh.receiveShadow = true;
    trackGroup.add(mesh);

    addMarkings(data, theme);
  }

  function addMarkings(data, theme) {
    var n = data.n;
    var half = data.width / 2;
    var lineMat = new THREE.MeshStandardMaterial({
      color: theme.lineColor,
      emissive: theme.rail === 'neon' ? theme.lineColor : 0x000000,
      emissiveIntensity: theme.rail === 'neon' ? 1.1 : 0,
      roughness: 0.6
    });

    /* solid edge lines */
    for (var s = 0; s < 2; s++) {
      var positions = [];
      var indices = [];
      var sign = s === 0 ? 1 : -1;
      var offset = half - 0.55;

      for (var i = 0; i < n; i++) {
        var p = data.pts[i];
        var next = data.pts[(i + 1) % n];
        var prev = data.pts[(i - 1 + n) % n];
        var dir = new THREE.Vector3().subVectors(next, prev).normalize();
        var side = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(offset * sign);
        var sideW = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(0.18);
        positions.push(p.x + side.x + sideW.x, 0.045, p.z + side.z + sideW.z);
        positions.push(p.x + side.x - sideW.x, 0.045, p.z + side.z - sideW.z);
      }
      for (var j = 0; j < n; j++) {
        var a = j * 2;
        var b = j * 2 + 1;
        var c = ((j + 1) % n) * 2;
        var d = ((j + 1) % n) * 2 + 1;
        indices.push(a, c, b, b, c, d);
      }
      var g = new THREE.BufferGeometry();
      g.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
      g.setIndex(indices);
      g.computeVertexNormals();
      trackGroup.add(new THREE.Mesh(g, lineMat));
    }

    /* centre dashes */
    var dashGeo = new THREE.PlaneGeometry(0.22, 4);
    dashGeo.rotateX(-Math.PI / 2);
    var dashCount = Math.floor(data.total / 12);
    var dashes = new THREE.InstancedMesh(dashGeo, lineMat, dashCount);
    var m = new THREE.Matrix4();
    var q = new THREE.Quaternion();
    var e = new THREE.Euler();

    for (var k = 0; k < dashCount; k++) {
      var smp = samplePath(data, (k * 12) / data.total);
      var ang = Math.atan2(smp.dir.x, smp.dir.z);
      e.set(0, ang, 0);
      q.setFromEuler(e);
      m.compose(new THREE.Vector3(smp.pos.x, 0.05, smp.pos.z), q, new THREE.Vector3(1, 1, 1));
      dashes.setMatrixAt(k, m);
    }
    dashes.instanceMatrix.needsUpdate = true;
    trackGroup.add(dashes);
  }

  function addBarriers(data, theme) {
    var n = data.n;
    var half = data.width / 2;

    for (var i = 0; i < n; i++) {
      var a = data.pts[i];
      var b = data.pts[(i + 1) % n];
      var mid = new THREE.Vector3().addVectors(a, b).multiplyScalar(0.5);
      var dir = new THREE.Vector3().subVectors(b, a);
      var len = dir.length();
      var angle = Math.atan2(dir.x, dir.z);
      var side = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(half + 1.1);

      for (var s = 0; s < 2; s++) {
        var sign = s === 0 ? 1 : -1;
        var px = mid.x + side.x * sign;
        var pz = mid.z + side.z * sign;

        if (theme.rail === 'neon') {
          var h = 1.1;
          var geo = new THREE.BoxGeometry(0.45, h, len + 0.35);
          var mat = new THREE.MeshStandardMaterial({
            color: theme.railColor,
            emissive: theme.railEmissive,
            emissiveIntensity: 1.25,
            roughness: 0.35,
            metalness: 0.4
          });
          var mesh = new THREE.Mesh(geo, mat);
          mesh.position.set(px, h / 2, pz);
          mesh.rotation.y = angle;
          trackGroup.add(mesh);
        } else {
          /* metal guardrail: a rail plus a post every other segment */
          var railGeo = new THREE.BoxGeometry(0.12, 0.34, len + 0.3);
          var railMat = new THREE.MeshStandardMaterial({
            color: theme.railColor,
            roughness: 0.35,
            metalness: 0.85
          });
          var rail = new THREE.Mesh(railGeo, railMat);
          rail.position.set(px, 0.82, pz);
          rail.rotation.y = angle;
          rail.castShadow = true;
          trackGroup.add(rail);

          if (i % 2 === 0) {
            var postGeo = new THREE.BoxGeometry(0.14, 0.9, 0.14);
            var post = new THREE.Mesh(postGeo, railMat);
            post.position.set(px, 0.45, pz);
            post.castShadow = true;
            trackGroup.add(post);
          }
        }

        var body = new CANNON.Body({ mass: 0 });
        body.addShape(new CANNON.Box(new CANNON.Vec3(0.3, 0.8, len / 2 + 0.2)));
        body.position.set(px, 0.8, pz);
        body.quaternion.setFromEuler(0, angle, 0);
        world.add(body);
        staticBodies.push(body);
      }
    }
  }

  function addCheckpoints(data, theme) {
    for (var g = 0; g < GATE_FRACTIONS.length; g++) {
      var u = GATE_FRACTIONS[g];
      var smp = samplePath(data, u);
      var angle = Math.atan2(smp.dir.x, smp.dir.z);
      var side = new THREE.Vector3(-smp.dir.z, 0, smp.dir.x).normalize().multiplyScalar(data.width / 2 + 1.2);
      var isFinish = g === 0;
      var color = isFinish ? 0x3dff9a : (theme.rail === 'neon' ? 0x35c8ff : 0xffd23f);

      var pillarGeo = new THREE.BoxGeometry(0.55, 6, 0.55);
      var pillarMat = new THREE.MeshStandardMaterial({
        color: color,
        emissive: color,
        emissiveIntensity: theme.rail === 'neon' ? 1.2 : 0.35,
        roughness: 0.35,
        metalness: 0.5
      });

      for (var s = 0; s < 2; s++) {
        var sign = s === 0 ? 1 : -1;
        var pillar = new THREE.Mesh(pillarGeo, pillarMat);
        pillar.position.set(smp.pos.x + side.x * sign, 3, smp.pos.z + side.z * sign);
        pillar.castShadow = true;
        trackGroup.add(pillar);
      }

      var barGeo = new THREE.BoxGeometry(data.width + 2.6, 0.4, 0.4);
      var bar = new THREE.Mesh(barGeo, pillarMat);
      bar.position.set(smp.pos.x, 5.9, smp.pos.z);
      bar.rotation.y = angle + Math.PI / 2;
      trackGroup.add(bar);

      checkpoints.push({ pos: new THREE.Vector3(smp.pos.x, 0, smp.pos.z) });
    }
  }

  function addCityDecor(data) {
    var tex = buildingTexture();
    var boxGeo = new THREE.BoxGeometry(1, 1, 1);

    for (var i = 0; i < 90; i++) {
      var angle = Math.random() * Math.PI * 2;
      var radius = 165 + Math.random() * 320;
      var h = 22 + Math.random() * 90;
      var w = 12 + Math.random() * 20;

      var mat = new THREE.MeshStandardMaterial({
        color: 0x0e1622,
        map: tex,
        emissiveMap: tex,
        emissive: 0xffffff,
        emissiveIntensity: 0.55,
        roughness: 0.7,
        metalness: 0.25
      });
      var mesh = new THREE.Mesh(boxGeo, mat);
      mesh.scale.set(w, h, w * 0.85);
      mesh.position.set(Math.cos(angle) * radius, h / 2, Math.sin(angle) * radius * 0.9);
      mesh.rotation.y = Math.random() * Math.PI;
      trackGroup.add(mesh);
    }
  }

  function addRockDecor() {
    var geo = new THREE.DodecahedronGeometry(1, 0);
    var count = 110;
    var mat = new THREE.MeshStandardMaterial({ color: 0x8a6242, roughness: 1.0, metalness: 0.0 });
    var inst = new THREE.InstancedMesh(geo, mat, count);
    inst.castShadow = true;
    inst.receiveShadow = true;
    var m = new THREE.Matrix4();
    var q = new THREE.Quaternion();
    var e = new THREE.Euler();

    for (var i = 0; i < count; i++) {
      var angle = Math.random() * Math.PI * 2;
      var radius = 150 + Math.random() * 360;
      var s = 3 + Math.random() * 13;
      e.set(Math.random(), Math.random() * Math.PI, Math.random());
      q.setFromEuler(e);
      m.compose(
        new THREE.Vector3(Math.cos(angle) * radius, s * 0.3, Math.sin(angle) * radius * 0.9),
        q,
        new THREE.Vector3(s, s * (0.6 + Math.random() * 0.7), s)
      );
      inst.setMatrixAt(i, m);
    }
    inst.instanceMatrix.needsUpdate = true;
    trackGroup.add(inst);
  }

  function addForest(data) {
    var trunkGeo = new THREE.CylinderGeometry(0.28, 0.42, 3.2, 6);
    var leafGeo = new THREE.ConeGeometry(2.1, 6.4, 7);
    var trunkMat = new THREE.MeshStandardMaterial({ color: 0x4a3524, roughness: 1.0 });
    var leafMat = new THREE.MeshStandardMaterial({ color: 0x2f5d2b, roughness: 0.95 });

    var count = 320;
    var trunks = new THREE.InstancedMesh(trunkGeo, trunkMat, count);
    var leaves = new THREE.InstancedMesh(leafGeo, leafMat, count);
    trunks.castShadow = true;
    leaves.castShadow = true;
    leaves.receiveShadow = true;

    var m = new THREE.Matrix4();
    var q = new THREE.Quaternion();
    var e = new THREE.Euler();
    var placed = 0;
    var guard = 0;

    while (placed < count && guard < count * 12) {
      guard++;
      var angle = Math.random() * Math.PI * 2;
      var radius = 150 + Math.random() * 420;
      var x = Math.cos(angle) * radius;
      var z = Math.sin(angle) * radius * 0.9;

      /* keep the trees off the racing surface */
      var near = nearestOnPath(data, x, z);
      if (near.dist < (data.width / 2 + 14) * (data.width / 2 + 14)) continue;

      var s = 0.75 + Math.random() * 0.9;
      e.set(0, Math.random() * Math.PI * 2, 0);
      q.setFromEuler(e);

      m.compose(new THREE.Vector3(x, 1.6 * s, z), q, new THREE.Vector3(s, s, s));
      trunks.setMatrixAt(placed, m);
      m.compose(new THREE.Vector3(x, (3.2 + 2.4) * s, z), q, new THREE.Vector3(s, s, s));
      leaves.setMatrixAt(placed, m);
      placed++;
    }

    trunks.count = placed;
    leaves.count = placed;
    trunks.instanceMatrix.needsUpdate = true;
    leaves.instanceMatrix.needsUpdate = true;
    trackGroup.add(trunks);
    trackGroup.add(leaves);
  }

  function addMountains() {
    var geo = new THREE.ConeGeometry(1, 1, 6);
    var mat = new THREE.MeshStandardMaterial({ color: 0x6f7f92, roughness: 1.0, flatShading: true });
    var count = 26;
    var inst = new THREE.InstancedMesh(geo, mat, count);
    var m = new THREE.Matrix4();
    var q = new THREE.Quaternion();
    var e = new THREE.Euler();

    for (var i = 0; i < count; i++) {
      var angle = (i / count) * Math.PI * 2 + Math.random() * 0.2;
      var radius = 520 + Math.random() * 260;
      var h = 160 + Math.random() * 190;
      var w = 150 + Math.random() * 130;
      e.set(0, Math.random() * Math.PI, 0);
      q.setFromEuler(e);
      m.compose(
        new THREE.Vector3(Math.cos(angle) * radius, h / 2 - 20, Math.sin(angle) * radius * 0.9),
        q,
        new THREE.Vector3(w, h, w)
      );
      inst.setMatrixAt(i, m);
    }
    inst.instanceMatrix.needsUpdate = true;
    trackGroup.add(inst);
  }

  function addMounds(data) {
    var idxs = [7, 21, 36, 47, 58];
    for (var k = 0; k < idxs.length; k++) {
      var smp = samplePath(data, idxs[k] / data.n);
      var angle = Math.atan2(smp.dir.x, smp.dir.z);

      var geo = new THREE.BoxGeometry(14, 1.5, 9);
      var mat = new THREE.MeshStandardMaterial({ color: 0x7d5836, roughness: 1.0 });
      var mesh = new THREE.Mesh(geo, mat);
      mesh.position.set(smp.pos.x, 0.5, smp.pos.z);
      mesh.rotation.set(-0.12, angle, 0, 'YXZ');
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      trackGroup.add(mesh);

      var body = new CANNON.Body({ mass: 0 });
      body.addShape(new CANNON.Box(new CANNON.Vec3(7, 0.75, 4.5)));
      body.position.set(smp.pos.x, 0.5, smp.pos.z);
      body.quaternion.setFromEuler(-0.12, angle, 0, 'YXZ');
      world.add(body);
      staticBodies.push(body);
    }
  }

  function buildTrack(trackId) {
    clearTrack();

    var theme = THEMES[trackId] || THEMES.alpine_pass;
    scene.fog = new THREE.FogExp2(theme.fog, theme.fogDensity);
    skyMat.uniforms.topColor.value.setHex(theme.skyTop);
    skyMat.uniforms.bottomColor.value.setHex(theme.skyHorizon);
    hemi.color.setHex(theme.hemiSky);
    hemi.groundColor.setHex(theme.hemiGround);
    sun.color.setHex(theme.sun);
    sun.intensity = theme.sunIntensity;
    ambient.intensity = theme.decor === 'city' ? 0.15 : 0.3;
    renderer.toneMappingExposure = theme.exposure;
    applyEnvironment(theme);

    var data = buildPath(trackId);
    pathData = data;

    addGround(theme);
    addRoad(data, theme);
    addBarriers(data, theme);
    addCheckpoints(data, theme);

    if (theme.decor === 'city') addCityDecor(data);
    else if (theme.decor === 'rocks') {
      addRockDecor();
      addMounds(data);
    } else {
      addForest(data);
      addMountains();
    }

    var start = samplePath(data, 0);
    startPos.set(start.pos.x, 0, start.pos.z);
    startAngle = Math.atan2(start.dir.x, start.dir.z);

    state.trackId = trackId;

    postTrackShape(data);
  }

  function postTrackShape(data) {
    var minX = Infinity, maxX = -Infinity, minZ = Infinity, maxZ = -Infinity;
    var flat = [];
    for (var i = 0; i < data.n; i++) {
      var p = data.pts[i];
      flat.push(Math.round(p.x * 10) / 10, Math.round(p.z * 10) / 10);
      minX = Math.min(minX, p.x); maxX = Math.max(maxX, p.x);
      minZ = Math.min(minZ, p.z); maxZ = Math.max(maxZ, p.z);
    }
    post('track', {
      path: flat,
      min: [minX, minZ],
      max: [maxX, maxZ],
      width: data.width
    });
  }

  /* ------------------------------------------------------------------ *
   * Car meshes
   * ------------------------------------------------------------------ */
  function taperBox(geo, topScaleX, topScaleZ) {
    var pos = geo.attributes.position;
    for (var i = 0; i < pos.count; i++) {
      var y = pos.getY(i);
      if (y > 0) {
        pos.setX(i, pos.getX(i) * topScaleX);
        pos.setZ(i, pos.getZ(i) * topScaleZ);
      }
    }
    pos.needsUpdate = true;
    geo.computeVertexNormals();
    return geo;
  }

  function buildWheel(shape, rimStyle) {
    var wheel = new THREE.Group();
    var r = shape.wheelR;

    var tyreMat = new THREE.MeshStandardMaterial({ color: 0x0e1014, roughness: 0.95, metalness: 0.05 });
    var tyreGeo = new THREE.CylinderGeometry(r, r, 0.30, 20);
    tyreGeo.rotateZ(Math.PI / 2);
    var tyre = new THREE.Mesh(tyreGeo, tyreMat);
    tyre.castShadow = true;
    wheel.add(tyre);

    var rimColor = rimStyle === 1 ? 0xd8b45a : (rimStyle === 2 ? 0x22262e : 0xc9d3e0);
    var rimMat = new THREE.MeshStandardMaterial({ color: rimColor, metalness: 0.95, roughness: 0.22 });

    var discGeo = new THREE.CylinderGeometry(r * 0.62, r * 0.62, 0.32, 16);
    discGeo.rotateZ(Math.PI / 2);
    wheel.add(new THREE.Mesh(discGeo, rimMat));

    var spokeGeo = new THREE.BoxGeometry(0.34, r * 1.05, 0.07);
    for (var i = 0; i < 5; i++) {
      var spoke = new THREE.Mesh(spokeGeo, rimMat);
      spoke.rotation.x = (i / 5) * Math.PI;
      wheel.add(spoke);
    }

    var brakeGeo = new THREE.CylinderGeometry(r * 0.42, r * 0.42, 0.05, 12);
    brakeGeo.rotateZ(Math.PI / 2);
    wheel.add(new THREE.Mesh(brakeGeo, new THREE.MeshStandardMaterial({ color: 0x6b6b6b, metalness: 0.8, roughness: 0.4 })));

    return wheel;
  }

  /* A real silhouette instead of stacked boxes: the side profile of a coupe is
     extruded across the car's width and bevelled, which gives the rounded
     shoulder line that reads as a car body. */
  var BODY_PROFILE = [
    [0.50, 0.10], [0.50, 0.34], [0.42, 0.46], [0.28, 0.52], [0.10, 0.56],
    [-0.02, 0.94], [-0.26, 1.00], [-0.42, 0.78], [-0.50, 0.62], [-0.50, 0.30],
    [-0.46, 0.10]
  ];

  var GLASS_PROFILE = [
    [0.09, 0.58], [-0.02, 0.93], [-0.25, 0.99], [-0.40, 0.79], [-0.28, 0.62], [0.02, 0.60]
  ];

  function extrudeProfile(profile, length, height, width, bevelScale) {
    var path = new THREE.Shape();
    for (var i = 0; i < profile.length; i++) {
      var X = profile[i][0] * length;
      var Y = profile[i][1] * height;
      if (i === 0) path.moveTo(X, Y);
      else path.lineTo(X, Y);
    }
    path.closePath();

    var bev = Math.min(0.1, width * (bevelScale || 0.06));
    var depth = Math.max(0.05, width - bev * 2);
    var geo = new THREE.ExtrudeGeometry(path, {
      depth: depth,
      bevelEnabled: true,
      bevelSize: bev,
      bevelThickness: bev,
      bevelSegments: 2,
      curveSegments: 4
    });
    geo.translate(0, 0, -depth / 2);
    geo.rotateY(-Math.PI / 2);   // length ends up along +Z, nose forward
    geo.computeVertexNormals();
    return geo;
  }

  function createCarMesh(cfg, shape, paintHex, finish, rimStyle) {
    var group = new THREE.Group();
    var half = shape.half;

    var paint = new THREE.MeshStandardMaterial({
      color: paintHex,
      metalness: finish === 'metallic' ? 0.95 : 0.6,
      roughness: finish === 'matte' ? 0.85 : (finish === 'metallic' ? 0.16 : 0.3),
      envMapIntensity: 1.15
    });
    var glass = new THREE.MeshStandardMaterial({
      color: 0x0a1018,
      metalness: 0.9,
      roughness: 0.08,
      envMapIntensity: 1.4
    });
    var dark = new THREE.MeshStandardMaterial({ color: 0x12151b, roughness: 0.75, metalness: 0.35 });
    var chrome = new THREE.MeshStandardMaterial({ color: 0xcfd6de, metalness: 1.0, roughness: 0.15 });

    /* sculpted body shell */
    var length = half[2] * 2;
    var height = Math.max(shape.roofY * 1.28, half[1] * 2.5);
    var width = half[0] * 2;

    var bodyGeo = extrudeProfile(BODY_PROFILE, length, height, width, 0.055);
    var body = new THREE.Mesh(bodyGeo, paint);
    body.castShadow = true;
    body.receiveShadow = true;
    body.position.y = -half[1];
    group.add(body);

    /* glass canopy, slightly narrower and inset */
    var glassGeo = extrudeProfile(GLASS_PROFILE, length * 0.98, height * 1.012, width * 1.015, 0.04);
    var cabin = new THREE.Mesh(glassGeo, glass);
    cabin.castShadow = true;
    cabin.position.y = -half[1] + 0.004;
    group.add(cabin);

    /* fenders over the wheels */
    var fenderGeo = new THREE.BoxGeometry(0.22, 0.3, shape.wheelR * 2.5);
    for (var f = 0; f < 4; f++) {
      var fx = (f % 2 === 0 ? 1 : -1) * (half[0] + 0.02);
      var fz = (f < 2 ? 1 : -1) * (half[2] - 0.55);
      var fender = new THREE.Mesh(fenderGeo, paint);
      fender.position.set(fx, -half[1] + height * 0.26, fz);
      fender.castShadow = true;
      group.add(fender);
    }

    /* side skirt */
    var skirt = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 2.02, 0.1, half[2] * 1.45), dark);
    skirt.position.set(0, -half[1] + height * 0.16, 0);
    group.add(skirt);

    /* headlights and tail lights */
    var lightMat = new THREE.MeshStandardMaterial({
      color: 0xffffff, emissive: 0xfff2cc, emissiveIntensity: 1.6, roughness: 0.2
    });
    var tailMat = new THREE.MeshStandardMaterial({
      color: 0xff2233, emissive: 0xff2233, emissiveIntensity: 1.4, roughness: 0.3
    });

    for (var l = 0; l < 2; l++) {
      var lx = (l === 0 ? 1 : -1) * half[0] * 0.55;
      var head = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 0.46, 0.11, 0.09), lightMat);
      head.position.set(lx, -half[1] + height * 0.30, half[2] * 0.99);
      group.add(head);

      var tail = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 0.5, 0.1, 0.08), tailMat);
      tail.position.set(lx, -half[1] + height * 0.55, -half[2] * 0.99);
      group.add(tail);
    }

    /* mirrors */
    for (var mi = 0; mi < 2; mi++) {
      var mx = (mi === 0 ? 1 : -1) * (half[0] + 0.12);
      var mirror = new THREE.Mesh(new THREE.BoxGeometry(0.2, 0.1, 0.14), dark);
      mirror.position.set(mx, -half[1] + height * 0.62, shape.cabinZ + 0.55);
      group.add(mirror);
    }

    /* wing */
    if (shape.wing) {
      var wingY = -half[1] + height * 0.86;
      var wing = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 1.85, 0.07, 0.42), dark);
      wing.position.set(0, wingY, -half[2] + 0.3);
      wing.castShadow = true;
      group.add(wing);

      for (var w2 = 0; w2 < 2; w2++) {
        var plate = new THREE.Mesh(new THREE.BoxGeometry(0.05, 0.2, 0.46), dark);
        plate.position.set((w2 === 0 ? 1 : -1) * half[0] * 0.92, wingY, -half[2] + 0.3);
        group.add(plate);

        var stalk = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.26, 0.07), dark);
        stalk.position.set((w2 === 0 ? 1 : -1) * half[0] * 0.5, wingY - 0.14, -half[2] + 0.3);
        group.add(stalk);
      }
    }

    /* exhausts */
    for (var ex = 0; ex < 2; ex++) {
      var pipeGeo = new THREE.CylinderGeometry(0.07, 0.07, 0.16, 8);
      pipeGeo.rotateX(Math.PI / 2);
      var pipe = new THREE.Mesh(pipeGeo, chrome);
      pipe.position.set((ex === 0 ? 1 : -1) * half[0] * 0.45, -half[1] + height * 0.14, -half[2] * 1.01);
      group.add(pipe);
    }

    return group;
  }

  /* ------------------------------------------------------------------ *
   * Player car
   * ------------------------------------------------------------------ */
  var chassisBody = null;
  var vehicle = null;
  var carGroup = null;
  var wheelMeshes = [];

  function clearCar() {
    if (carGroup) {
      disposeGroup(carGroup);
      scene.remove(carGroup);
      carGroup = null;
    }
    wheelMeshes.forEach(function (w) {
      disposeGroup(w);
      scene.remove(w);
    });
    wheelMeshes = [];
    if (vehicle) {
      if (world.removeVehicle) world.removeVehicle(vehicle);
      else if (vehicle.removeFromWorld) vehicle.removeFromWorld(world);
    }
    vehicle = null;
    if (chassisBody) {
      removeBody(chassisBody);
      chassisBody = null;
    }
  }

  function buildCar(cfg) {
    clearCar();

    var shape = CAR_SHAPES[cfg.id] || CAR_SHAPES.vortex_gt;
    var half = shape.half;

    chassisBody = new CANNON.Body({ mass: cfg.mass });
    chassisBody.addShape(new CANNON.Box(new CANNON.Vec3(half[0], half[1], half[2])));
    chassisBody.position.set(startPos.x, 1.3, startPos.z);
    chassisBody.quaternion.setFromEuler(0, startAngle, 0);
    chassisBody.linearDamping = 0.09;
    chassisBody.angularDamping = 0.45;
    world.add(chassisBody);

    vehicle = new CANNON.RaycastVehicle({
      chassisBody: chassisBody,
      indexRightAxis: 0,
      indexUpAxis: 1,
      indexForwardAxis: 2
    });

    var wheelBase = half[2] - 0.55;
    var trackWidth = half[0] - 0.04;

    var opts = {
      radius: shape.wheelR,
      directionLocal: new CANNON.Vec3(0, -1, 0),
      axleLocal: new CANNON.Vec3(-1, 0, 0),
      suspensionStiffness: cfg.suspensionStiffness,
      suspensionRestLength: 0.34,
      maxSuspensionTravel: 0.3,
      frictionSlip: cfg.frictionSlip,
      dampingRelaxation: 2.4,
      dampingCompression: 4.6,
      maxSuspensionForce: 100000,
      rollInfluence: 0.03,
      customSlidingRotationalSpeed: -30,
      useCustomSlidingRotationalSpeed: true,
      chassisConnectionPointLocal: new CANNON.Vec3()
    };

    var mounts = [
      [-trackWidth, 0, wheelBase],
      [trackWidth, 0, wheelBase],
      [-trackWidth, 0, -wheelBase],
      [trackWidth, 0, -wheelBase]
    ];

    for (var m = 0; m < mounts.length; m++) {
      opts.chassisConnectionPointLocal.set(mounts[m][0], mounts[m][1], mounts[m][2]);
      vehicle.addWheel(opts);
    }
    vehicle.addToWorld(world);

    carGroup = createCarMesh(cfg, shape, new THREE.Color(cfg.color || '#22d3ee'), cfg.finish, cfg.rim);
    scene.add(carGroup);

    for (var i = 0; i < 4; i++) {
      var wheel = buildWheel(shape, cfg.rim);
      scene.add(wheel);
      wheelMeshes.push(wheel);
    }

    state.car = cfg;
    resetToStart();
  }

  function resetToStart() {
    if (!chassisBody) return;
    chassisBody.position.set(startPos.x, 1.3, startPos.z);
    chassisBody.quaternion.setFromEuler(0, startAngle, 0);
    chassisBody.velocity.set(0, 0, 0);
    chassisBody.angularVelocity.set(0, 0, 0);
    chassisBody.force.set(0, 0, 0);
    chassisBody.torque.set(0, 0, 0);
    if (chassisBody.wakeUp) chassisBody.wakeUp();

    state.lap = 0;
    state.cpPtr = 0;
    state.bestLap = 0;
    state.drifting = 0;
    state.flipTimer = 0;
    state.reverseHold = 0;

    input.throttle = 0;
    input.brake = 0;
    input.steer = 0;
    input.handbrake = 0;
  }

  /* ------------------------------------------------------------------ *
   * Rivals (kinematic, they follow the racing line)
   * ------------------------------------------------------------------ */
  var rivals = [];

  function clearRivals() {
    rivals.forEach(function (r) {
      disposeGroup(r.mesh);
      scene.remove(r.mesh);
    });
    rivals = [];
  }

  function buildRivals(count) {
    clearRivals();
    if (!pathData) return;

    var base = state.car || { finish: 'gloss', rim: 0 };
    var shapes = ['apex_spider', 'vortex_gt', 'titan_x', 'nomad_r1', 'vortex_gt', 'titan_x'];
    var top = (state.car && state.car.topSpeed) || 52;

    for (var i = 0; i < count; i++) {
      var shapeId = shapes[i % shapes.length];
      var shape = CAR_SHAPES[shapeId];
      var color = RIVAL_COLORS[i % RIVAL_COLORS.length];
      var mesh = createCarMesh(
        { id: shapeId },
        shape,
        new THREE.Color(color),
        'metallic',
        0
      );
      scene.add(mesh);

      var startU = 0.012 * (i + 1);
      rivals.push({
        mesh: mesh,
        shape: shape,
        u: startU,
        lap: 0,
        lane: (i % 2 === 0 ? 1 : -1) * (2.2 + Math.random() * 1.6),
        skill: 0.82 + Math.random() * 0.16,
        speed: top * (0.62 + Math.random() * 0.16),
        wobble: Math.random() * 6.28
      });
    }
    state.total = rivals.length + 1;
  }

  var rivalWheels = [];
  function updateRivals(dt, elapsed) {
    if (!pathData) return;
    for (var i = 0; i < rivals.length; i++) {
      var r = rivals[i];
      var target = r.speed * (1 + 0.06 * Math.sin(elapsed * 0.7 + r.wobble));
      r.u += (target * dt) / pathData.total;
      if (r.u >= 1) {
        r.u -= 1;
        r.lap += 1;
      }

      var smp = samplePath(pathData, r.u);
      var normal = new THREE.Vector3(-smp.dir.z, 0, smp.dir.x).normalize();
      var px = smp.pos.x + normal.x * r.lane;
      var pz = smp.pos.z + normal.z * r.lane;
      var ang = Math.atan2(smp.dir.x, smp.dir.z);

      r.mesh.position.set(px, r.shape.half[1] + 0.36, pz);
      r.mesh.rotation.set(0, ang, 0);
    }
  }

  /* ------------------------------------------------------------------ *
   * Driving
   * ------------------------------------------------------------------ */
  var fwdVec = new CANNON.Vec3();
  var upVec = new CANNON.Vec3();
  var rightVec = new CANNON.Vec3();

  function stepPhysics(dt) {
    if (!vehicle || !chassisBody || !state.car) return;

    var cfg = state.car;
    var speed = chassisBody.velocity.length();

    chassisBody.quaternion.vmult(new CANNON.Vec3(0, 0, 1), fwdVec);
    chassisBody.quaternion.vmult(new CANNON.Vec3(0, 1, 0), upVec);
    chassisBody.quaternion.vmult(new CANNON.Vec3(1, 0, 0), rightVec);

    var fwdSpeed = chassisBody.velocity.dot(fwdVec);
    var latSpeed = chassisBody.velocity.dot(rightVec);

    var lock = Math.max(0.13, 0.58 - speed * 0.011);
    var steer = input.steer * lock;
    vehicle.setSteeringValue(steer, 0);
    vehicle.setSteeringValue(steer, 1);

    var engine = cfg.engineForce * ENGINE_SCALE;
    var force = 0;        // + drives the nose forward
    var brakeAll = 0;

    /* Cannon's raycast vehicle pushes the chassis along -Z for a positive
       engine force, which made the car drive tail-first. `drive` is the game's
       own sign (+ = forward) and is flipped once when it is applied below. */
    /* reverse only after the car has actually been standing still on the
       brake for a moment — holding the pedal at speed must never flip it */
    if (input.brake > 0 && input.throttle <= 0 && fwdSpeed < 0.8) {
      state.reverseHold += dt;
    } else {
      state.reverseHold = 0;
    }
    var reversing = state.reverseHold > 0.3;

    if (input.throttle > 0 && fwdSpeed < cfg.topSpeed) {
      force = engine * input.throttle;
    } else if (reversing && fwdSpeed > -9) {
      force = -engine * 0.42 * input.brake;
    }

    if (input.brake > 0 && !reversing) {
      brakeAll = 180 * input.brake;
    }

    vehicle.applyEngineForce(-force, 2);
    vehicle.applyEngineForce(-force, 3);
    vehicle.applyEngineForce(0, 0);
    vehicle.applyEngineForce(0, 1);

    vehicle.setBrake(brakeAll, 0);
    vehicle.setBrake(brakeAll, 1);

    var handbrake = input.handbrake ? 200 : 0;
    vehicle.setBrake(input.handbrake ? handbrake : brakeAll, 2);
    vehicle.setBrake(input.handbrake ? handbrake : brakeAll, 3);

    var rearSlip = input.handbrake ? cfg.frictionSlip * 0.42 : cfg.frictionSlip;
    vehicle.wheelInfos[2].frictionSlip = rearSlip;
    vehicle.wheelInfos[3].frictionSlip = rearSlip;

    state.drifting = (speed > 9 && Math.abs(latSpeed) > 3.4) ? 1 : 0;

    if (upVec.y < 0.3 && state.phase === 'racing') {
      state.flipTimer += dt;
      if (state.flipTimer > 1.6) {
        chassisBody.position.y += 1.4;
        chassisBody.quaternion.setFromEuler(0, startAngle, 0);
        chassisBody.velocity.set(0, 0, 0);
        chassisBody.angularVelocity.set(0, 0, 0);
        state.flipTimer = 0;
      }
    } else {
      state.flipTimer = 0;
    }

    if (chassisBody.position.y < -8) resetToStart();

    world.step(FIXED_STEP, dt, 3);
  }

  /* ------------------------------------------------------------------ *
   * Race logic
   * ------------------------------------------------------------------ */
  function completeLap() {
    var now = performance.now() / 1000;
    var lapTime = now - state.lapStart;
    state.lap += 1;

    if (!state.bestLap || lapTime < state.bestLap) state.bestLap = lapTime;

    if (state.lap >= LAPS) {
      state.phase = 'finished';
      input.throttle = 0;
      input.brake = 1;
      post('finished', {
        totalTime: now - state.raceStart,
        bestLap: state.bestLap,
        lapTime: lapTime,
        pos: state.pos,
        total: state.total
      });
      return;
    }

    state.lapStart = now;
    post('lap', { lap: state.lap + 1, lapTime: lapTime, bestLap: state.bestLap });
  }

  function updateRace() {
    if (state.phase !== 'racing' || !chassisBody || checkpoints.length === 0) return;

    var gateIdx = CP_ORDER[state.cpPtr];
    var cp = checkpoints[gateIdx];
    var dx = chassisBody.position.x - cp.pos.x;
    var dz = chassisBody.position.z - cp.pos.z;

    if (dx * dx + dz * dz < CP_RADIUS2) {
      if (gateIdx === 0) {
        state.cpPtr = 0;
        completeLap();
      } else {
        state.cpPtr += 1;
        post('checkpoint', { cp: state.cpPtr, total: CP_ORDER.length - 1 });
      }
    }
  }

  function playerProgress() {
    if (!pathData || !chassisBody) return 0;
    var near = nearestOnPath(pathData, chassisBody.position.x, chassisBody.position.z);
    return state.lap * pathData.total + near.along;
  }

  function updateStandings() {
    if (!pathData) return;
    var mine = playerProgress();
    var ahead = 0;
    for (var i = 0; i < rivals.length; i++) {
      var r = rivals[i];
      var theirs = r.lap * pathData.total + r.u * pathData.total;
      if (theirs > mine) ahead++;
    }
    state.pos = ahead + 1;
    state.total = rivals.length + 1;
  }

  function tickCountdown(dt) {
    state.countdown -= dt;
    var shown = Math.ceil(state.countdown);
    if (shown !== state.lastCountShown) {
      state.lastCountShown = shown;
      if (shown > 0) post('countdown', { value: shown });
    }
    if (state.countdown <= 0) {
      state.phase = 'racing';
      state.raceStart = performance.now() / 1000;
      state.lapStart = state.raceStart;
      state.cpPtr = 0;
      post('countdown', { value: 0 });
      post('lap', { lap: 1, lapTime: 0, bestLap: 0 });
    }
  }

  /* ------------------------------------------------------------------ *
   * Visual sync + camera
   * ------------------------------------------------------------------ */
  var camPos = new THREE.Vector3(0, 10, -20);
  var camLook = new THREE.Vector3();
  var tmpQ = new THREE.Quaternion();
  var vBack = new THREE.Vector3();
  var vFwd = new THREE.Vector3();
  var vDesired = new THREE.Vector3();

  function updateVisuals() {
    if (!chassisBody || !carGroup) return;

    carGroup.position.set(chassisBody.position.x, chassisBody.position.y, chassisBody.position.z);
    carGroup.quaternion.set(
      chassisBody.quaternion.x,
      chassisBody.quaternion.y,
      chassisBody.quaternion.z,
      chassisBody.quaternion.w
    );

    for (var i = 0; i < wheelMeshes.length; i++) {
      if (!vehicle || !vehicle.wheelInfos[i]) continue;
      vehicle.updateWheelTransform(i);
      var t = vehicle.wheelInfos[i].worldTransform;
      wheelMeshes[i].position.set(t.position.x, t.position.y, t.position.z);
      wheelMeshes[i].quaternion.set(t.quaternion.x, t.quaternion.y, t.quaternion.z, t.quaternion.w);
    }

    /* keep the shadow frustum around the car */
    if (chassisBody) {
      sun.position.set(chassisBody.position.x + 80, 140, chassisBody.position.z + 60);
      sun.target.position.set(chassisBody.position.x, 0, chassisBody.position.z);
      sun.target.updateMatrixWorld();
      skyDome.position.set(camera.position.x, 0, camera.position.z);
    }
  }

  function updateCamera(dt) {
    if (!chassisBody) return;

    tmpQ.set(
      chassisBody.quaternion.x,
      chassisBody.quaternion.y,
      chassisBody.quaternion.z,
      chassisBody.quaternion.w
    );

    vBack.set(0, 0, -1).applyQuaternion(tmpQ);
    vFwd.set(0, 0, 1).applyQuaternion(tmpQ);

    vDesired.set(chassisBody.position.x, chassisBody.position.y, chassisBody.position.z)
      .addScaledVector(vBack, 9.2);
    vDesired.y += 3.4;

    var k = 1 - Math.exp(-dt * 6.0);
    camPos.lerp(vDesired, k);
    camera.position.copy(camPos);

    camLook.set(chassisBody.position.x, chassisBody.position.y + 1.1, chassisBody.position.z)
      .addScaledVector(vFwd, 7);
    camera.lookAt(camLook);

    var speed = chassisBody.velocity.length();
    var fov = Math.min(84, 60 + speed * 0.24);
    if (Math.abs(camera.fov - fov) > 0.2) {
      camera.fov = fov;
      camera.updateProjectionMatrix();
    }
  }

  /* ------------------------------------------------------------------ *
   * Main loop
   * ------------------------------------------------------------------ */
  var last = performance.now();
  var hudTimer = 0;
  var elapsed = 0;

  function gearInfo(speedKmh, topSpeedMs) {
    var topKmh = Math.max(60, topSpeedMs * 3.6);
    var ratio = Math.max(0, Math.min(1, speedKmh / topKmh));
    var gear = speedKmh < 2 ? 1 : Math.min(6, 1 + Math.floor(ratio * 6));
    var lower = (gear - 1) / 6;
    var upper = gear / 6;
    var within = upper > lower ? (ratio - lower) / (upper - lower) : 0;
    var rpm = 900 + Math.max(0, Math.min(1, within)) * 6800;
    return { gear: gear, rpm: Math.round(rpm) };
  }

  function animate(now) {
    requestAnimationFrame(animate);

    var dt = (now - last) / 1000;
    last = now;
    if (dt > 0.1) dt = 0.1;
    elapsed += dt;

    if (state.phase === 'countdown') {
      tickCountdown(dt);
      stepPhysics(dt);
    } else if (state.phase === 'racing' || state.phase === 'finished') {
      stepPhysics(dt);
      updateRace();
    }

    if (state.phase === 'racing' || state.phase === 'countdown' || state.phase === 'finished') {
      updateRivals(dt, elapsed);
      updateStandings();
    }

    updateVisuals();
    updateCamera(dt);

    hudTimer += dt;
    if (hudTimer >= 0.1) {
      hudTimer = 0;
      var speedKmh = chassisBody ? Math.round(chassisBody.velocity.length() * 3.6) : 0;
      var gi = gearInfo(speedKmh, (state.car && state.car.topSpeed) || 52);
      post('hud', {
        speed: speedKmh,
        gear: speedKmh < 2 ? 0 : gi.gear,
        rpm: gi.rpm,
        lap: Math.min(state.lap + 1, LAPS),
        laps: LAPS,
        lapTime: state.phase === 'racing' ? (performance.now() / 1000 - state.lapStart) : 0,
        bestLap: state.bestLap,
        drifting: state.drifting,
        pos: state.pos,
        total: state.total,
        x: chassisBody ? Math.round(chassisBody.position.x * 10) / 10 : 0,
        z: chassisBody ? Math.round(chassisBody.position.z * 10) / 10 : 0
      });
    }

    renderer.render(scene, camera);
  }

  /* ------------------------------------------------------------------ *
   * Setup + API
   * ------------------------------------------------------------------ */
  function applySetup() {
    if (!state.trackId || !state.car) return;

    clearTrack();
    buildTrack(state.trackId);
    buildCar(state.car);
    buildRivals(state.opponents);

    camPos.set(startPos.x, 8, startPos.z - 14);
    state.phase = 'idle';
    state.pos = 1;
    state.total = rivals.length + 1;
    post('loaded', { track: state.trackId, car: state.car.id, rivals: rivals.length });
  }

  window.__AP = {
    setup: function (carCfg, trackId, opts) {
      state.car = carCfg;
      state.trackId = trackId;
      if (opts && typeof opts.opponents === 'number') state.opponents = opts.opponents;
      applySetup();
    },
    setCar: function (cfg) {
      state.car = cfg;
      applySetup();
    },
    setTrack: function (id) {
      state.trackId = id;
      applySetup();
    },
    setLaps: function (n) {
      LAPS = Math.max(1, Math.min(20, n | 0));
    },
    setOpponents: function (n) {
      state.opponents = Math.max(0, Math.min(9, n | 0));
    },
    setInput: function (o) {
      if (!o) return;
      if (typeof o.throttle === 'number') input.throttle = o.throttle;
      if (typeof o.brake === 'number') input.brake = o.brake;
      if (typeof o.steer === 'number') input.steer = o.steer;
      if (typeof o.handbrake === 'number') input.handbrake = o.handbrake;
    },
    start: function () {
      if (state.phase === 'racing' || state.phase === 'countdown') return;
      resetToStart();
      state.phase = 'countdown';
      state.countdown = 3.2;
      state.lastCountShown = -1;
      camPos.set(startPos.x, 8, startPos.z - 14);
      post('countdown', { value: 3 });
    },
    pause: function () {
      if (state.phase === 'racing' || state.phase === 'countdown') state.phase = 'paused';
    },
    resume: function () {
      if (state.phase === 'paused') state.phase = 'racing';
    },
    restart: function () {
      resetToStart();
      buildRivals(state.opponents);
      state.phase = 'countdown';
      state.countdown = 3.2;
      state.lastCountShown = -1;
      post('countdown', { value: 3 });
    },
    snapshot: function () {
      return JSON.stringify({
        phase: state.phase,
        lap: state.lap,
        pos: state.pos,
        speed: chassisBody ? chassisBody.velocity.length() : 0
      });
    }
  };

  window.addEventListener('resize', function () {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  var boot = document.getElementById('boot');
  if (boot && boot.parentNode) boot.parentNode.removeChild(boot);

  requestAnimationFrame(animate);
  post('ready');
})();
