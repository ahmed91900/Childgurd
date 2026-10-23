import {before, after, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {ref, uploadBytes, getBytes, deleteObject} from 'firebase/storage';
let env;
before(async()=>{
  env=await initializeTestEnvironment({projectId:'demo-kidsafe',storage:{host:'127.0.0.1',port:9199,rules:await readFile(new URL('../storage.rules',import.meta.url),'utf8')}});
});
after(async()=>{await env.cleanup();});
const owner=()=>env.authenticatedContext('owner',{owner:true}).storage();
const child=()=>env.authenticatedContext('child',{firebase:{sign_in_provider:'anonymous'}}).storage();
const bytes=new Uint8Array([1,2,3]);
const meta={contentType:'image/png',customMetadata:{owner:'owner'}};
test('only owner can upload advertising media with matching metadata',async()=>{
  await assertSucceeds(uploadBytes(ref(owner(),'advertising/original.png'),bytes,meta));
  await assertFails(uploadBytes(ref(child(),'advertising/child.png'),bytes,meta));
  await assertFails(uploadBytes(ref(owner(),'advertising/forged.png'),bytes,{...meta,customMetadata:{owner:'another'}}));
});
test('invalid types, oversized media and unrelated paths are denied',async()=>{
  await assertFails(uploadBytes(ref(owner(),'advertising/program.html'),bytes,{...meta,contentType:'text/html'}));
  await assertFails(uploadBytes(ref(owner(),'advertising/huge.png'),new Uint8Array(20*1024*1024+1),meta));
  await assertFails(uploadBytes(ref(owner(),'children/photo.png'),bytes,meta));
});
test('authenticated clients can fetch ads, unauthenticated SDK access is denied',async()=>{
  await assertSucceeds(uploadBytes(ref(owner(),'advertising/read.png'),bytes,meta));
  await assertSucceeds(getBytes(ref(child(),'advertising/read.png')));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(),'advertising/read.png')));
});
test('only owner can delete uploaded advertisements',async()=>{
  await assertSucceeds(uploadBytes(ref(owner(),'advertising/delete.png'),bytes,meta));
  await assertFails(deleteObject(ref(child(),'advertising/delete.png')));
  await assertSucceeds(deleteObject(ref(owner(),'advertising/delete.png')));
});
