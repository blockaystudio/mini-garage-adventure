/* Shared prototype foundation. No network, analytics, advertisements or purchases. */
(function (root, factory) {
  const api = factory(); if (typeof module === 'object' && module.exports) module.exports = api;
  else root.KidsCore = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const clone = value => JSON.parse(JSON.stringify(value));
  const clamp = (n, lo, hi) => Math.max(lo, Math.min(hi, n));
  const plain = x => x !== null && typeof x === 'object' && !Array.isArray(x);
  const safeNumber = (x, fallback, lo=0, hi=1e7) => Number.isFinite(x) ? clamp(x,lo,hi) : fallback;
  const escapeHTML = s => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  class LocalSave {
    constructor(game, defaults, normalizer, storage) {
      this.key = `kidslab.v1.${game}`; this.game = game; this.defaults = defaults;
      this.normalize = normalizer || (v => v); this.warning = ''; this.storage = storage;
      if (storage === undefined) { try { this.storage = globalThis.localStorage; } catch (_) { this.storage = null; } }
      this.memory = null; this.data = this.load();
    }
    parse(raw) {
      if (!raw || raw.length > 150000) return null;
      const obj = JSON.parse(raw);
      if (!plain(obj) || obj.schema !== 1 || obj.game !== this.game || !plain(obj.data)) return null;
      return this.normalize(obj.data);
    }
    load() {
      if (!this.storage) { this.warning = 'Progress lasts for this visit only: browser saving is unavailable.'; return clone(this.defaults); }
      for (const key of [this.key, this.key+'.backup']) {
        try { const result = this.parse(this.storage.getItem(key)); if (result) {
          if (key.endsWith('.backup')) this.warning = 'Recovered the previous saved visit.';
          return result;
        }} catch (_) { this.warning = 'The previous save could not be read. A safe save was used.'; }
      }
      return clone(this.defaults);
    }
    save(data) {
      this.data = this.normalize(clone(data));
      const next = JSON.stringify({schema:1,game:this.game,data:this.data}); this.memory = next;
      if (!this.storage) return false;
      try {
        const previous = this.storage.getItem(this.key);
        try { if (this.parse(previous)) this.storage.setItem(this.key+'.backup',previous); } catch (_) {}
        this.storage.setItem(this.key,next); return true;
      } catch (_) { this.warning = 'Your browser cannot save right now. This visit still works.'; return false; }
    }
    reset() {
      try { this.storage?.removeItem(this.key); this.storage?.removeItem(this.key+'.backup'); } catch (_) {}
      this.data=clone(this.defaults); return this.data;
    }
  }
  // Decision engine only: compiled browser builds CANNOT serve ads, regardless of server flags.
  const BUILD_CAPABILITIES = Object.freeze({adAdapterIncluded:false,reviewedAds:false,platform:'web',maxDailyAds:2,maxRollout:25});
  const OFF = Object.freeze({allowed:false,reason:'Ads disabled'});
  function adDecision(config, context={}, capabilities=BUILD_CAPABILITIES) {
    const no = reason => ({allowed:false,reason});
    if (!capabilities.adAdapterIncluded || !capabilities.reviewedAds) return no('No reviewed ad capability in this build');
    if (!plain(config) || context.signatureVerified!==true) return no('Unverified configuration');
    if (config.schema_version!==1 || !Number.isInteger(config.revision) || config.revision<1) return no('Invalid schema or revision');
    const now=context.now;
    if (!Number.isFinite(now) || !Number.isFinite(config.expires_at) || config.expires_at<=now || !Number.isFinite(config.issued_at) || config.issued_at>now+60) return no('Expired or invalid configuration');
    if (config.revision < (context.minimumRevision || 0)) return no('Rollback blocked');
    if (config.kill_switch!==false) return no('Global kill switch');
    if (!plain(config.apps) || !plain(config.apps[context.game])) return no('Missing app policy');
    const p=config.apps[context.game]?.[capabilities.platform];
    if (!plain(p) || p.enabled!==true || p.reviewed_build!==context.build) return no('Not enabled for this reviewed build');
    if (context.privacyEligible!==true) return no('Privacy requirements not met');
    if (!Number.isInteger(context.installDays) || context.installDays<Math.max(1, safeNumber(p.min_install_days,7,1,365))) return no('New-player protection');
    if (!Number.isInteger(context.activeDays) || context.activeDays<Math.max(1,safeNumber(p.min_active_days,3,1,30))) return no('Not enough return visits');
    if (context.isFirstSession!==false) return no('First session protected');
    if (context.isNaturalBreak!==true) return no('Gameplay may not be interrupted');
    if (!Number.isFinite(context.sessionMinutes) || context.sessionMinutes<safeNumber(p.min_session_minutes,5,5,240)) return no('Too early in session');
    if (!Number.isFinite(context.minutesSinceAd) || context.minutesSinceAd<safeNumber(p.min_minutes_between,15,15,1440)) return no('Spacing protection');
    const cap=p.daily_cap, rollout=p.rollout_percent;
    if (!Number.isInteger(cap) || cap<1 || cap>capabilities.maxDailyAds) return no('Invalid daily cap');
    if (!Number.isFinite(rollout) || rollout<0 || rollout>capabilities.maxRollout) return no('Invalid rollout');
    if (!Number.isInteger(context.adsToday) || context.adsToday<0 || context.adsToday>=cap) return no('Daily limit');
    if (!Number.isFinite(context.localBucket) || context.localBucket<0 || context.localBucket>=100 || context.localBucket>=rollout) return no('Ad-free comparison group');
    return {allowed:true,reason:'Eligible for reviewed placement',dailyCap:cap};
  }
  const PETS = [
    {id:'clover',name:'Clover',trait:'A garden-loving daydreamer',favorite:'berry',color:'#B8DEA6',ears:'leaf'},
    {id:'mochi',name:'Mochi',trait:'A little music maker',favorite:'music',color:'#CFBDF0',ears:'long'},
    {id:'pip',name:'Pip',trait:'Always ready to explore',favorite:'ball',color:'#F4C774',ears:'round'}
  ];
  const DECOR = ['plant','rug','lamp','cushion','stars','table'];
  const petDefaults={pet:null,decor:[],actions:[],memories:[],visits:0,completed:0,reducedMotion:false};
  function normalizePet(d) {
    const value=clone(petDefaults); value.pet=PETS.some(p=>p.id===d.pet)?d.pet:null;
    value.decor=Array.isArray(d.decor)?d.decor.filter(x=>plain(x)&&DECOR.includes(x.kind)).slice(0,18).map((x,i)=>({id:'d'+i,kind:x.kind,x:safeNumber(x.x,35,4,91),y:safeNumber(x.y,60,28,88)})):[];
    value.actions=Array.isArray(d.actions)?[...new Set(d.actions.filter(x=>['berry','music','ball'].includes(x)))]:[];
    value.memories=Array.isArray(d.memories)?d.memories.filter(x=>plain(x)&&PETS.some(p=>p.id===x.pet)).slice(-8).map(x=>({pet:x.pet,items:safeNumber(x.items,0,0,18),title:['A cozy beginning','A happy little home','Another lovely visit'].includes(x.title)?x.title:'A cozy beginning'})):[];
    value.visits=Math.floor(safeNumber(d.visits,0));value.completed=Math.floor(safeNumber(d.completed,0));value.reducedMotion=d.reducedMotion===true;return value;
  }
  const TIRES={road:{label:'Road',radius:21,maxSpeed:245,grip:.76},trail:{label:'Trail',radius:29,maxSpeed:225,grip:1.12},giant:{label:'Giant',radius:37,maxSpeed:202,grip:1.3}};
  const TRACKS={meadow:['flat','ramp','flat','bumps'],dunes:['ramp','bumps','ramp','bumps']};
  const garageDefaults={tires:'trail',suspension:'soft',paint:'orange',track:'meadow',custom:['flat','ramp','bumps','flat'],finishes:0,visits:0,reducedMotion:false};
  function normalizeGarage(d){return {tires:TIRES[d.tires]?d.tires:'trail',suspension:['soft','firm'].includes(d.suspension)?d.suspension:'soft',paint:['orange','cyan','purple','lime'].includes(d.paint)?d.paint:'orange',track:['meadow','dunes','custom'].includes(d.track)?d.track:'meadow',custom:Array.isArray(d.custom)&&d.custom.length===4?d.custom.map(x=>['flat','ramp','bumps'].includes(x)?x:'flat'):clone(garageDefaults.custom),finishes:Math.floor(safeNumber(d.finishes,0)),visits:Math.floor(safeNumber(d.visits,0)),reducedMotion:d.reducedMotion===true};}
  function terrain(x, track){
    let h=330; for(let i=0;i<4;i++){const p=(x-(220+i*360))/260;if(p<=0||p>=1)continue;
      if(track[i]==='ramp')h-=78*Math.sin(Math.PI*p)**2;
      else if(track[i]==='bumps')h-=30*Math.sin(Math.PI*p*3)**2;
    }return h;
  }
  function initialCar(parts,track){return {x:70,y:terrain(70,track)-TIRES[parts.tires].radius-17,vx:0,vy:0,angle:0,elapsed:0,finished:false,airborne:false};}
  // Forgiving arcade model, not an engineering model. Larger tires trade speed for terrain handling.
  function stepCar(s,dt,throttle,brake,parts,track){
    if(s.finished)return {...s};dt=clamp(dt,0,.035);const t=TIRES[parts.tires];const n={...s};
    const slope=(terrain(s.x+8,track)-terrain(s.x-8,track))/16;
    const rough=Math.abs(slope);const accel=throttle?155*t.grip:0;
    n.vx=clamp(s.vx+(accel-22-s.vx*.085+Math.min(0,slope)*85/(t.radius/21)-(brake?360:0))*dt,0,t.maxSpeed/(1+rough*.15/t.grip));
    n.x=s.x+n.vx*dt;n.elapsed=s.elapsed+dt;
    const target=terrain(n.x,track)-t.radius-17;
    n.vy+=650*dt;n.y+=n.vy*dt;
    if(n.y>=target){if(s.airborne&&n.vy>80)n.vx*=parts.suspension==='soft'?.95:.82;n.y=target;n.vy=Math.min(0,slope*n.vx);n.airborne=false;}else n.airborne=target-n.y>4;
    const groundAngle=Math.atan2(terrain(n.x+35,track)-terrain(n.x-35,track),70);
    n.angle=s.angle+(groundAngle-s.angle)*Math.min(1,dt*(parts.suspension==='soft'?8:15));
    if(n.x>=1810){n.finished=true;n.vx=0;}
    return n;
  }
  const PUZZLES=[
    {name:'A little reflection',concept:'Light moves in straight lines until a mirror changes its direction.',start:[0,3],goal:[8,1],mirrors:[[4,3],[4,1]],solution:['/','/'],initial:['\\','/']},
    {name:'Take the lower path',concept:'Turning a mirror changes the direction of the reflected light.',start:[0,1],goal:[8,4],mirrors:[[2,1],[2,4]],solution:['\\','\\'],initial:['/','/']},
    {name:'The long way around',concept:'Several mirrors can guide light around a winding path.',start:[0,1],goal:[8,0],mirrors:[[6,1],[6,4],[2,4],[2,0]],solution:['\\','/','\\','/'],initial:['/','\\','/','\\']}
  ];
  function traceLight(p,orientations){
    let [x,y]=p.start,dx=1,dy=0;const path=[[x,y]],seen=new Set();let success=false,loop=false;const touched=[];
    for(let i=0;i<256;i++){
      if(x===p.goal[0]&&y===p.goal[1]){success=true;break;}
      const key=[x,y,dx,dy].join(',');if(seen.has(key)){loop=true;break;}seen.add(key);
      const m=p.mirrors.findIndex(v=>v[0]===x&&v[1]===y);
      if(m>=0){touched.push(m);if(orientations[m]==='/')[dx,dy]=[-dy,-dx];else if(orientations[m]==='\\')[dx,dy]=[dy,dx];}
      x+=dx;y+=dy;path.push([x,y]);if(x<0||x>8||y<0||y>5)break;
    }return {path,success,loop,touched};
  }
  const labDefaults={puzzle:0,orientations:PUZZLES.map(p=>p.initial.slice()),solved:[],attempts:[0,0,0],visits:0,reducedMotion:false};
  function normalizeLab(d){return {puzzle:Math.floor(safeNumber(d.puzzle,0,0,2)),orientations:PUZZLES.map((p,i)=>p.initial.map((v,j)=>['/','\\'].includes(d.orientations?.[i]?.[j])?d.orientations[i][j]:v)),solved:Array.isArray(d.solved)?[...new Set(d.solved.filter(i=>Number.isInteger(i)&&i>=0&&i<3))]:[],attempts:PUZZLES.map((_,i)=>Math.floor(safeNumber(d.attempts?.[i],0))),visits:Math.floor(safeNumber(d.visits,0)),reducedMotion:d.reducedMotion===true};}
  return {clone,clamp,plain,safeNumber,escapeHTML,LocalSave,BUILD_CAPABILITIES,adDecision,OFF,PETS,DECOR,petDefaults,normalizePet,TIRES,TRACKS,garageDefaults,normalizeGarage,terrain,initialCar,stepCar,PUZZLES,traceLight,labDefaults,normalizeLab};
});
