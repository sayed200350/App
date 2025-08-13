import { initializeTestEnvironment, RulesTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

let testEnv: RulesTestEnvironment;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'resilientme-test',
    storage: {
      rules: readFileSync(require('path').resolve(__dirname, '../../storage.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('Storage Security Rules', () => {
  it('allows user to write own image and denies others', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const aliceStorage = alice.storage();
    const bobStorage = bob.storage();

    await assertSucceeds(aliceStorage.ref('rejection_images/alice/img.jpg').putString('hello'));
    await assertFails(bobStorage.ref('rejection_images/alice/img.jpg').putString('nope'));
  });
});