importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBJ4i42jXh_YF_rPKbN5zTcXOt7DmqvQpU",
  authDomain: "smallcargo-a0b67.firebaseapp.com",
  projectId: "smallcargo-a0b67",
  storageBucket: "smallcargo-a0b67.firebasestorage.app",
  messagingSenderId: "649372892023",
  appId: "1:649372892023:web:4b0b9f8c5f3a6d4e5f6b8c"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve Firebase Messaging object
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
