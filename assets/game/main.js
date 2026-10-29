/*
 * AeroPulse: Horizon Drift — 3D scene, vehicle physics and race logic.
 *
 * Runs inside the Flutter WebView. Rendering is Three.js, physics is Cannon.js
 * (RaycastVehicle: raycast suspension + separate longitudinal / lateral tire
 * friction, which is what makes the drifting feel real).
 *
 * Flutter -> JS (called through runJavaScript):
 *   window.__AP.setCar({...})       car id, physics numbers, paint, finish, rim
 *   window.__AP.setTrack('neon_city' | 'canyon_dust')
 *   window.__AP.setInput({throttle, brake, steer, handbrake})
 *   window.__AP.start() / pause() / resume() / restart() / setLaps(n)
 *
 * JS -> Flutter (JavaScriptChannel named "AeroPulse"):
 *   {type:'ready'} {type:'loaded'} {type:'countdown', value}
 *   {type:'hud', speed, lap, laps, lapTime, bestLap, drifting, gear}
 *   {type:'checkpoint', cp, total} {type:'lap', lap, lapTime, bestLap}
 *   {type:'finished', lapTime, bestLap, totalTime} {type:'error', message}
 */
(function () {
  'use strict';

  var CHANNEL = 'AeroPulse';
  var LAPS = 3;
  var FIXED_STEP = 1 / 60;
  var ENGINE_SCALE = 3.4;
  var GATE_FRACTIONS = [0, 0.25, 0.5, 0.75]; // gate 0 is the start / finish line
  var CP_ORDER = [1, 2, 3, 0];               // order the gates must be cleared
  var CP_RADIUS2 = 12 * 12;

  /* ------------------------------------------------------------------ *
   * Bridge back to Flutter
   * ------------------------------------------------------------------ */
  function post(type, data) {
    var msg = data ? JSON.parse(JSON.stringify(data)) : {};
    msg.type = type;
    try {
      if (window[CHANNEL] && window[CHANNEL].postMessage) {
        window[CHANNEL].postMessage(JSON.stringify(msg));
      }
    } catch (e) {
      /* channel not attached yet — nothing useful to do */
    }
  }

  window.onerror = function (message) {
    post('error', { message: String(message) });
  };

  /* ------------------------------------------------------------------ *
   * Per-car geometry (built from primitives — no external models to load)
   * ------------------------------------------------------------------ */
  var CAR_SHAPES = {
    vortex_gt:   { half: [0.92, 0.27, 2.05], cabin: [0.70, 0.26, 0.95], cabinZ: -0.10, wing: true,  wheelR: 0.36, roofY: 0.50 },
    titan_x:     { half: [1.04, 0.33, 2.20], cabin: [0.84, 0.30, 1.05], cabinZ: -0.35, wing: true,  wheelR: 0.41, roofY: 0.58 },
    apex_spider: { half: [0.95, 0.24, 2.12], cabin: [0.68, 0.22, 0.78], cabinZ:  0.10, wing: true,  wheelR: 0.35, roofY: 0.44 },
    nomad_r1:    { half: [0.98, 0.36, 2.15], cabin: [0.84, 0.36, 1.15], cabinZ: -0.30, wing: false, wheelR: 0.43, roofY: 0.66 }
  };

  var TRACK_THEMES = {
    neon_city: {
      sky: 0x05070f, fog: 0x05070f, fogDensity: 0.0034,
      ground: 0x0b0e16, road: 0x141a26,
      barrier: 0x101828, emissive: 0x27d9ff, emissiveIntensity: 1.15,
      hemiSky: 0x8fd8ff, hemiGround: 0x101828, sun: 0xbcd8ff, sunIntensity: 0.9,
      decor: 'city'
    },
    canyon_dust: {
      sky: 0x2b1d12, fog: 0x50351f, fogDensity: 0.0028,
      ground: 0x7a5230, road: 0x5d3d24,
      barrier: 0x8a5a32, emissive: 0xff9d3c, emissiveIntensity: 0.55,
      hemiSky: 0xffd9a8, hemiGround: 0x3a2717, sun: 0xffe0b0, sunIntensity: 1.25,
      decor: 'rocks'
    }
  };

  /* ------------------------------------------------------------------ *
   * State
   * ------------------------------------------------------------------ */
  var state = {
    trackId: null,
    car: null,
    phase: 'idle',        // idle | countdown | racing | paused | finished
    countdown: 0,
    lastCountShown: -1,
    lap: 0,
    cpPtr: 0,
    lapStart: 0,
    bestLap: 0,
    raceStart: 0,
    drifting: 0,
    flipTimer: 0
  };

  var input = { throttle: 0, brake: 0, steer: 0, handbrake: 0 };

  /* ------------------------------------------------------------------ *
   * Renderer / scene / camera
   * ------------------------------------------------------------------ */
  var renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(1);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  document.body.appendChild(renderer.domElement);

  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(62, window.innerWidth / window.innerHeight, 0.1, 1400);
  camera.position.set(0, 8, -16);

  var hemi = new THREE.HemisphereLight(0x8fd8ff, 0x101828, 0.9);
  scene.add(hemi);

  var sun = new THREE.DirectionalLight(0xffffff, 1.0);
  sun.position.set(70, 120, 50);
  sun.castShadow = true;
  sun.shadow.mapSize.width = 1024;
  sun.shadow.mapSize.height = 1024;
  sun.shadow.camera.near = 10;
  sun.shadow.camera.far = 420;
  sun.shadow.camera.left = -120;
  sun.shadow.camera.right = 120;
  sun.shadow.camera.top = 120;
  sun.shadow.camera.bottom = -120;
  scene.add(sun);

  var ambient = new THREE.AmbientLight(0x3d4a63, 0.55);
  scene.add(ambient);

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
   * Track
   * ------------------------------------------------------------------ */
  var trackGroup = new THREE.Group();
  scene.add(trackGroup);

  var staticBodies = [];
  var checkpoints = [];        // { pos: THREE.Vector3 }
  var startPos = new THREE.Vector3();
  var startAngle = 0;

  var rand = (function () {
    var seed = 1337;
    return function () {
      seed = (seed * 1664525 + 1013904223) % 4294967296;
      return seed / 4294967296;
    };
  })();

  function disposeGroup(group) {
    group.traverse(function (o) {
      if (o.isMesh) {
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
  }

  function trackPath(kind) {
    var n = 56;
    var pts = [];
    var rx = kind === 'canyon_dust' ? 108 : 94;
    var rz = kind === 'canyon_dust' ? 74 : 80;
    for (var i = 0; i < n; i++) {
      var t = (i / n) * Math.PI * 2;
      var wob = kind === 'canyon_dust'
        ? 0.15 * Math.sin(3 * t)
        : 0.07 * Math.sin(2 * t);
      pts.push(new THREE.Vector3(
        Math.cos(t) * rx * (1 + wob),
        0,
        Math.sin(t) * rz * (1 + wob * 0.6)
      ));
    }
    return pts;
  }

  function addGround(theme) {
    var geo = new THREE.PlaneGeometry(900, 900);
    var mat = new THREE.MeshStandardMaterial({ color: theme.ground, roughness: 0.97, metalness: 0.0 });
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

  function addRoad(pts, width, color) {
    var n = pts.length;
    var positions = [];
    var indices = [];

    for (var i = 0; i < n; i++) {
      var p = pts[i];
      var next = pts[(i + 1) % n];
      var prev = pts[(i - 1 + n) % n];
      var dir = new THREE.Vector3().subVectors(next, prev).normalize();
      var side = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(width / 2);
      positions.push(p.x + side.x, 0.02, p.z + side.z);
      positions.push(p.x - side.x, 0.02, p.z - side.z);
    }

    for (var j = 0; j < n; j++) {
      var a = j * 2, b = j * 2 + 1;
      var c = ((j + 1) % n) * 2, d = ((j + 1) % n) * 2 + 1;
      indices.push(a, c, b, b, c, d);
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geo.setIndex(indices);
    geo.computeVertexNormals();

    var mat = new THREE.MeshStandardMaterial({
      color: color,
      roughness: 0.85,
      metalness: 0.08,
      side: THREE.DoubleSide
    });
    var mesh = new THREE.Mesh(geo, mat);
    mesh.receiveShadow = true;
    trackGroup.add(mesh);
  }

  function addBarriers(pts, width, theme) {
    var n = pts.length;
    var h = 1.15;

    for (var i = 0; i < n; i++) {
      var a = pts[i];
      var b = pts[(i + 1) % n];
      var mid = new THREE.Vector3().addVectors(a, b).multiplyScalar(0.5);
      var dir = new THREE.Vector3().subVectors(b, a);
      var len = dir.length();
      var angle = Math.atan2(dir.x, dir.z);
      var side = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(width / 2 + 0.7);

      for (var s = 0; s < 2; s++) {
        var sign = s === 0 ? 1 : -1;
        var px = mid.x + side.x * sign;
        var pz = mid.z + side.z * sign;

        var geo = new THREE.BoxGeometry(0.5, h, len + 0.4);
        var mat = new THREE.MeshStandardMaterial({
          color: theme.barrier,
          emissive: theme.emissive,
          emissiveIntensity: theme.emissiveIntensity,
          roughness: 0.4,
          metalness: 0.35
        });
        var mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(px, h / 2, pz);
        mesh.rotation.y = angle;
        mesh.receiveShadow = true;
        trackGroup.add(mesh);

        var body = new CANNON.Body({ mass: 0 });
        body.addShape(new CANNON.Box(new CANNON.Vec3(0.25, h / 2, len / 2 + 0.2)));
        body.position.set(px, h / 2, pz);
        body.quaternion.setFromEuler(0, angle, 0);
        world.add(body);
        staticBodies.push(body);
      }
    }
  }

  function addCheckpoints(pts) {
    var n = pts.length;

    for (var g = 0; g < GATE_FRACTIONS.length; g++) {
      var idx = Math.floor(GATE_FRACTIONS[g] * n) % n;
      var p = pts[idx];
      var next = pts[(idx + 1) % n];
      var prev = pts[(idx - 1 + n) % n];
      var dir = new THREE.Vector3().subVectors(next, prev).normalize();
      var angle = Math.atan2(dir.x, dir.z);
      var side = new THREE.Vector3(-dir.z, 0, dir.x).normalize().multiplyScalar(10.5);

      var isFinish = g === 0;
      var color = isFinish ? 0x3dff9a : 0x35c8ff;

      var pillarGeo = new THREE.BoxGeometry(0.5, 5.4, 0.5);
      var pillarMat = new THREE.MeshStandardMaterial({
        color: color,
        emissive: color,
        emissiveIntensity: 1.2,
        roughness: 0.3,
        metalness: 0.4
      });

      for (var s = 0; s < 2; s++) {
        var sign = s === 0 ? 1 : -1;
        var pillar = new THREE.Mesh(pillarGeo, pillarMat);
        pillar.position.set(p.x + side.x * sign, 2.7, p.z + side.z * sign);
        trackGroup.add(pillar);
      }

      var barGeo = new THREE.BoxGeometry(21.5, 0.35, 0.35);
      var bar = new THREE.Mesh(barGeo, pillarMat);
      bar.position.set(p.x, 5.2, p.z);
      bar.rotation.y = angle + Math.PI / 2;
      trackGroup.add(bar);

      checkpoints.push({ pos: new THREE.Vector3(p.x, 0, p.z) });
    }
  }

  function addCityDecor(pts) {
    var boxGeo = new THREE.BoxGeometry(1, 1, 1);

    for (var i = 0; i < 70; i++) {
      var angle = rand() * Math.PI * 2;
      var radius = 130 + rand() * 190;
      var h = 14 + rand() * 62;
      var w = 8 + rand() * 14;

      var mat = new THREE.MeshStandardMaterial({
        color: 0x0d1420,
        emissive: rand() > 0.55 ? 0x1a6fff : 0xff2d7a,
        emissiveIntensity: 0.35,
        roughness: 0.6,
        metalness: 0.3
      });
      var mesh = new THREE.Mesh(boxGeo, mat);
      mesh.scale.set(w, h, w * 0.9);
      mesh.position.set(Math.cos(angle) * radius, h / 2, Math.sin(angle) * radius * 0.85);
      trackGroup.add(mesh);
    }
  }

  function addRockDecor(pts) {
    var rockGeo = new THREE.DodecahedronGeometry(1, 0);

    for (var i = 0; i < 80; i++) {
      var angle = rand() * Math.PI * 2;
      var radius = 125 + rand() * 200;
      var s = 4 + rand() * 14;

      var mat = new THREE.MeshStandardMaterial({
        color: rand() > 0.5 ? 0x8a5a32 : 0x6d4526,
        roughness: 1.0,
        metalness: 0.0
      });
      var mesh = new THREE.Mesh(rockGeo, mat);
      mesh.scale.set(s, s * (0.5 + rand()), s);
      mesh.position.set(Math.cos(angle) * radius, s * 0.25, Math.sin(angle) * radius * 0.85);
      mesh.rotation.set(rand(), rand() * Math.PI, rand());
      trackGroup.add(mesh);
    }
  }

  /* Canyon keeps its "elevation change" as dirt mounds the car has to climb. */
  function addMounds(pts) {
    var idxs = [7, 21, 36, 47];

    for (var k = 0; k < idxs.length; k++) {
      var p = pts[idxs[k] % pts.length];
      var next = pts[(idxs[k] + 1) % pts.length];
      var dir = new THREE.Vector3().subVectors(next, p).normalize();
      var angle = Math.atan2(dir.x, dir.z);

      var geo = new THREE.BoxGeometry(14, 1.6, 9);
      var mat = new THREE.MeshStandardMaterial({ color: 0x6a4527, roughness: 1.0, metalness: 0.0 });
      var mesh = new THREE.Mesh(geo, mat);
      mesh.position.set(p.x, 0.55, p.z);
      mesh.rotation.set(-0.13, angle, 0, 'YXZ');
      mesh.receiveShadow = true;
      mesh.castShadow = true;
      trackGroup.add(mesh);

      var body = new CANNON.Body({ mass: 0 });
      body.addShape(new CANNON.Box(new CANNON.Vec3(7, 0.8, 4.5)));
      body.position.set(p.x, 0.55, p.z);
      body.quaternion.setFromEuler(-0.13, angle, 0, 'YXZ');
      world.add(body);
      staticBodies.push(body);
    }
  }

  function buildTrack(trackId) {
    clearTrack();

    var theme = TRACK_THEMES[trackId] || TRACK_THEMES.neon_city;
    scene.background = new THREE.Color(theme.sky);
    scene.fog = new THREE.FogExp2(theme.fog, theme.fogDensity);

    hemi.color.setHex(theme.hemiSky);
    hemi.groundColor.setHex(theme.hemiGround);
    sun.color.setHex(theme.sun);
    sun.intensity = theme.sunIntensity;

    var pts = trackPath(trackId);

    addGround(theme);
    addRoad(pts, 15, theme.road);
    addBarriers(pts, 15, theme);
    addCheckpoints(pts);

    if (theme.decor === 'city') addCityDecor(pts);
    else {
      addRockDecor(pts);
      addMounds(pts);
    }

    var d = new THREE.Vector3().subVectors(pts[1], pts[0]);
    startPos.set(pts[0].x, 0, pts[0].z);
    startAngle = Math.atan2(d.x, d.z);

    state.trackId = trackId;
  }

  /* ------------------------------------------------------------------ *
   * Car — physics body, raycast vehicle, procedural low-poly model
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
      if (w.geometry) w.geometry.dispose();
      if (w.material) w.material.dispose();
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

  function rimMaterial(rim) {
    if (rim === 1) return new THREE.MeshStandardMaterial({ color: 0xd8b45a, metalness: 0.95, roughness: 0.25 });
    if (rim === 2) return new THREE.MeshStandardMaterial({ color: 0x1b1f27, metalness: 0.6, roughness: 0.45 });
    return new THREE.MeshStandardMaterial({ color: 0xc9d3e0, metalness: 0.9, roughness: 0.2 });
  }

  function buildCar(cfg) {
    clearCar();

    var shape = CAR_SHAPES[cfg.id] || CAR_SHAPES.vortex_gt;
    var half = shape.half;

    /* ---- physics ---- */
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

    /* ---- visuals ---- */
    carGroup = new THREE.Group();

    var paintColor = new THREE.Color(cfg.color || '#22d3ee');
    var paint = new THREE.MeshStandardMaterial({
      color: paintColor,
      roughness: cfg.finish === 'matte' ? 0.9 : (cfg.finish === 'metallic' ? 0.22 : 0.38),
      metalness: cfg.finish === 'metallic' ? 0.9 : 0.35
    });
    var glass = new THREE.MeshStandardMaterial({ color: 0x0b1220, roughness: 0.12, metalness: 0.8 });
    var dark = new THREE.MeshStandardMaterial({ color: 0x14181f, roughness: 0.7, metalness: 0.4 });

    var body = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 2, half[1] * 2, half[2] * 2), paint);
    body.castShadow = true;
    body.receiveShadow = true;
    carGroup.add(body);

    var cabin = new THREE.Mesh(
      new THREE.BoxGeometry(shape.cabin[0] * 2, shape.cabin[1] * 2, shape.cabin[2] * 2),
      glass
    );
    cabin.position.set(0, shape.roofY * 0.72, shape.cabinZ);
    cabin.castShadow = true;
    carGroup.add(cabin);

    if (shape.wing) {
      var wing = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 1.7, 0.08, 0.42), dark);
      wing.position.set(0, half[1] + 0.28, -half[2] + 0.25);
      carGroup.add(wing);

      var stalkGeo = new THREE.BoxGeometry(0.08, 0.28, 0.08);
      for (var w2 = 0; w2 < 2; w2++) {
        var stalk = new THREE.Mesh(stalkGeo, dark);
        stalk.position.set(w2 === 0 ? 0.5 : -0.5, half[1] + 0.14, -half[2] + 0.25);
        carGroup.add(stalk);
      }
    }

    var skirt = new THREE.Mesh(new THREE.BoxGeometry(half[0] * 2.04, 0.12, half[2] * 1.6), dark);
    skirt.position.set(0, -half[1] * 0.72, 0);
    carGroup.add(skirt);

    scene.add(carGroup);

    /* wheels — positioned every frame from the raycast suspension */
    var rim = rimMaterial(cfg.rim);
    var tyre = new THREE.MeshStandardMaterial({ color: 0x0d0f13, roughness: 0.95, metalness: 0.05 });

    for (var i = 0; i < 4; i++) {
      var wheel = new THREE.Group();

      var tyreGeo = new THREE.CylinderGeometry(shape.wheelR, shape.wheelR, 0.3, 18);
      tyreGeo.rotateZ(Math.PI / 2);
      var tyreMesh = new THREE.Mesh(tyreGeo, tyre);
      tyreMesh.castShadow = true;
      wheel.add(tyreMesh);

      var rimGeo = new THREE.CylinderGeometry(shape.wheelR * 0.55, shape.wheelR * 0.55, 0.32, 12);
      rimGeo.rotateZ(Math.PI / 2);
      var rimMesh = new THREE.Mesh(rimGeo, rim);
      wheel.add(rimMesh);

      if (cfg.rim === 2) {
        var spokeGeo = new THREE.BoxGeometry(0.34, shape.wheelR * 1.05, 0.08);
        for (var sp = 0; sp < 2; sp++) {
          var spoke = new THREE.Mesh(spokeGeo, rim);
          spoke.rotation.x = sp === 0 ? 0 : Math.PI / 2;
          wheel.add(spoke);
        }
      }

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

    input.throttle = 0;
    input.brake = 0;
    input.steer = 0;
    input.handbrake = 0;
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

    /* steering lock tightens as speed rises — keeps high-speed runs stable */
    var lock = Math.max(0.13, 0.58 - speed * 0.011);
    var steer = input.steer * lock;
    vehicle.setSteeringValue(steer, 0);
    vehicle.setSteeringValue(steer, 1);

    /* rear-wheel drive */
    var engine = cfg.engineForce * ENGINE_SCALE;
    var force = 0;
    var frontBrake = 0;

    if (input.throttle > 0 && fwdSpeed < cfg.topSpeed) {
      force = engine * input.throttle;
    } else if (input.brake > 0) {
      if (fwdSpeed > 1.2) {
        force = 0;
        frontBrake = 60 * input.brake;
      } else {
        force = -engine * 0.5 * input.brake;
      }
    }

    vehicle.applyEngineForce(force, 2);
    vehicle.applyEngineForce(force, 3);
    vehicle.applyEngineForce(0, 0);
    vehicle.applyEngineForce(0, 1);

    vehicle.setBrake(frontBrake, 0);
    vehicle.setBrake(frontBrake, 1);

    var handbrake = input.handbrake ? 95 : 0;
    vehicle.setBrake(handbrake, 2);
    vehicle.setBrake(handbrake, 3);

    /* handbrake breaks rear lateral grip — that is the drift */
    var rearSlip = input.handbrake ? cfg.frictionSlip * 0.42 : cfg.frictionSlip;
    vehicle.wheelInfos[2].frictionSlip = rearSlip;
    vehicle.wheelInfos[3].frictionSlip = rearSlip;

    state.drifting = (speed > 9 && Math.abs(latSpeed) > 3.4) ? 1 : 0;

    /* flipped? put it back on its wheels after a moment */
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

    /* fell off the world? respawn at the start line */
    if (chassisBody.position.y < -8) {
      resetToStart();
    }

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
        lapTime: lapTime
      });
      return;
    }

    state.lapStart = now;
    post('lap', { lap: state.lap + 1, lapTime: lapTime, bestLap: state.bestLap });
  }

  function updateRace(dt) {
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
      .addScaledVector(vBack, 9.5);
    vDesired.y += 3.7;

    var k = 1 - Math.exp(-dt * 5.5);
    camPos.lerp(vDesired, k);
    camera.position.copy(camPos);

    camLook.set(chassisBody.position.x, chassisBody.position.y + 1.2, chassisBody.position.z)
      .addScaledVector(vFwd, 6);
    camera.lookAt(camLook);

    var speed = chassisBody.velocity.length();
    var fov = Math.min(82, 62 + speed * 0.22);
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

  function animate(now) {
    requestAnimationFrame(animate);

    var dt = (now - last) / 1000;
    last = now;
    if (dt > 0.1) dt = 0.1;

    if (state.phase === 'countdown') {
      tickCountdown(dt);
      stepPhysics(dt);
    } else if (state.phase === 'racing' || state.phase === 'finished') {
      stepPhysics(dt);
      updateRace(dt);
    }

    updateVisuals();
    updateCamera(dt);

    hudTimer += dt;
    if (hudTimer >= 0.1) {
      hudTimer = 0;
      var speedKmh = chassisBody ? Math.round(chassisBody.velocity.length() * 3.6) : 0;
      post('hud', {
        speed: speedKmh,
        lap: Math.min(state.lap + 1, LAPS),
        laps: LAPS,
        lapTime: state.phase === 'racing' ? (performance.now() / 1000 - state.lapStart) : 0,
        bestLap: state.bestLap,
        drifting: state.drifting,
        gear: speedKmh < 1 ? 'N' : String(Math.min(6, 1 + Math.floor(speedKmh / 34)))
      });
    }

    renderer.render(scene, camera);
  }

  /* ------------------------------------------------------------------ *
   * Setup + public API
   * ------------------------------------------------------------------ */
  function applySetup() {
    if (!state.trackId || !state.car) return;

    /* rebuild the world from scratch for this track + car pairing */
    clearTrack();
    buildTrack(state.trackId);
    buildCar(state.car);

    camPos.set(startPos.x, 8, startPos.z - 14);
    state.phase = 'idle';
    post('loaded', { track: state.trackId, car: state.car.id });
  }

  window.__AP = {
    /* one call from Flutter: car config + track together */
    setup: function (carCfg, trackId) {
      state.car = carCfg;
      state.trackId = trackId;
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
      state.phase = 'countdown';
      state.countdown = 3.2;
      state.lastCountShown = -1;
      post('countdown', { value: 3 });
    },
    snapshot: function () {
      return JSON.stringify({
        phase: state.phase,
        lap: state.lap,
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
