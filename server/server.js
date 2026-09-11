const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT) || 8080;
const publicDir = path.join(__dirname, 'public');
const downloadsDir = path.join(__dirname, 'downloads');

function sendDownload(res, filePath, contentType, filename) {
  if (!fs.existsSync(filePath)) {
    res.status(404).type('text/plain').send('Archivo no disponible en este despliegue.');
    return;
  }
  res.setHeader('Content-Type', contentType);
  res.setHeader('Content-Disposition', 'attachment; filename="' + filename + '"');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.sendFile(filePath);
}

app.get('/downloads/mochila-market.apk', (req, res) => {
  sendDownload(
    res,
    path.join(downloadsDir, 'mochila-market.apk'),
    'application/vnd.android.package-archive',
    'mochila-market.apk',
  );
});

app.get('/downloads/mochila-market-android.zip', (req, res) => {
  sendDownload(
    res,
    path.join(downloadsDir, 'mochila-market-android.zip'),
    'application/zip',
    'mochila-market-android.zip',
  );
});

app.get('/downloads/mochila-market-ios.zip', (req, res) => {
  sendDownload(
    res,
    path.join(downloadsDir, 'mochila-market-ios.zip'),
    'application/zip',
    'mochila-market-ios.zip',
  );
});

app.use(express.static(publicDir, { index: 'index.html' }));

app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('mochila-market listening on 0.0.0.0:' + PORT);
});
