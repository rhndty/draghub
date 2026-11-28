import { createServer } from 'node:http';

import { finishPageHtml } from './lib/finish-page.js';
import { sendJson, setCors } from './lib/http.js';
import {
  createSnapTransaction,
  getTransactionStatus,
  isPaidStatus,
  verifyNotificationSignature,
} from './lib/midtrans.js';

const PORT = Number(process.env.PORT || 3000);

const server = createServer(async (req, res) => {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }

  const url = new URL(req.url || '/', `http://${req.headers.host}`);
  const pathname = url.pathname.replace(/\/+$/, '') || '/';

  try {
    // Health check untuk memastikan server hidup
    if (req.method === 'GET' && pathname === '/') {
      sendJson(res, 200, {
        status: 'ok',
        service: 'draghub-midtrans-backend',
        sandbox: process.env.MIDTRANS_IS_PRODUCTION !== 'true',
        endpoints: [
          'POST /api/create-transaction',
          'GET /api/status/:orderId',
          'GET /api/finish',
          'POST /api/notification',
        ],
      });
      return;
    }

    if (req.method === 'POST' && pathname === '/api/create-transaction') {
      const body = await readJson(req);
      const result = await createSnapTransaction({
        orderId: body.orderId,
        grossAmount: body.grossAmount,
        customerName: body.customerName,
        customerEmail: body.customerEmail,
        itemName: body.itemName,
        finishUrl: body.finishUrl,
      });
      sendJson(res, 200, result);
      return;
    }

    if (req.method === 'GET' && pathname.startsWith('/api/status/')) {
      const orderId = decodeURIComponent(pathname.slice('/api/status/'.length));
      const status = await getTransactionStatus(orderId);
      sendJson(res, 200, status);
      return;
    }

    if (req.method === 'GET' && pathname === '/api/finish') {
      res.statusCode = 200;
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.end(finishPageHtml);
      return;
    }

    if (req.method === 'POST' && pathname === '/api/notification') {
      const body = await readJson(req);
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
      const status = await getTransactionStatus(body.order_id);
      console.log('[midtrans-notification]', {
        orderId: status.orderId,
        transactionStatus: status.transactionStatus,
        fraudStatus: status.fraudStatus,
        paid: isPaidStatus(status.transactionStatus, status.fraudStatus),
      });
      sendJson(res, 200, { received: true });
      return;
    }

    sendJson(res, 404, { error: 'Endpoint tidak ditemukan.' });
  } catch (error) {
    console.error('[midtrans-backend]', error);
    sendJson(res, error.statusCode || 500, {
      error: error.message,
      details: error.details,
    });
  }
});

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (chunks.length === 0) return {};
  const raw = Buffer.concat(chunks).toString('utf8');
  try {
    return JSON.parse(raw);
  } catch {
    const error = new Error('Body request bukan JSON yang valid.');
    error.statusCode = 400;
    throw error;
  }
}

server.listen(PORT, () => {
  const sandbox = process.env.MIDTRANS_IS_PRODUCTION !== 'true';
  console.log(
    `[midtrans-backend] jalan di http://localhost:${PORT} (${sandbox ? 'SANDBOX' : 'PRODUCTION'})`,
  );
  if (!process.env.MIDTRANS_SERVER_KEY) {
    console.warn(
      '[midtrans-backend] PERINGATAN: MIDTRANS_SERVER_KEY belum di-set. Salin .env.example menjadi .env lalu isi key-nya.',
    );
  }
});
