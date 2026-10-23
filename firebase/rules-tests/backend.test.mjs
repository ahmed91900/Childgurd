import {before,after,test} from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp as adminApp,deleteApp as deleteAdminApp} from 'firebase-admin/app';
import {getAuth as adminAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {initializeApp,deleteApp} from 'firebase/app';
import {getAuth,connectAuthEmulator,signInWithEmailAndPassword,signInAnonymously,getIdToken} from 'firebase/auth';
import {getFunctions,connectFunctionsEmulator,httpsCallable} from 'firebase/functions';

let admin,db,parent,child,second,bad,guest;
const apps=[];
function client(name){
  const app=initializeApp({apiKey:'demo-key',appId:'demo-app',projectId:'demo-kidsafe'},name);apps.push(app);
  const auth=getAuth(app);connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});
  const functions=getFunctions(app,'us-central1');connectFunctionsEmulator(functions,'127.0.0.1',5001);
  return {auth,call:(name,data)=>httpsCallable(functions,name)(data)};
}
before(async()=>{
  admin=adminApp({projectId:'demo-kidsafe'},'backend-tests');db=getFirestore(admin);
  const auth=adminAuth(admin);
  try{await auth.deleteUser('integration-parent');}catch(_){}
  await auth.createUser({uid:'integration-parent',email:'parent@example.test',password:'TestOnlyPassword123!',emailVerified:true});
  parent=client('parent');await signInWithEmailAndPassword(parent.auth,'parent@example.test','TestOnlyPassword123!');
  child=client('child');second=client('second');bad=client('bad');guest=client('guest');
  for(const c of [child,second,bad])await signInAnonymously(c.auth);
});
after(async()=>{await Promise.all(apps.map(deleteApp));await deleteAdminApp(admin);});

test('callable endpoints reject unauthenticated and anonymous parent actions',async()=>{
  await assert.rejects(guest.call('createPairing',{child:'child'}),{code:'functions/permission-denied'});
  await assert.rejects(child.call('registerParent'),{code:'functions/permission-denied'});
});
test('verified parent registration creates server-owned account permission',async()=>{
  await parent.call('registerParent');
  assert.equal((await db.doc('parentAccounts/integration-parent').get()).data().active,true);
  await db.doc('families/integration-parent').set({owner:'integration-parent'});
  await db.doc('families/integration-parent/children/child').set({profile:{id:'child',name:'',age:8},custom:[],videos:[],decisions:{}});
});
test('pairing uses a one-time scoped code and rejects replay',async()=>{
  const {data}=await parent.call('createPairing',{child:'child'});
  assert.equal(data.code.length,16);assert.equal(data.expiresInSeconds,600);
  const joined=await child.call('redeemPairing',{code:data.code});
  assert.deepEqual(joined.data,{family:'integration-parent',child:'child'});
  const uid=child.auth.currentUser.uid;
  assert.equal((await db.doc(`devices/${uid}`).get()).data().active,true);
  await assert.rejects(second.call('redeemPairing',{code:data.code}),{code:'functions/permission-denied'});
});
test('new pairing revokes the previous child device',async()=>{
  const {data}=await parent.call('createPairing',{child:'child'});
  await second.call('redeemPairing',{code:data.code});
  assert.equal((await db.doc(`devices/${child.auth.currentUser.uid}`).get()).data().active,false);
  assert.equal((await db.doc(`devices/${second.auth.currentUser.uid}`).get()).data().active,true);
});
test('invalid pairing attempts consume the persistent rate budget',async()=>{
  for(let i=0;i<5;i++)await assert.rejects(bad.call('redeemPairing',{code:'invalid-test-code'}),{code:'functions/permission-denied'});
  await assert.rejects(bad.call('redeemPairing',{code:'invalid-test-code'}),{code:'functions/resource-exhausted'});
});
test('advertising changes require an owner claim; on/off state persists',async()=>{
  await assert.rejects(parent.call('configureAds',{enabled:true,provider:'image',url:'https://example.com/approved.png'}),{code:'functions/permission-denied'});
  await adminAuth(admin).setCustomUserClaims('integration-parent',{owner:true});
  await getIdToken(parent.auth.currentUser,true);
  await parent.call('configureAds',{enabled:true,provider:'image',url:'https://example.com/approved.png',title:'Test'});
  assert.equal((await db.doc('publicConfig/monetization').get()).data().enabled,true);
  await parent.call('configureAds',{enabled:false,provider:'off'});
  assert.equal((await db.doc('publicConfig/monetization').get()).data().enabled,false);
});
test('revoked child cannot register a push token',async()=>{
  await assert.rejects(child.call('registerPushToken',{token:'emulator-only-token'}),{code:'functions/permission-denied'});
  await second.call('registerPushToken',{token:'emulator-only-token'});
  assert.deepEqual((await db.doc(`privatePush/${second.auth.currentUser.uid}`).get()).data().tokens,['emulator-only-token']);
});
test('account deletion revokes devices, removes online data and tombstones registration',async()=>{
  await parent.call('deleteFamily');
  assert.equal((await db.doc('families/integration-parent').get()).exists,false);
  assert.equal((await db.doc(`devices/${second.auth.currentUser.uid}`).get()).exists,false);
  assert.equal((await db.doc('parentAccounts/integration-parent').get()).data().active,false);
  await assert.rejects(adminAuth(admin).getUser('integration-parent'),{code:'auth/user-not-found'});
});
