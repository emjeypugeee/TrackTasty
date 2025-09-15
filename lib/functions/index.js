const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
admin.initializeApp();

// Configure nodemailer with your email service
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: functions.config().gmail.email,
    pass: functions.config().gmail.password,
  },
});

exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const {email, password, userData} = data;
  
  // Generate a unique token for verification
  const token = require('crypto').randomBytes(20).toString('hex');
  const expires = Date.now() + 3600000; // 1 hour
  
  // Store the pending registration in Firestore
  await admin.firestore().collection('pendingRegistrations').doc(token).set({
    email,
    password,
    userData,
    expires,
  });
  
  // Send verification email
  const verificationLink = `https://yourapp.com/verify?token=${token}`;
  const mailOptions = {
    from: 'your-app@gmail.com',
    to: email,
    subject: 'Verify your email',
    html: `<p>Please click <a href="${verificationLink}">here</a> to verify your email address.</p>`,
  };
  
  await transporter.sendMail(mailOptions);
  
  return {success: true};
});

exports.completeRegistration = functions.https.onCall(async (data, context) => {
  const {token} = data;
  
  // Get the pending registration
  const doc = await admin.firestore().collection('pendingRegistrations').doc(token).get();
  
  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Invalid or expired token');
  }
  
  const {email, password, userData, expires} = doc.data();
  
  // Check if token is expired
  if (Date.now() > expires) {
    await admin.firestore().collection('pendingRegistrations').doc(token).delete();
    throw new functions.https.HttpsError('deadline-exceeded', 'Token expired');
  }
  
  // Create the user account
  const userRecord = await admin.auth().createUser({
    email,
    password,
    emailVerified: true,
  });
  
  // Save user data to Firestore
  await admin.firestore().collection('Users').doc(email).set({
    ...userData,
    email,
    dateAccountCreated: admin.firestore.FieldValue.serverTimestamp(),
    isAdmin: false,
    lastPreferenceStep: 7,
    preferencesCompleted: true,
    profileImage: null,
  });
  
  // Save initial weight
  const currentDate = new Date();
  const dateString = `${currentDate.getFullYear()}-${(currentDate.getMonth() + 1).toString().padStart(2, '0')}-${currentDate.getDate().toString().padStart(2, '0')}`;
  
  await admin.firestore().collection('weight_history').doc(`${userRecord.uid}_${dateString}`).set({
    userId: userRecord.uid,
    date: admin.firestore.FieldValue.serverTimestamp(),
    weight: userData.weight,
  });
  
  // Clean up the pending registration
  await admin.firestore().collection('pendingRegistrations').doc(token).delete();
  
  return {success: true, uid: userRecord.uid};
});