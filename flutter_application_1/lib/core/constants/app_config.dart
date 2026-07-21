
const String kBaseUrlAuth     = 'https://epidiagnostic-ms-pacientes.onrender.com';       // MS1: auth, pacientes, personal, admin
const String kBaseUrlAtencion = 'https://epidiagnostic-ms-atencion-medica.onrender.com'; // MS2: atenciones (mismo JWT que MS1)
const String kBaseUrlML       = 'http://44.206.197.26:8001';  // Legado: NER + Isolation Forest — AWS EC2 (no confundir con MS2)
const String kBaseUrl         = kBaseUrlAuth; // alias para compatibilidad


const String kStripePublishableKey = 'pk_test_REEMPLAZAR_CON_CLAVE_REAL';


const String kPriceIdIntermedio = 'price_test_INTERMEDIO_XXX';
const String kPriceIdPremedio   = 'price_test_PREMIUM_XXX';
