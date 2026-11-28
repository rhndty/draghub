import { finishPageHtml } from '../lib/finish-page.js';

/**
 * GET /api/finish
 * Halaman yang dibuka Midtrans setelah pembayaran selesai.
 * Di aplikasi mobile, WebView akan menangkap URL ini lalu kembali ke app.
 */
export default function handler(req, res) {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(finishPageHtml);
}
