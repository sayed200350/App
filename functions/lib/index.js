"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reactToPost = exports.submitPost = exports.processNotificationQueue = exports.onRejectionCreate = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.onRejectionCreate = functions.firestore
    .document('users/{uid}/rejections/{id}')
    .onCreate(async (snap, context) => {
    const data = snap.data();
    const uid = context.params.uid;
    const createdAt = data?.timestamp?.toDate?.() ?? new Date();
    const day = new Date(createdAt);
    day.setHours(0, 0, 0, 0);
    const dayKey = day.toISOString().split('T')[0];
    const aggRef = admin.firestore().doc(`users/${uid}/aggregates/${dayKey}`);
    await admin.firestore().runTransaction(async (tx) => {
        const doc = await tx.get(aggRef);
        const current = doc.exists ? doc.data() || {} : { totalLogs: 0, sumImpact: 0 };
        const emotionalImpact = Number(data?.emotionalImpact ?? 0) || 0;
        tx.set(aggRef, {
            totalLogs: (current.totalLogs || 0) + 1,
            sumImpact: (current.sumImpact || 0) + emotionalImpact,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        const qs = await admin
            .firestore()
            .collection(`users/${uid}/rejections`)
            .where('timestamp', '>=', sevenDaysAgo)
            .get();
        const impacts = qs.docs.map((d) => Number(d.get('emotionalImpact') || 0) || 0);
        const total = impacts.length;
        const avg = impacts.reduce((a, b) => a + b, 0) / Math.max(1, total);
        const score = Math.max(5, 100 - avg * 7);
        await admin
            .firestore()
            .doc(`users/${uid}/stats/current`)
            .set({
            resilienceScore: score,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }
    catch (e) {
        console.warn('[stats] failed to compute resilience score', e);
    }
    try {
        const emotionalImpact = Number(data?.emotionalImpact ?? 0) || 0;
        if (emotionalImpact >= 7) {
            const runAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
            await admin
                .firestore()
                .collection(`users/${uid}/notificationQueue`)
                .add({
                type: 'recovery-followup',
                runAt,
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                payload: {
                    rejectionId: snap.id,
                    emotionalImpact,
                },
            });
        }
    }
    catch (e) {
        console.warn('[queue] failed to enqueue follow-up', e);
    }
    return true;
});
exports.processNotificationQueue = functions.pubsub
    .schedule('every 1 minutes')
    .onRun(async () => {
    const now = new Date();
    const queueSnap = await admin
        .firestore()
        .collectionGroup('notificationQueue')
        .where('status', '==', 'pending')
        .where('runAt', '<=', now)
        .limit(20)
        .get();
    if (queueSnap.empty)
        return null;
    const tasks = [];
    for (const doc of queueSnap.docs) {
        const queueRef = doc.ref;
        const userRef = queueRef.parent.parent;
        if (!userRef)
            continue;
        tasks.push((async () => {
            try {
                const tokensSnap = await userRef.collection('fcmTokens').get();
                const tokens = tokensSnap.docs.map((d) => d.get('token') || d.id).filter(Boolean);
                if (tokens.length === 0) {
                    await queueRef.set({ status: 'no-tokens', processedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
                    return;
                }
                const message = {
                    notification: {
                        title: 'How are you doing?',
                        body: "Yesterday was tough. You're stronger than you know.",
                    },
                    data: {
                        type: 'recovery-followup',
                    },
                };
                await admin.messaging().sendEachForMulticast({ tokens, ...message });
                await queueRef.set({ status: 'sent', processedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
            }
            catch (e) {
                console.warn('[queue] processing failed', e);
                await queueRef.set({ status: 'error', error: String(e?.message || e), processedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
            }
        })());
    }
    await Promise.allSettled(tasks);
    return null;
});
exports.submitPost = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    let type = String(data?.type || '').slice(0, 32);
    let content = String(data?.content || '').trim();
    content = content.replace(/[<>]/g, '');
    if (content.length === 0 || content.length > 2000) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid content');
    }
    const doc = await admin.firestore().collection('community').add({
        type,
        content,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        reactions: {},
        authorUid: uid,
    });
    return { id: doc.id };
});
exports.reactToPost = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const postId = String(data?.postId || '');
    const reaction = String(data?.reaction || '');
    if (!postId || !reaction)
        throw new functions.https.HttpsError('invalid-argument', 'Missing arguments');
    const postRef = admin.firestore().collection('community').doc(postId);
    const userMarkRef = postRef.collection('userReactions').doc(uid);
    await admin.firestore().runTransaction(async (tx) => {
        const mark = await tx.get(userMarkRef);
        if (mark.exists)
            throw new functions.https.HttpsError('already-exists', 'Already reacted');
        tx.set(userMarkRef, { reactedAt: admin.firestore.FieldValue.serverTimestamp(), reaction });
        tx.set(postRef, { [`reactions.${reaction}`]: admin.firestore.FieldValue.increment(1) }, { merge: true });
    });
    return { ok: true };
});
//# sourceMappingURL=index.js.map