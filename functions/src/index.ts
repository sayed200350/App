import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

// Utilities
const sanitizeText = (input: string): string => {
  return input.trim().replace(/[<>]/g, '').slice(0, 2000);
};

const ensureAuthed = (context: functions.https.CallableContext): string => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  return context.auth.uid;
};

const ensureAdmin = (context: functions.https.CallableContext) => {
  if (!context.auth || !(context.auth.token as any)?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }
};

const rateLimitCheck = async (uid: string, key: string, limit: number, windowSeconds: number) => {
  const bucketRef = db.collection('rateLimits').doc(`${uid}:${key}`);
  const now = admin.firestore.Timestamp.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(bucketRef);
    const data = snap.exists ? snap.data() as any : { count: 0, windowStart: now };
    const windowStart: admin.firestore.Timestamp = data.windowStart || now;
    const count: number = data.count || 0;
    const elapsed = now.seconds - windowStart.seconds;
    if (elapsed > windowSeconds) {
      tx.set(bucketRef, { count: 1, windowStart: now }, { merge: true });
    } else {
      if (count + 1 > limit) {
        throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded');
      }
      tx.set(bucketRef, { count: count + 1, windowStart }, { merge: true });
    }
  });
};

// Backfill: set status: 'visible' where missing on recent community posts (admin only)
export const backfillCommunityStatus = functions.https.onCall(async (_data, context) => {
  ensureAdmin(context);
  const snap = await db.collection('community').orderBy('createdAt', 'desc').limit(1000).get();
  const batch = db.batch();
  let count = 0;
  for (const doc of snap.docs) {
    const data = doc.data() as any;
    if (!Object.prototype.hasOwnProperty.call(data, 'status')) {
      batch.set(doc.ref, { status: 'visible' }, { merge: true });
      count++;
    }
  }
  if (count > 0) await batch.commit();
  return { updated: count };
});

// On rejection create: update aggregates, compute patterns, and schedule follow-up notification
export const onRejectionCreate = functions.firestore
  .document('users/{uid}/rejections/{id}')
  .onCreate(async (snap, context) => {
    const data = snap.data() as any;
    const uid = context.params.uid as string;

    // Update aggregate doc (daily)
    const day = new Date();
    day.setHours(0, 0, 0, 0);
    const dayKey = day.toISOString().split('T')[0];
    const aggRef = db.doc(`users/${uid}/aggregates/${dayKey}`);
    await db.runTransaction(async (tx) => {
      const doc = await tx.get(aggRef);
      const current = doc.exists ? doc.data() as any : { totalLogs: 0, sumImpact: 0 };
      tx.set(
        aggRef,
        {
          totalLogs: (current.totalLogs || 0) + 1,
          sumImpact: (current.sumImpact || 0) + (data?.emotionalImpact || 0),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // Simple server-side pattern detection snapshot
    try {
      const recentSnap = await db
        .collection(`users/${uid}/rejections`)
        .orderBy('timestamp', 'desc')
        .limit(200)
        .get();
      const items = recentSnap.docs.map((d) => d.data());
      const patterns: Array<{ title: string; description: string; insight: string; actionable: string } | null> = [];

      // Ghosting keyword in notes
      const dating = items.filter((i: any) => i.type === 'dating');
      const ghostCount = dating.filter((i: any) => (i.note || '').toLowerCase().includes('ghost')).length;
      if (ghostCount >= 3 && ghostCount > Math.max(1, Math.floor(dating.length / 2))) {
        patterns.push({
          title: 'Ghosting Pattern Detected',
          description: `You\'ve been ghosted ${ghostCount} times recently`,
          insight: "This is about their communication style, not your worth",
          actionable: 'Try apps that require more investment upfront',
        });
      }

      // Day-of-week spikes
      const counts: Record<number, number> = {};
      items.forEach((i: any) => {
        const ts = i.timestamp?.toDate?.() || new Date(i.timestamp);
        const day = (ts instanceof Date) ? ts.getDay() : 0; // 0..6
        counts[day] = (counts[day] || 0) + 1;
      });
      const maxDay = Object.entries(counts).sort((a, b) => b[1] - a[1])[0];
      if (maxDay && maxDay[1] >= Math.max(3, Math.floor(items.length / 3))) {
        const weekday = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][parseInt(maxDay[0])];
        patterns.push({
          title: 'Timing Pattern',
          description: `Most rejections occur on ${weekday}`,
          insight: 'Consider adjusting outreach timing',
          actionable: 'Avoid sending important messages on heavy days',
        });
      }

      // Recovery improvement (approx: average impact falling)
      const sorted = items
        .filter((i: any) => typeof i.emotionalImpact === 'number')
        .sort((a: any, b: any) => {
          const ta = a.timestamp?.toDate?.() || new Date(a.timestamp);
          const tb = b.timestamp?.toDate?.() || new Date(b.timestamp);
          return ta.getTime() - tb.getTime();
        });
      if (sorted.length >= 4) {
        const impacts = sorted.map((i: any) => i.emotionalImpact);
        const half = Math.floor(impacts.length / 2);
        const firstAvg = impacts.slice(0, half).reduce((s: number, v: number) => s + v, 0) / Math.max(1, half);
        const secondAvg = impacts.slice(half).reduce((s: number, v: number) => s + v, 0) / Math.max(1, impacts.length - half);
        if (secondAvg < firstAvg - 1.0) {
          patterns.push({
            title: 'Recovery Improving',
            description: 'Average impact decreased over time',
            insight: "You're building resilience",
            actionable: 'Keep consistent with small daily actions',
          });
        }
      }

      const patternsRef = db.doc(`users/${uid}/aggregates/patterns`);
      await patternsRef.set({
        patterns: patterns.filter(Boolean),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch (e) {
      console.error('Pattern analysis error', e);
    }

    // Schedule follow-up via FCM topic or stored token if available
    try {
      const userDoc = await db.doc(`users/${uid}`).get();
      const token = userDoc.get('fcmToken');
      if (token) {
        await admin.messaging().send({
          token,
          notification: {
            title: 'How are you doing?',
            body: "Yesterday was tough. You're stronger than you know.",
          },
          data: {
            deep_link: 'resilientme://recovery',
          },
        });
      }
    } catch (e) {
      console.error('FCM send error', e);
    }

    return true;
  });

// Callable: Create community post with sanitization and rate limiting
export const createCommunityPost = functions.https.onCall(async (data, context) => {
  const uid = ensureAuthed(context);
  await rateLimitCheck(uid, 'createPost', 5, 60 * 10); // 5 posts per 10 minutes

  const type = String(data?.type || '').toLowerCase();
  const content = sanitizeText(String(data?.content || ''));
  if (!content || content.length < 3) {
    throw new functions.https.HttpsError('invalid-argument', 'Content too short');
  }
  const allowedTypes = new Set(['dating', 'job', 'social', 'other']);
  if (!allowedTypes.has(type)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid type');
  }

  const doc = await db.collection('community').add({
    type,
    content,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    reactions: {},
    authorUid: uid,
    status: 'visible',
  });
  return { id: doc.id };
});

// Callable: React to post with dedupe and basic per-user marker + rate limit
export const reactToPost = functions.https.onCall(async (data, context) => {
  const uid = ensureAuthed(context);
  await rateLimitCheck(uid, 'react', 20, 60); // 20 reactions per minute

  const postId = String(data?.postId || '');
  const reaction = String(data?.reaction || '');
  const allowed = new Set(['💪', '😔', '🎉', '🫂']);
  if (!postId || !allowed.has(reaction)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid post/reaction');
  }

  const postRef = db.collection('community').doc(postId);
  const markerRef = db.collection('userReactions').doc(`${uid}:${postId}`);

  await db.runTransaction(async (tx) => {
    const marker = await tx.get(markerRef);
    if (marker.exists) {
      // Already reacted; no-op to dedupe
      return;
    }
    tx.set(markerRef, { uid, postId, reaction, createdAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    tx.set(
      postRef,
      { [`reactions.${reaction}`]: admin.firestore.FieldValue.increment(1) },
      { merge: true }
    );
  });

  return { ok: true };
});

// Scheduled daily challenge generator
export const generateDailyChallenges = functions.pubsub.schedule('every day 05:00').timeZone('Etc/UTC').onRun(async () => {
  // Iterate all users; for demo, scan user documents that have a profile
  const usersSnap = await db.collection('users').get();
  const batch = db.batch();
  const today = new Date();
  const key = today.toISOString().split('T')[0];
  for (const user of usersSnap.docs) {
    const uid = user.id;
    const level = 'beginner'; // placeholder; could be derived from aggregates
    const challenge = {
      title: 'Self-Care Check',
      description: 'Do one thing today that makes you feel good',
      type: 'other',
      difficulty: level,
      points: 10,
      timeEstimate: '15 minutes',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const ref = db.doc(`users/${uid}/challenges/${key}`);
    batch.set(ref, challenge, { merge: true });
  }
  await batch.commit();
  return null;
});

// Callable: Request data export (dummy bundles user-owned subcollections)
export const requestDataExport = functions.https.onCall(async (_data, context) => {
  const uid = ensureAuthed(context);
  const userRef = db.collection('users').doc(uid);
  const [rejectionsSnap, challengesSnap] = await Promise.all([
    userRef.collection('rejections').get(),
    userRef.collection('challenges').get(),
  ]);
  const payload = {
    rejections: rejectionsSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
    challenges: challengesSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
    generatedAt: new Date().toISOString(),
  };
  // For MVP return directly; in production, store file and email link
  return payload;
});

// Modify requestDataExport to write to Storage and return a signed URL
export const requestDataExport = functions.https.onCall(async (_data, context) => {
  const uid = ensureAuthed(context);
  await rateLimitCheck(uid, 'export', 3, 60 * 10); // 3 exports per 10 min
  const userRef = db.collection('users').doc(uid);
  const [rejectionsSnap, challengesSnap] = await Promise.all([
    userRef.collection('rejections').get(),
    userRef.collection('challenges').get(),
  ]);
  const payload = {
    rejections: rejectionsSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
    challenges: challengesSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
    generatedAt: new Date().toISOString(),
  };
  const json = JSON.stringify(payload, null, 2);
  const path = `exports/${uid}/${Date.now()}.json`;
  await storage.bucket().file(path).save(Buffer.from(json), { contentType: 'application/json' });
  const [url] = await storage.bucket().file(path).getSignedUrl({ action: 'read', expires: Date.now() + 60 * 60 * 1000 });
  return { url };
});

// Trigger: When a rejection is deleted, remove attached image from Storage if present
export const onRejectionDelete = functions.firestore
  .document('users/{uid}/rejections/{id}')
  .onDelete(async (snap, context) => {
    const uid = context.params.uid as string;
    const id = context.params.id as string;
    const path = `rejection_images/${uid}/${id}.jpg`;
    try {
      await storage.bucket().file(path).delete({ ignoreNotFound: true });
    } catch (e) {
      console.error('Storage delete error', e);
    }
  });

// Callable: Request account deletion (scrub PII, delete subcollections)
export const requestAccountDeletion = functions.https.onCall(async (_data, context) => {
  const uid = ensureAuthed(context);

  // Delete user subcollections
  const userRef = db.collection('users').doc(uid);
  const rejections = await userRef.collection('rejections').listDocuments();
  const challenges = await userRef.collection('challenges').listDocuments();

  // Delete associated Storage images for rejections
  for (const doc of rejections) {
    const path = `rejection_images/${uid}/${doc.id}.jpg`;
    try { await storage.bucket().file(path).delete({ ignoreNotFound: true }); } catch {}
  }

  const batches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;
  for (const doc of [...rejections, ...challenges]) {
    batch.delete(doc);
    count++;
    if (count % 400 === 0) { // stay within batch limits
      batches.push(batch);
      batch = db.batch();
    }
  }
  batches.push(batch);
  for (const b of batches) { await b.commit(); }

  // Delete user root doc if present
  await userRef.delete().catch(() => {});

  // Delete auth user
  try { await auth.deleteUser(uid); } catch (e) { console.error('Auth delete failed', e); }

  return { ok: true };
});

// Callable: Report a community post; increments report count and hides if exceeds threshold
export const reportPost = functions.https.onCall(async (data, context) => {
  const uid = ensureAuthed(context);
  await rateLimitCheck(uid, 'report', 10, 60); // 10 reports per minute

  const postId = String(data?.postId || '');
  if (!postId) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid post');
  }

  const postRef = db.collection('community').doc(postId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(postRef);
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Post not found');
    const data = snap.data() as any;
    const reports = (data.reports || 0) + 1;
    const update: any = { reports };
    if (reports >= 3) {
      update.status = 'hidden';
    }
    tx.set(postRef, update, { merge: true });
    tx.set(db.collection('communityReports').doc(), { uid, postId, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  });

  return { ok: true };
});
