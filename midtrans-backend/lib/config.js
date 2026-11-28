/**
 * Konfigurasi Midtrans dari environment variable.
 * Server Key HANYA boleh hidup di backend, jangan pernah dikirim ke Flutter.
 */
export function getConfig() {
  const serverKey = (process.env.MIDTRANS_SERVER_KEY || '').trim();
  if (!serverKey) {
    const error = new Error(
      'MIDTRANS_SERVER_KEY belum di-set. Isi file .env (lokal) atau Environment Variables di Vercel.',
    );
    error.statusCode = 500;
    throw error;
  }

  const isProduction =
    String(process.env.MIDTRANS_IS_PRODUCTION || 'false').toLowerCase() ===
    'true';
  const publicBaseUrl = (process.env.PUBLIC_BASE_URL || 'http://localhost:3000')
    .trim()
    .replace(/\/+$/, '');

  return {
    serverKey,
    clientKey: (process.env.MIDTRANS_CLIENT_KEY || '').trim(),
    isProduction,
    publicBaseUrl,
    snapBaseUrl: isProduction
      ? 'https://app.midtrans.com'
      : 'https://app.sandbox.midtrans.com',
    apiBaseUrl: isProduction
      ? 'https://api.midtrans.com'
      : 'https://api.sandbox.midtrans.com',
  };
}

export function basicAuthHeader(serverKey) {
  return `Basic ${Buffer.from(`${serverKey}:`).toString('base64')}`;
}
