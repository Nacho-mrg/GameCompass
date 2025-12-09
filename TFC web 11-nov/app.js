// Configuración Firebase (pon tu configuración real)
const firebaseConfig = {
    apiKey: "TU_API_KEY",
    authDomain: "TU_AUTH_DOMAIN",
    projectId: "TU_PROJECT_ID",
    storageBucket: "TU_STORAGE_BUCKET",
    messagingSenderId: "TU_MESSAGING_SENDER_ID",
    appId: "TU_APP_ID"
  };
  
  firebase.initializeApp(firebaseConfig);
  const auth = firebase.auth();
  
  const welcomeMessage = document.getElementById("welcomeMessage");
  const getStartedBtn = document.getElementById("getStartedBtn");
  
  auth.onAuthStateChanged(user => {
    if (user) {
      welcomeMessage.textContent = `¡Bienvenido de nuevo, ${user.displayName || user.email}!`;
      welcomeMessage.classList.remove("hidden");
      getStartedBtn.style.display = "none";
    } else {
      welcomeMessage.textContent = "";
      welcomeMessage.classList.add("hidden");
      getStartedBtn.style.display = "inline-block";
    }
  });
  
  getStartedBtn.addEventListener("click", () => {
    // Aquí puedes abrir un modal o redirigir a la página de login
    alert("Aquí va el flujo de login o registro.");
  });
  