// Para emulador Android usa 10.0.2.2 (apunta al localhost del host).
// Para dispositivo físico usa la IP local de tu máquina (ej. 192.168.1.X).
// Cambiar por la URL real cuando se despliegue en la nube.
const String kBaseUrl = 'http://192.168.100.30:8000';

// ── Stripe (modo TEST) ────────────────────────────────────────────────────────
// Obtener en https://dashboard.stripe.com/test/apikeys
// En modo test NINGUNA tarjeta cobra dinero real.
// Reemplazar con la clave publicable real del proyecto en Stripe.
const String kStripePublishableKey = 'pk_test_REEMPLAZAR_CON_CLAVE_REAL';

// IDs de precio de Stripe (configurar en https://dashboard.stripe.com/test/products)
// Crear un producto por plan con precio recurrente mensual.
const String kPriceIdIntermedio = 'price_test_INTERMEDIO_XXX';
const String kPriceIdPremedio   = 'price_test_PREMIUM_XXX';
