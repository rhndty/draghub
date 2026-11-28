import { createSnapTransaction } from '../lib/midtrans.js';
import { readJsonBody, sendJson, setCors } from '../lib/http.js';

/**
 * POST /api/create-transaction
 * Body: { orderId, grossAmount, customerName?, customerEmail?, itemName? }
 * Mengembalikan: { orderId, token, redirectUrl, finishUrl }
 */
export default async function handler(req, res) {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    sendJson(res, 405, { error: 'Gunakan method POST.' });
    return;
  }

  try {
    const body = await readJsonBody(req);
    const result = await createSnapTransaction({
      orderId: body.orderId,
      grossAmount: body.grossAmount,
      customerName: body.customerName,
      customerEmail: body.customerEmail,
      itemName: body.itemName,
      finishUrl: body.finishUrl,
    });
    sendJson(res, 200, result);
  } catch (error) {
    sendJson(res, error.statusCode || 500, {
      error: error.message,
      details: error.details,
    });
  }
}
