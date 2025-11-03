//server.js
require('dotenv').config(); // Load .env file

const multer = require('multer');
const { Storage } = require('@google-cloud/storage');
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const admin = require('firebase-admin'); // <- NEW

const app = express();

/* ========================
   CORS / middleware
======================== */
app.use(cors()); // 先全開，之後要上線再縮
app.use(express.json());

/* ========================
   GCS setup (avatar upload)
======================== */
let storage;
if (process.env.GCP_SERVICE_ACCOUNT_JSON) {
    const creds = JSON.parse(process.env.GCP_SERVICE_ACCOUNT_JSON);
    storage = new Storage({
        projectId: creds.project_id,
        credentials: {
            client_email: creds.client_email,
            private_key: creds.private_key,
        },
    });

    // 🔥 Firestore 也用同一組 creds
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: creds.project_id,
                clientEmail: creds.client_email,
                privateKey: creds.private_key,
            }),
        });
    }
} else {
    // fallback: GOOGLE_APPLICATION_CREDENTIALS
    storage = new Storage();
    if (!admin.apps.length) {
        admin.initializeApp(); // 會自動吃 GOOGLE_APPLICATION_CREDENTIALS
    }
}

// Firestore DB handle
const db = admin.firestore();

const BUCKET_NAME =
    process.env.GCP_BUCKET_NAME || 'htwg-cloudapp-hw.firebasestorage.app';

const upload = multer({ storage: multer.memoryStorage() });

// 上傳頭貼
app.post('/api/upload-avatar', upload.single('avatar'), async (req, res) => {
    try {
        const email = req.body.email;
        const file = req.file;

        if (!email) {
            return res.status(400).send({ message: 'Missing email.' });
        }
        if (!file) {
            return res.status(400).send({ message: 'Missing avatar file.' });
        }

        // 只收 JPEG (前端我們會轉成 jpeg 上傳)
        if (
            file.mimetype !== 'image/jpeg' &&
            file.mimetype !== 'image/jpg'
        ) {
            return res.status(400).send({ message: 'Only JPEG allowed.' });
        }

        const destFileName = `avatar/${email}.jpg`;

        const bucket = storage.bucket(BUCKET_NAME);
        const gcFile = bucket.file(destFileName);

        await gcFile.save(file.buffer, {
            metadata: {
                contentType: 'image/jpeg',
                cacheControl: 'public, max-age=3600',
            },
            resumable: false,
        });

        // bucket 如果本身就是 public 可以不用，但保險一次
        await gcFile.makePublic().catch(() => {});

        return res.status(200).send({ message: 'Avatar uploaded.' });
    } catch (err) {
        console.error('Upload avatar error:', err);
        return res.status(500).send({ message: 'Failed to upload avatar.' });
    }
});

/* ========================
   MySQL helpers
======================== */

function formatDate(date) {
    if (!date) return null;

    const d = new Date(date);
    d.setDate(d.getDate()); // 原本就這樣寫的：+0天 (你之前+1天，現在保留你現有邏輯)

    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');

    return `${year}/${month}/${day}`;
}

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
});

/* ========================
   Core APIs (register, trips, etc)
======================== */

// 1. 註冊 / 登入
app.post('/api/register', async (req, res) => {
    const { email, name } = req.body;
    if (!email || !name) {
        return res
            .status(400)
            .send({ message: 'Email and name are required.' });
    }
    try {
        const [result] = await pool.execute(
            'INSERT INTO travellers (email, name) VALUES (?, ?)',
            [email, name],
        );
        res.status(201).send({
            id: result.insertId,
            email,
            name,
            message: 'Registration successful.',
        });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            const [traveller] = await pool.execute(
                'SELECT id, email, name FROM travellers WHERE email = ?',
                [email],
            );
            if (traveller.length > 0) {
                return res.status(409).send({
                    message: 'Email already exists. Logged in successfully.',
                    id: traveller[0].id,
                    email: traveller[0].email,
                    name: traveller[0].name,
                });
            }
            return res
                .status(409)
                .send({ message: 'Email already exists.' });
        }
        console.error(error);
        res
            .status(500)
            .send({ message: 'Server error during registration.' });
    }
});

// 2. 建立行程
app.post('/api/itineraries', async (req, res) => {
    const {
        traveller_email,
        title,
        destination,
        start_date,
        end_date,
        short_description,
        detail_description,
    } = req.body;

    if (
        !title ||
        !destination ||
        !start_date ||
        !end_date ||
        short_description.length > 80 ||
        !traveller_email
    ) {
        return res.status(400).send({
            message:
                'Missing required fields, invalid input, or short description too long. (Requires traveller_email and end_date)',
        });
    }

    try {
        const [traveller] = await pool.execute(
            'SELECT id FROM travellers WHERE email = ?',
            [traveller_email],
        );
        if (traveller.length === 0) {
            return res
                .status(404)
                .send({ message: 'Traveller not found with this email.' });
        }
        const traveller_id = traveller[0].id;

        const [result] = await pool.execute(
            'INSERT INTO itineraries (traveller_id, title, destination, start_date, end_date, short_description, detail_description) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
                traveller_id,
                title,
                destination,
                start_date,
                end_date,
                short_description,
                detail_description,
            ],
        );
        res
            .status(201)
            .send({ id: result.insertId, message: 'Itinerary created successfully.' });
    } catch (error) {
        console.error(error);
        res
            .status(500)
            .send({ message: 'Server error during itinerary creation.' });
    }
});

// 3b. 取得行程列表
app.get('/api/itineraries/by-email/:email', async (req, res) => {
    const { email } = req.params;
    try {
        const [rows] = await pool.execute(
            `
      SELECT i.id, i.title, i.start_date, i.end_date, i.short_description, t.email AS traveller_email
      FROM itineraries i
      JOIN travellers t ON i.traveller_id = t.id
      ORDER BY i.start_date DESC
    `,
            [email],
        );

        const formattedRows = rows.map((row) => ({
            ...row,
            start_date: formatDate(row.start_date),
            end_date: formatDate(row.end_date),
        }));

        res.send(formattedRows);
    } catch (error) {
        console.error(error);
        res.status(500).send({
            message: 'Server error retrieving itineraries by email.',
        });
    }
});

// 4. 行程詳細
app.get('/api/itineraries/detail/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const [rows] = await pool.execute(
            `
      SELECT i.*, t.email AS traveller_email
      FROM itineraries i
      JOIN travellers t ON i.traveller_id = t.id
      WHERE i.id = ?
    `,
            [id],
        );

        if (rows.length === 0) {
            return res.status(404).send({ message: 'Itinerary not found.' });
        }

        const itinerary = rows[0];
        itinerary.start_date = formatDate(itinerary.start_date);
        itinerary.end_date = formatDate(itinerary.end_date);

        res.send(itinerary);
    } catch (error) {
        console.error(error);
        res
            .status(500)
            .send({ message: 'Server error retrieving itinerary detail.' });
    }
});

// 5. 編輯
app.put('/api/itineraries/:id', async (req, res) => {
    const { id } = req.params;
    const {
        title,
        destination,
        start_date,
        end_date,
        short_description,
        detail_description,
        traveller_email,
    } = req.body;

    if (
        !title ||
        !destination ||
        !start_date ||
        !end_date ||
        short_description.length > 80 ||
        !traveller_email
    ) {
        return res.status(400).send({
            message: 'Missing required fields or traveller_email.',
        });
    }

    try {
        // 授權檢查
        const [rows] = await pool.execute(
            `
      SELECT i.id
      FROM itineraries i
      JOIN travellers t ON i.traveller_id = t.id
      WHERE i.id = ? AND t.email = ?
    `,
            [id, traveller_email],
        );

        if (rows.length === 0) {
            return res.status(403).send({
                message: 'You are not the owner of this itinerary.',
            });
        }

        const [result] = await pool.execute(
            `
      UPDATE itineraries SET
        title = ?,
        destination = ?,
        start_date = ?,
        end_date = ?,
        short_description = ?,
        detail_description = ?
      WHERE id = ?
    `,
            [
                title,
                destination,
                start_date,
                end_date,
                short_description,
                detail_description,
                id,
            ],
        );

        if (result.affectedRows === 0) {
            return res.status(404).send({
                message: 'Itinerary not found or no changes made.',
            });
        }

        res.send({ message: `Itinerary ID ${id} updated successfully.` });
    } catch (error) {
        console.error(error);
        res
            .status(500)
            .send({ message: 'Server error during itinerary update.' });
    }
});

// 6. 刪除
app.delete('/api/itineraries/:id', async (req, res) => {
    const { id } = req.params;
    const { traveller_email } = req.body;

    if (!traveller_email) {
        return res.status(400).send({
            message: 'Missing traveller_email for authorization.',
        });
    }

    try {
        // 授權檢查
        const [rows] = await pool.execute(
            `
      SELECT i.id
      FROM itineraries i
      JOIN travellers t ON i.traveller_id = t.id
      WHERE i.id = ? AND t.email = ?
    `,
            [id, traveller_email],
        );

        if (rows.length === 0) {
            return res.status(403).send({
                message: 'You are not authorized to delete this itinerary.',
            });
        }

        const [result] = await pool.execute(
            'DELETE FROM itineraries WHERE id = ?',
            [id],
        );

        if (result.affectedRows === 0) {
            return res
                .status(404)
                .send({ message: 'Itinerary not found.' });
        }

        res.send({ message: `Itinerary ID ${id} deleted successfully.` });
    } catch (error) {
        console.error(error);
        res
            .status(500)
            .send({ message: 'Server error during itinerary deletion.' });
    }
});

/* ========================
   NEW: Likes API (Firestore)
======================== */

/**
 * Toggle like for this itinerary by this user.
 * Body: { userEmail: "a@b.com" }
 */
app.post('/api/itineraries/:id/like/toggle', async (req, res) => {
    try {
        const itineraryId = req.params.id;
        const userEmail = req.body.userEmail;

        if (!userEmail) {
            return res
                .status(400)
                .send({ message: 'Missing userEmail in body.' });
        }

        // doc path: likes/{itineraryId}/userLikes/{userEmail}
        const likeDocRef = db
            .collection('likes')
            .doc(itineraryId)
            .collection('userLikes')
            .doc(userEmail);

        const snap = await likeDocRef.get();

        if (snap.exists) {
            // already liked -> remove like
            await likeDocRef.delete();
            return res.send({ liked: false });
        } else {
            // not liked -> add like
            await likeDocRef.set({
                email: userEmail,
                liked_at: Date.now(), // 簡單 timestamp，用 ms 整數，不用 serverTimestamp
            });
            return res.send({ liked: true });
        }
    } catch (err) {
        console.error('toggle like error:', err);
        return res.status(500).send({ message: 'Like failed' });
    }
});

/**
 * Get like count for itinerary
 */
app.get('/api/itineraries/:id/like/count', async (req, res) => {
    try {
        const itineraryId = req.params.id;

        const qs = await db
            .collection('likes')
            .doc(itineraryId)
            .collection('userLikes')
            .get();

        const count = qs.size;
        return res.send({ count });
    } catch (err) {
        console.error('get like count error:', err);
        return res.status(500).send({ message: 'Failed to get like count' });
    }
});

/**
 * Get who liked (for popup)
 */
app.get('/api/itineraries/:id/like/list', async (req, res) => {
    try {
        const itineraryId = req.params.id;

        const qs = await db
            .collection('likes')
            .doc(itineraryId)
            .collection('userLikes')
            .get();

        const users = qs.docs.map((doc) => ({
            email: doc.id,
            ...doc.data(),
        }));

        return res.send({ users });
    } catch (err) {
        console.error('get like list error:', err);
        return res.status(500).send({ message: 'Failed to get like list' });
    }
});

/* ========================
   NEW: Comments API (Firestore)
   collection path:
   comments/{itineraryId}/items/{autoId}

   each comment doc:
   {
     email: string,
     text: string,
     created_at: number (Date.now())
   }
======================== */

/**
 * 取得某個行程的所有留言 (照 created_at 由新到舊或舊到新，你決定)
 * GET /api/itineraries/:id/comments
 */
app.get('/api/itineraries/:id/comments', async (req, res) => {
    try {
        const itineraryId = req.params.id;

        // comments/{itineraryId}/items/*
        const qs = await db
            .collection('comments')
            .doc(itineraryId)
            .collection('items')
            .orderBy('created_at', 'asc') // 最舊在上，想反過來就 'desc'
            .get();

        const comments = qs.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        return res.send({ comments });
    } catch (err) {
        console.error('get comments error:', err);
        return res.status(500).send({ message: 'Failed to load comments' });
    }
});

/**
 * 新增留言
 * POST /api/itineraries/:id/comments
 * body: { userEmail: string, text: string }
 */
app.post('/api/itineraries/:id/comments', async (req, res) => {
    try {
        const itineraryId = req.params.id;
        const { userEmail, text } = req.body;

        if (!userEmail || !text || !text.trim()) {
            return res.status(400).send({ message: 'Missing userEmail or text' });
        }

        // push comment
        const newDocRef = await db
            .collection('comments')
            .doc(itineraryId)
            .collection('items')
            .add({
                email: userEmail,
                text: text.trim(),
                created_at: Date.now()
            });

        return res.status(201).send({
            id: newDocRef.id,
            email: userEmail,
            text: text.trim(),
            created_at: Date.now()
        });
    } catch (err) {
        console.error('add comment error:', err);
        return res.status(500).send({ message: 'Failed to add comment' });
    }
});

/**
 * 刪除自己的留言
 * DELETE /api/itineraries/:id/comments/:commentId
 * body: { userEmail: string }
 */
app.delete('/api/itineraries/:id/comments/:commentId', async (req, res) => {
    try {
        const itineraryId = req.params.id;
        const commentId = req.params.commentId;
        const { userEmail } = req.body;

        if (!userEmail) {
            return res.status(400).send({ message: 'Missing userEmail' });
        }

        const commentRef = db
            .collection('comments')
            .doc(itineraryId)
            .collection('items')
            .doc(commentId);

        const snap = await commentRef.get();
        if (!snap.exists) {
            return res.status(404).send({ message: 'Comment not found' });
        }

        const data = snap.data();
        if (data.email !== userEmail) {
            return res.status(403).send({ message: 'Not allowed to delete this comment' });
        }

        await commentRef.delete();
        return res.send({ message: 'Comment deleted' });
    } catch (err) {
        console.error('delete comment error:', err);
        return res.status(500).send({ message: 'Failed to delete comment' });
    }
});


/* ========================
   start server
======================== */
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

app.listen(PORT, HOST, () => {
    console.log(`Backend running at http://${HOST}:${PORT}`);
});