export const finishPageHtml = `<!doctype html>
<html lang="id">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Pembayaran Selesai - DragHub</title>
    <style>
      body { font-family: system-ui, -apple-system, sans-serif; background: #f7f7f9; margin: 0; padding: 24px; color: #1f2937; }
      .card { max-width: 420px; margin: 48px auto; background: #fff; border-radius: 16px; padding: 28px; box-shadow: 0 10px 30px rgba(0,0,0,.08); text-align: center; }
      h1 { font-size: 20px; margin: 0 0 8px; }
      p { font-size: 14px; color: #6b7280; line-height: 1.5; }
      a { display: inline-block; margin-top: 18px; background: #7f1d1d; color: #fff; text-decoration: none; padding: 12px 20px; border-radius: 10px; font-weight: 700; font-size: 14px; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>Pembayaran Selesai</h1>
      <p>Terima kasih. Silakan kembali ke aplikasi DragHub untuk melihat nomor balap Anda.</p>
      <a href="draghub://midtrans-finish">Kembali ke DragHub</a>
    </div>
  </body>
</html>`;
