import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { setLogLevel, doc, setDoc, getDoc, updateDoc } from 'firebase/firestore';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require('fs');

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
	setLogLevel('error');
	testEnv = await initializeTestEnvironment({
		projectId: 'resilientme-staging',
		firestore: {
			host: '127.0.0.1',
			port: 8080,
			rules: fs.readFileSync('../firestore.rules', 'utf8'),
		},
	});
});

afterAll(async () => {
	await testEnv.cleanup();
});

it('denies reading another user\'s document', async () => {
	const alice = testEnv.authenticatedContext('alice');
	const bobDb = testEnv.authenticatedContext('bob').firestore();
	const aliceDb = alice.firestore();
	await setDoc(doc(aliceDb, 'users/alice/profile/info'), { ok: true });
	await expect(getDoc(doc(bobDb, 'users/alice/profile/info'))).rejects.toThrow();
});

it('allows owner to write under /users/{uid}', async () => {
	const janeDb = testEnv.authenticatedContext('jane').firestore();
	await setDoc(doc(janeDb, 'users/jane/rejections/one'), { emotionalImpact: 8, timestamp: new Date() });
	const snap = await getDoc(doc(janeDb, 'users/jane/rejections/one'));
	expect(snap.exists()).toBe(true);
});

it('allows reaction-only updates on community', async () => {
	const authedDb = testEnv.authenticatedContext('user1').firestore();
	// Seed post as admin
	const adminDb = testEnv.unauthenticatedContext().firestore();
	await setDoc(doc(adminDb, 'community/post1'), { content: 'test', type: '💔 Dating', createdAt: new Date(), reactions: {} });
	// Reaction update
	await updateDoc(doc(authedDb, 'community/post1'), { 'reactions.support': 1 });
	const snap = await getDoc(doc(authedDb, 'community/post1'));
	expect(snap.data()?.reactions?.support).toBe(1);
});