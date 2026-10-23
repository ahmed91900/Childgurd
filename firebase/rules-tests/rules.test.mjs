import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc, updateDoc, serverTimestamp, collectionGroup, query, where, getDocs} from 'firebase/firestore';

let env;
const claims={email_verified:true,firebase:{sign_in_provider:'password'}};
const profile={id:'child',name:'Learner',age:8,difficulty:1,minutes:30,requiredTasks:2,enabled:['math'],adsAllowed:false};
const config={profile,custom:[],videos:[],decisions:{}};
before(async()=>{
  env=await initializeTestEnvironment({projectId:'demo-kidsafe',firestore:{host:'127.0.0.1',port:8080,rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8')}});
});
after(async()=>{await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    await setDoc(doc(db,'parentAccounts/parentA'),{active:true});
    await setDoc(doc(db,'parentAccounts/parentB'),{active:true});
    await setDoc(doc(db,'families/parentA'),{owner:'parentA'});
    await setDoc(doc(db,'families/parentB'),{owner:'parentB'});
    await setDoc(doc(db,'families/parentA/children/child'),{...config,deviceId:'deviceA'});
    await setDoc(doc(db,'families/parentB/children/child'),{...config,deviceId:'deviceB'});
    await setDoc(doc(db,'devices/deviceA'),{family:'parentA',child:'child',active:true});
  });
});
const parent=()=>env.authenticatedContext('parentA',claims).firestore();
const device=()=>env.authenticatedContext('deviceA',{firebase:{sign_in_provider:'anonymous'}}).firestore();
const progress=()=>({family:'parentA',child:'child',date:'2026-10-23',device:'deviceA',done:['library:math'],points:10,seconds:10,bonus:0,updatedAt:serverTimestamp()});

test('unauthenticated users cannot read a child or ad config',async()=>{
  const db=env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db,'families/parentA/children/child')));
  await assertFails(getDoc(doc(db,'publicConfig/monetization')));
});
test('verified parent reads own family and cannot read another family',async()=>{
  await assertSucceeds(getDoc(doc(parent(),'families/parentA/children/child')));
  await assertFails(getDoc(doc(parent(),'families/parentB/children/child')));
});
test('unverified and unregistered parent accounts are denied',async()=>{
  await assertFails(getDoc(doc(env.authenticatedContext('parentA',{email_verified:false,firebase:{sign_in_provider:'password'}}).firestore(),'families/parentA/children/child')));
  await assertFails(setDoc(doc(env.authenticatedContext('parentC',claims).firestore(),'families/parentC'),{owner:'parentC'}));
});
test('parent can update a child configuration without changing server device link',async()=>{
  await assertSucceeds(updateDoc(doc(parent(),'families/parentA/children/child'),{'profile.minutes':20}));
  await assertFails(updateDoc(doc(parent(),'families/parentA/children/child'),{deviceId:'attacker'}));
});
test('parent cannot forge another family or server fields',async()=>{
  await assertFails(setDoc(doc(parent(),'families/parentB'),{owner:'parentA'}));
  await assertFails(updateDoc(doc(parent(),'families/parentA/children/child'),{owner:true}));
});
test('paired child reads its own profile, not siblings or parent records',async()=>{
  await assertSucceeds(getDoc(doc(device(),'families/parentA/children/child')));
  await assertFails(getDoc(doc(device(),'families/parentB/children/child')));
  await assertFails(getDoc(doc(device(),'families/parentA')));
});
test('child cannot edit tasks, pairing links, or advertising flags',async()=>{
  await assertFails(updateDoc(doc(device(),'families/parentA/children/child'),{'profile.minutes':180}));
  await assertFails(setDoc(doc(device(),'devices/deviceA'),{family:'parentB',child:'child',active:true}));
  await assertFails(setDoc(doc(device(),'publicConfig/monetization'),{enabled:true}));
});
test('child progress accepts bounded data and enforces monotonic counters',async()=>{
  const ref=doc(device(),'families/parentA/children/child/progress/2026-10-23');
  await assertSucceeds(setDoc(ref,progress()));
  await assertSucceeds(updateDoc(ref,{seconds:20,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{seconds:1,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{done:[],updatedAt:serverTimestamp()}));
});
test('child cannot forge family, date, identity, rewards or data fields',async()=>{
  const ref=doc(device(),'families/parentA/children/child/progress/2026-10-23');
  for(const extra of [{family:'parentB'},{device:'someoneElse'},{date:'2099-01-01'},{points:1000000},{seconds:-1},{extra:'data'}]){
    await assertFails(setDoc(ref,{...progress(),...extra}));
  }
});
test('revoked devices lose access immediately',async()=>{
  await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'devices/deviceA'),{active:false}));
  await assertFails(getDoc(doc(device(),'families/parentA/children/child')));
  await assertFails(setDoc(doc(device(),'families/parentA/children/child/progress/2026-10-23'),progress()));
});
test('deleting a family disables child access even if a stale link remains',async()=>{
  const {deleteDoc}=await import('firebase/firestore');
  await env.withSecurityRulesDisabled(c=>deleteDoc(doc(c.firestore(),'families/parentA')));
  await assertFails(getDoc(doc(device(),'families/parentA/children/child')));
});
test('time requests cannot self-approve or grant arbitrary time',async()=>{
  const ref=doc(device(),'families/parentA/children/child/requests/123');
  const r={id:'123',child:'child',family:'parentA',device:'deviceA',date:'2026-10-23',status:'pending',minutes:10,updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(ref,r));
  await assertFails(setDoc(ref,{...r,status:'approved'}));
  await assertFails(setDoc(ref,{...r,minutes:100}));
});
test('parent dashboard query stays scoped to the validated family',async()=>{
  await assertSucceeds(setDoc(doc(device(),'families/parentA/children/child/progress/2026-10-23'),progress()));
  await assertSucceeds(getDocs(query(collectionGroup(parent(),'progress'),where('family','==','parentA'))));
  await assertFails(getDocs(query(collectionGroup(parent(),'progress'),where('family','==','parentB'))));
});
test('pairing secrets, token collections and owner roles are never client-readable',async()=>{
  for(const path of ['pairings/secret','privatePush/parentA','pairingAttempts/deviceA','parentAccounts/parentA']){
    await assertFails(getDoc(doc(parent(),path)));
    await assertFails(setDoc(doc(parent(),path),{active:true,owner:true}));
  }
});
