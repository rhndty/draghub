import { getTransactionStatus } from '../../lib/midtrans.js';
import { sendJson, setCors } from '../../lib/http.js';

/**
 * GET /api/status/:orderId
 * Mengembalikan status transaksi asli dari Midtrans.
 */
export default async function handler(req, res) {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }

  if (req.method !== 'GET') {
    sendJson(res, 405, { error: 'Gunakan method GET.' });
    return;
  }

  try {
    const orderId =
      req.query?.orderId ||
      (req.url ? decodeURIComponent(req.url.split('?')[0].split('/').pop()) : '');

    const status = await getTransactionStatus(orderId);
    sendJson(res, 200, status);
  } catch (error) {
    sendJson(res, error.statusCode || 500, {
      error: error.message,
      details: error.details,
    });
  }
}
