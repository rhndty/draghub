# DragHub Midtrans Backend

Backend kecil (Node.js, tanpa dependency) untuk:

- `POST /api/create-transaction` → membuat Snap token & `redirect_url`
- `GET /api/status/:orderId` → mengecek status transaksi asli ke Midtrans
- `GET /api/finish` → halaman redirect setelah pembayaran
- `POST /api/notification` → webhook Midtrans (verifikasi signature)

## Menjalankan lokal

```powershell
Copy-Item .env.example .env
notepad .env                 # isi MIDTRANS_SERVER_KEY
npm.cmd start                # atau: node --env-file=.env server.js
```

Tes: http://localhost:3000

## Deploy Vercel

```powershell
npx vercel
npx vercel --prod
```

Set environment variables di dashboard Vercel (`MIDTRANS_SERVER_KEY`,
`MIDTRANS_CLIENT_KEY`, `MIDTRANS_IS_PRODUCTION=false`,
`PUBLIC_BASE_URL=https://project.vercel.app`).

Panduan lengkap: [`../docs/MIDTRANS_SETUP.md`](../docs/MIDTRANS_SETUP.md).
