const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const { promisify } = require('util'); // Import promisify for fs.unlink
const unlink = promisify(fs.unlink); // Promisify the unlink function
const multer = require('multer');
var PDFDocument = require('pdfkit');

router.post('/pdf', function (req, res, next) {
  let body = req.body;

  let doc = new PDFDocument({ size: 'A4', autoFirstPage: false });
  let pdfName = 'pdf-' + Date.now() + '.pdf';

  doc.pipe(fs.createWriteStream(path.join(__dirname, '..', `/public/pdf/${pdfName}`));

  for (let name of body) {
    doc.addPage();
    doc.image(path.join(__dirname, '..', `/public/images/${name}`), 20, 20, {
      width: 555.28,
      align: 'center',
      valign: 'center',
    });
  }
  doc.end();

  res.send(`/pdf/${pdfName}`);
});

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'public/images');
  },
  filename: function (req, file, cb) {
    cb(null, file.fieldname + '-' + Date.now() + '.' + file.mimetype.split('/')[1]);
  },
});

const fileFilter = (req, file, callback) => {
  const ext = path.extname(file.originalname);
  if (ext !== '.png' && ext !== '.jpg') {
    return callback(new Error('Only png and jpg files are accepted'));
  } else {
    return callback(null, true);
  }
};

const upload = multer({ storage, fileFilter });

router.get('/new', async function (req, res, next) {
  let filenames = req.session.imagefiles;

  async function deleteFiles(paths) {
    const deleting = paths.map((file) => unlink(path.join(__dirname, '..', `/public/images/${file}`));
    await Promise.all(deleting);
  }

  try {
    await deleteFiles(filenames);
    req.session.imagefiles = undefined;
    res.redirect('/');
  } catch (error) {
    console.error('Error deleting files:', error);
    res.status(500).send('Error deleting files.');
  }
});

router.post('/upload', upload.array('images'), function (req, res) {
  const files = req.files;
  const imgNames = files.map((file) => file.filename);
  req.session.imagefiles = imgNames;
  res.redirect('/');
});

module.exports = router;
