'use strict';
// Operator-only CLI: uses Application Default Credentials, never shipped in the APK.
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
async function main() {
  const [action, projectId, uid] = process.argv.slice(2);
  if (!projectId || !['grant-owner','revoke-owner','ads-off'].includes(action) || (action !== 'ads-off' && !uid)) {
    throw new Error('Usage: node owner-admin.cjs <grant-owner|revoke-owner|ads-off> PROJECT_ID [UID]');
  }
  initializeApp({projectId});
  if (action === 'ads-off') {
    await getFirestore().doc('publicConfig/monetization').set({enabled:false,provider:'off',updatedAt:FieldValue.serverTimestamp()});
  } else {
    const user=await getAuth().getUser(uid);
    await getAuth().setCustomUserClaims(uid,{...user.customClaims,owner:action==='grant-owner'});
  }
  process.stdout.write('Updated. Sign out and back in to refresh owner privileges.\n');
}
main().catch(e=>{process.stderr.write(`${e.message}\n`);process.exitCode=1;});
