// Required by firebase_messaging for web push notifications. This file
// must live at the root of the web build output (web/) and be served as
// a real .js file with the correct MIME type -- browsers request it
// automatically at /firebase-messaging-sw.js. Without it, FCM cannot
// register a service worker and every token save silently fails on web.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCttuDafRjrumRiR7A81CPg73kdGAmy7lI',
  appId: '1:409979331712:web:513850da84e7a6541ab265',
  messagingSenderId: '409979331712',
  projectId: 'hospital-management-syst-55814',
  authDomain: 'hospital-management-syst-55814.firebaseapp.com',
  storageBucket: 'hospital-management-syst-55814.firebasestorage.app',
});

const messaging = firebase.messaging();

// Handles notifications that arrive while no tab has the app open
// (background/terminated state on web).
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});