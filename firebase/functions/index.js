'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onDocumentWritten, onDocumentCreated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const {getMessaging} = require('firebase-admin/messaging');
const {randomBytes, createHash} = require('node:crypto');
initializeApp();
const db = getFirestore();
const options = {region:'us-central1', maxInstances:10};
function parent(r) {
  if (!r.auth || r.auth.token.email_verified !== true || r.auth.token.firebase?.sign_in_provider === 'anonymous')
    throw new HttpsError('permission-denied','Verified parent account required.');
  return r.auth.uid;
}
function text(v,n) {
  if (typeof v !== 'string' || !v.length || v.length>n) throw new HttpsError('invalid-argument','Invalid input.');
  return v;
}
exports.registerParent=onCall(options,async r=>{
  const uid=parent(r),user=await getAuth().getUser(uid);
  if(!user.emailVerified)throw new HttpsError('permission-denied','Verify your email.');
  await db.runTransaction(async tx=>{
    const ref=db.doc(`parentAccounts/${uid}`),snap=await tx.get(ref);
    if(snap.data()?.deleting)throw new HttpsError('failed-precondition','Account deletion in progress.');
    tx.set(ref,{active:true});
  });return {ok:true};
});
exports.deleteFamily=onCall({...options,timeoutSeconds:120},async r=>{
  const uid=parent(r);
  if(Date.now()/1000-(r.auth.token.auth_time||0)>300)throw new HttpsError('failed-precondition','Sign in again before deleting.');
  await db.doc(`parentAccounts/${uid}`).set({active:false,deleting:true});
  const devices=await db.collection('devices').where('family','==',uid).get();
  for(const d of devices.docs){await d.ref.delete();await db.doc(`privatePush/${d.id}`).delete();}
  await db.recursiveDelete(db.doc(`families/${uid}`));
  const codes=await db.collection('pairings').where('family','==',uid).get();
  for(const d of codes.docs)await d.ref.delete();
  await db.doc(`privatePush/${uid}`).delete();
  await getAuth().deleteUser(uid);return {ok:true};
});
exports.createPairing = onCall(options,async r => {
  const family=parent(r), child=text(r.data?.child,100);
  if (!(await db.doc(`families/${family}/children/${child}`).get()).exists) throw new HttpsError('not-found','Create the profile first.');
  const code=randomBytes(12).toString('base64url');
  await db.doc(`pairings/${createHash('sha256').update(code).digest('hex')}`).create({family,child,used:false,expires:Timestamp.fromMillis(Date.now()+600000)});
  return {code,expiresInSeconds:600};
});
exports.redeemPairing = onCall(options,async r => {
  if (!r.auth || r.auth.token.firebase?.sign_in_provider!=='anonymous') throw new HttpsError('permission-denied','Child identity required.');
  const code=text(r.data?.code,100),uid=r.auth.uid,rate=db.doc(`pairingAttempts/${uid}`);
  // Invalid codes consume attempts too; the transaction is separate on purpose.
  await db.runTransaction(async tx => {
    const s=await tx.get(rate),d=s.data()||{},now=Date.now(),recent=d.start && now-d.start<600000;
    const attempts=recent?d.attempts+1:1;
    if(attempts>5)throw new HttpsError('resource-exhausted','Try again later.');
    tx.set(rate,{start:recent?d.start:now,attempts});
  });
  const ref=db.doc(`pairings/${createHash('sha256').update(code).digest('hex')}`);
  return db.runTransaction(async tx => {
    const s=await tx.get(ref),d=s.data();
    if(!d || d.used || d.expires.toMillis()<Date.now())throw new HttpsError('permission-denied','Invalid or expired pairing.');
    const childRef=db.doc(`families/${d.family}/children/${d.child}`),child=await tx.get(childRef);
    if(!child.exists)throw new HttpsError('not-found','Profile unavailable.');
    const previous=child.data().deviceId;
    if(previous && previous!==uid)tx.set(db.doc(`devices/${previous}`),{active:false},{merge:true});
    tx.update(ref,{used:true});tx.set(db.doc(`devices/${uid}`),{family:d.family,child:d.child,active:true});
    tx.update(childRef,{deviceId:uid});return {family:d.family,child:d.child};
  });
});
exports.registerPushToken = onCall(options,async r => {
  if(!r.auth)throw new HttpsError('unauthenticated','Sign in first.');
  const uid=r.auth.uid,token=text(r.data?.token,4096);
  if(r.auth.token.firebase?.sign_in_provider==='anonymous'){
    if(!(await db.doc(`devices/${uid}`).get()).data()?.active)throw new HttpsError('permission-denied','Pair the device first.');
  }else parent(r);
  await db.doc(`privatePush/${uid}`).set({tokens:FieldValue.arrayUnion(token)},{merge:true});return {ok:true};
});
async function notify(uid,type){
  if(process.env.FUNCTIONS_EMULATOR==='true')return;
  if(!uid)return;
  const ref=db.doc(`privatePush/${uid}`),data=(await ref.get()).data();
  if(!data?.tokens?.length || Date.now()-(data.lastSent||0)<30000)return;
  const tokens=data.tokens.slice(-10);await ref.update({lastSent:Date.now()});
  const result=await getMessaging().sendEachForMulticast({tokens,notification:{title:'KidSafe Launcher',body:'Your family has an update.'},data:{type}});
  const invalid=result.responses.map((r,i)=>!r.success && ['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(r.error?.code)?tokens[i]:null).filter(Boolean);
  if(invalid.length)await ref.update({tokens:FieldValue.arrayRemove(...invalid)});
}
exports.assignmentChanged=onDocumentWritten('families/{family}/children/{child}',async event=>{
  const a=event.data?.after.data(),b=event.data?.before.data();if(!a)return;
  if(['profile','custom','decisions','videos'].every(k=>JSON.stringify(a[k])===JSON.stringify(b?.[k])))return;
  await notify(a.deviceId,'assignment');
});
exports.timeRequested=onDocumentCreated('families/{family}/children/{child}/requests/{id}',e=>notify(e.params.family,'time-request'));
exports.configureAds=onCall(options,async r=>{
  if(r.auth?.token.owner!==true)throw new HttpsError('permission-denied','Owner access required.');
  const d=r.data||{},provider=d.provider;
  if(!['off','admob','image','video'].includes(provider))throw new HttpsError('invalid-argument','Invalid provider.');
  const value={enabled:d.enabled===true,provider,title:String(d.title||'').slice(0,80)};
  if(provider==='admob'){
    value.bannerId=text(d.bannerId,100);
    if(!/^ca-app-pub-\d+\/\d+$/.test(value.bannerId))throw new HttpsError('invalid-argument','Invalid AdMob unit.');
  }
  if(provider==='image'||provider==='video'){
    let url;try{url=new URL(text(d.url,2048));}catch(_){throw new HttpsError('invalid-argument','Invalid URL.');}
    if(url.protocol!=='https:'||url.username||url.password||(provider==='video'&&!url.pathname.toLowerCase().endsWith('.mp4')))throw new HttpsError('invalid-argument','HTTPS required.');
    value.url=url.toString();
  }
  await db.doc('publicConfig/monetization').set(value);return {ok:true};
});
