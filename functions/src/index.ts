import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onRejectionCreate = functions.firestore
  .document('users/{uid}/rejections/{id}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const uid = context.params.uid as string;
    const createdAt = data?.createdAt || admin.firestore.FieldValue.serverTimestamp();

    // Update aggregate doc (daily)
    const day = new Date();
    day.setHours(0,0,0,0);
    const dayKey = day.toISOString().split('T')[0];
    const aggRef = admin.firestore().doc(`users/${uid}/aggregates/${dayKey}`);
    await admin.firestore().runTransaction(async tx => {
      const doc = await tx.get(aggRef);
      const current = doc.exists ? doc.data() : { totalLogs: 0, sumImpact: 0 };
      tx.set(aggRef, {
        totalLogs: (current.totalLogs || 0) + 1,
        sumImpact: (current.sumImpact || 0) + (data?.emotionalImpact || 0),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    });

    // TODO: schedule follow-up notification via FCM
    return true;
  });
