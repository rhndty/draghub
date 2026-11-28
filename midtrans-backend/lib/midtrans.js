import { createHash } from 'node:crypto';

import { basicAuthHeader, getConfig } from './config.js';

/**
 * Membuat transaksi Snap di Midtrans.
 * Endpoint resmi: POST {snapBaseUrl}/snap/v1/transactions
 * Butuh Server Key (Basic Auth), jadi WAJIB dijalankan di server.
 */
export async function createSnapTransaction({
  orderId,
  grossAmount,
  customerName,
  customerEmail,
  itemName,
  finishUrl,
}) {
  const cfg = getConfig();

  const amount = Math.round(Number(grossAmount));
  if (!orderId) {
    throw httpError(400, 'orderId wajib diisi.');
  }
  if (!Number.isFinite(amount) || amount < 1000) {
    throw httpError(400, 'grossAmount minimal Rp 1.000.');
  }

  const finalFinishUrl = finishUrl || `${cfg.publicBaseUrl}/api/finish`;

  const payload = {
    transaction_details: {
      order_id: orderId,
      gross_amount: amount,
    },
    item_details: [
      {
        id: String(orderId).slice(0, 50),
        price: amount,
        quantity: 1,
        name: String(itemName || 'Pendaftaran Event DragHub').slice(0, 50),
      },
    ],
    customer_details: {
      first_name: String(customerName || 'Rider DragHub').slice(0, 50),
      email: customerEmail || 'rider@draghub.local',
    },
    callbacks: {
      finish: finalFinishUrl,
    },
    expiry: {
      unit: 'hours',
      duration: 24,
    },
  };

  const response = await fetch(`${cfg.snapBaseUrl}/snap/v1/transactions`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: basicAuthHeader(cfg.serverKey),
    },
    body: JSON.stringify(payload),
  });

  const data = await parseJsonResponse(response);

  if (!response.ok) {
    throw httpError(
      response.status,
      data.status_message || 'Gagal membuat transaksi Midtrans.',
      data,
    );
  }

  return {
    orderId,
    token: data.token,
    redirectUrl: data.redirect_url,
    finishUrl: finalFinishUrl,
    isProduction: cfg.isProduction,
  };
}

/**
 * Mengecek status transaksi langsung ke Midtrans.
 * Endpoint resmi: GET {apiBaseUrl}/v2/{order_id}/status
 */
export async function getTransactionStatus(orderId) {
  if (!orderId) {
    throw httpError(400, 'orderId wajib diisi.');
  }

  const cfg = getConfig();
  const response = await fetch(
    `${cfg.apiBaseUrl}/v2/${encodeURIComponent(orderId)}/status`,
    {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        Authorization: basicAuthHeader(cfg.serverKey),
      },
    },
  );

  const data = await parseJsonResponse(response);

  if (!response.ok) {
    throw httpError(
      response.status,
      data.status_message || 'Gagal mengecek status transaksi Midtrans.',
      data,
    );
  }

  return {
    orderId: data.order_id || orderId,
    transactionStatus: data.transaction_status || 'unknown',
    fraudStatus: data.fraud_status || null,
    statusCode: data.status_code || null,
    statusMessage: data.status_message || null,
    grossAmount: data.gross_amount || null,
    paymentType: data.payment_type || null,
    transactionId: data.transaction_id || null,
    transactionTime: data.transaction_time || null,
    settlementTime: data.settlement_time || null,
    expiryTime: data.expiry_time || null,
    raw: data,
  };
}

/**
 * Verifikasi signature webhook/notification Midtrans.
 * signature_key = SHA512(order_id + status_code + gross_amount + server_key)
 */
export function verifyNotificationSignature({
  orderId,
  statusCode,
  grossAmount,
  signatureKey,
}) {
  if (!orderId || statusCode == null || grossAmount == null || !signatureKey) {
    return false;
  }
  const cfg = getConfig();
  const raw = `${orderId}${statusCode}${grossAmount}${cfg.serverKey}`;
  const expected = createHash('sha512').update(raw).digest('hex');
  return expected === signatureKey;
}

export function isPaidStatus(transactionStatus, fraudStatus) {
  return (
    transactionStatus === 'settlement' ||
    (transactionStatus === 'capture' &&
      (fraudStatus === 'accept' || fraudStatus == null))
  );
}

function httpError(statusCode, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  if (details) error.details = details;
  return error;
}

async function parseJsonResponse(response) {
  const text = await response.text();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}
