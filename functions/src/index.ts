import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onRejectionCreate = functions.firestore
  .document('users/{uid}/rejections/{id}')
  .onCreate(async (snap, context) => {
    const data = snap.data() as any;
    const uid = context.params.uid as string;

    // Prefer client-provided timestamp; fallback to server time
    const createdAt: Date = data?.timestamp?.toDate?.() ?? new Date();

    // Update aggregate doc (daily)
    const day = new Date(createdAt);
    day.setHours(0, 0, 0, 0);
    const dayKey = day.toISOString().split('T')[0];
    const aggRef = admin.firestore().doc(`users/${uid}/aggregates/${dayKey}`);
    await admin.firestore().runTransaction(async (tx) => {
      const doc = await tx.get(aggRef);
      const current = doc.exists ? doc.data() || {} : { totalLogs: 0, sumImpact: 0 };
      const emotionalImpact = Number(data?.emotionalImpact ?? 0) || 0;
      tx.set(
        aggRef,
        {
          totalLogs: (current.totalLogs || 0) + 1,
          sumImpact: (current.sumImpact || 0) + emotionalImpact,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // Compute simple resilience score (rolling 7 days avg impact)
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
        .set(
          {
            resilienceScore: score,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    } catch (e) {
      console.warn('[stats] failed to compute resilience score', e);
    }

    // Enqueue follow-up notification for high-impact entries (>= 7)
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
    } catch (e) {
      console.warn('[queue] failed to enqueue follow-up', e);
    }

    return true;
  });

// Scheduled processor: checks due notifications and sends FCM
export const processNotificationQueue = functions.pubsub
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

    if (queueSnap.empty) return null;

    const tasks: Promise<any>[] = [];

    for (const doc of queueSnap.docs) {
      const queueRef = doc.ref;
      const userRef = queueRef.parent.parent; // users/{uid}
      if (!userRef) continue;
      const uid = userRef.id;

      tasks.push(
        (async () => {
          try {
            // Load FCM tokens
            const tokensSnap = await userRef.collection('fcmTokens').get();
            const tokens = tokensSnap.docs.map((d) => (d.get('token') as string) || d.id).filter(Boolean);
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
            } as const;

            await admin.messaging().sendEachForMulticast({ tokens, ...message });

            await queueRef.set({ status: 'sent', processedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
          } catch (e) {
            console.warn('[queue] processing failed', e);
            await queueRef.set(
              { status: 'error', error: String((e as Error)?.message || e), processedAt: admin.firestore.FieldValue.serverTimestamp() },
              { merge: true }
            );
          }
        })()
      );
    }

    await Promise.allSettled(tasks);
    return null;
  });
