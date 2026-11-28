import {
  getTransactionStatus,
  isPaidStatus,
  verifyNotificationSignature,
} from '../lib/midtrans.js';
import { readJsonBody, sendJson, setCors } from '../lib/http.js';

/**
 * POST /api/notification
 * Webhook resmi Midtrans (Settings > Payment Notification URL).
 * Signature diverifikasi memakai Server Key, jadi endpoint ini aman dari
 * request palsu.
 *
 * Catatan: contoh ini hanya memverifikasi & mencatat status. Kalau mau,
 * di sini bisa ditambahkan update Firestore memakai firebase-admin agar
 * status PAID tetap terbit walaupun aplikasi ditutup.
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
    const valid = verifyNotificationSignature({
      orderId: body.order_id,
      statusCode: body.status_code,
      grossAmount: body.gross_amount,
      signatureKey: body.signature_key,
    });

    if (!valid) {
      sendJson(res, 401, { error: 'Signature notifikasi tidak valid.' });
      return;
    }

    // Ambil status terbaru langsung dari API Midtrans (lebih terpercaya
    // daripada body notifikasi).
    const status = await getTransactionStatus(body.order_id);
    const paid = isPaidStatus(status.transactionStatus, status.fraudStatus);

    console.log('[midtrans-notification]', {
      orderId: status.orderId,
      transactionStatus: status.transactionStatus,
      fraudStatus: status.fraudStatus,
      paid,
    });

    // Midtrans menganggap sukses kalau kita membalas HTTP 2xx.
    sendJson(res, 200, { received: true, paid });
  } catch (error) {
    sendJson(res, error.statusCode || 500, { error: error.message });
  }
}
