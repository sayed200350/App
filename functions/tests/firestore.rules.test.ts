import { initializeTestEnvironment, RulesTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
let testEnv: RulesTestEnvironment;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'resilientme-test',
    firestore: {
      rules: readFileSync(require('path').resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('Firestore Security Rules', () => {
  it('denies community writes from client', async () => {
    const ctx = testEnv.authenticatedContext('alice');
    const db = ctx.firestore();
    const ref = db.collection('community').doc('post1');
    await assertFails(ref.set({ content: 'hello', type: 'dating' }));
  });

  it('allows user to write own user doc and denies others', async () => {
    const aliceCtx = testEnv.authenticatedContext('alice');
    const bobCtx = testEnv.authenticatedContext('bob');
    const aliceDb = aliceCtx.firestore();
    const bobDb = bobCtx.firestore();

    await assertSucceeds(aliceDb.collection('users').doc('alice').collection('rejections').doc('1').set({ timestamp: new Date(), type: 'dating' }));
    await assertFails(bobDb.collection('users').doc('alice').collection('rejections').doc('2').set({ timestamp: new Date(), type: 'job' }));
  });

  it('allows public read of community', async () => {
    const anon = testEnv.unauthenticatedContext();
    const db = anon.firestore();
    const ref = db.collection('community');
    await assertSucceeds(ref.get());
  });
});