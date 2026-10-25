/* Not loaded by the play prototypes. Future integration seam, not an ad SDK. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.KidsRemote=api;})(globalThis,function(){'use strict';
const MAX_BYTES=65536;
function bytes(b64){if(typeof b64!=='string'||b64.length>MAX_BYTES||!/^[A-Za-z0-9+/]*={0,2}$/.test(b64))throw Error('Invalid base64');const raw=atob(b64);return Uint8Array.from(raw,c=>c.charCodeAt(0));}
async function verifyEnvelope(envelope,pinnedPublicKey,cryptoProvider=globalThis.crypto){
 try{
  if(!cryptoProvider?.subtle||!envelope||envelope.algorithm!=='RS256'||typeof pinnedPublicKey!=='string')return {verified:false,config:null,reason:'Missing cryptographic prerequisites'};
  const payload=bytes(envelope.payload_b64),signature=bytes(envelope.signature_b64);
  if(payload.byteLength>32768||signature.byteLength>1024||signature.byteLength<256)throw Error('Invalid envelope size');
  const keyData=pinnedPublicKey.replace(/-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\s/g,'');
  const key=await cryptoProvider.subtle.importKey('spki',bytes(keyData),{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['verify']);
  const valid=await cryptoProvider.subtle.verify({name:'RSASSA-PKCS1-v1_5'},key,signature,payload);
  if(!valid)return {verified:false,config:null,reason:'Invalid signature'};
  const config=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(payload));
  if(!config||typeof config!=='object'||Array.isArray(config))throw Error('Invalid payload');
  return {verified:true,config,reason:'Verified signature; policy eligibility still required'};
 }catch(_){return {verified:false,config:null,reason:'Malformed or unverifiable configuration'};}
}
async function fetchVerifiedPolicy(endpoint,pinnedPublicKey,options={}){
 // No endpoint is compiled into any browser prototype. Hosting is NOT deployed.
 const fail=reason=>({verified:false,config:null,reason});
 if(!endpoint)return fail('Remote configuration disabled');
 let url;try{url=new URL(endpoint);}catch(_){return fail('Invalid endpoint');}
 if(url.protocol!=='https:'||url.username||url.password)return fail('HTTPS-only endpoint required');
 const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),Math.min(options.timeoutMs||1500,3000));
 try{
  const response=await (options.fetchImpl||fetch)(url.toString(),{method:'GET',credentials:'omit',redirect:'error',referrerPolicy:'no-referrer',cache:'no-store',signal:controller.signal});
  if(!response.ok)return fail('Configuration service unavailable');
  if(Number(response.headers.get('content-length'))>MAX_BYTES)return fail('Response too large');
  const text=await response.text();if(text.length>MAX_BYTES)return fail('Response too large');
  return await verifyEnvelope(JSON.parse(text),pinnedPublicKey,options.cryptoProvider||globalThis.crypto);
 }catch(_){return fail('Fetch or verification failed; ads must remain off');}finally{clearTimeout(timeout);}
}
return {verifyEnvelope,fetchVerifiedPolicy};
});
