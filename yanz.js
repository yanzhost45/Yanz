// WhatsApp Sticker Bot (Self-Reply Enabled)
// Run: node bot.js

const { default: makeWASocket, DisconnectReason, useMultiFileAuthState, downloadMediaMessage } = require('@whiskeysockets/baileys');
const qrcode = require('qrcode-terminal');
const pino = require('pino');
const sharp = require('sharp');
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');

const mediaFolder = './media';
if (!fs.existsSync(mediaFolder)) fs.mkdirSync(mediaFolder);

// ---- IMAGE PROCESSING ----
async function processImageToSticker(imagePath) {
    console.log(`🔄 Processing image: ${imagePath}`);
    const stickerPath = imagePath.replace(/\.[^/.]+$/, '_sticker.webp');
    await sharp(imagePath)
        .resize(512, 512, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
        .webp({ lossless: true, quality: 80 })
        .toFile(stickerPath);
    console.log(`✅ Image sticker created: ${stickerPath}`);
    return stickerPath;
}

// ---- VIDEO PROCESSING ----
async function processVideoToSticker(videoPath) {
    console.log(`🔄 Processing video: ${videoPath}`);
    const stickerPath = videoPath.replace(/\.[^/.]+$/, '_sticker.webp');
    return new Promise((resolve, reject) => {
        ffmpeg(videoPath)
            .outputOptions([
                '-vcodec libwebp',
                '-lossless 1',
                '-loop 0',
                '-preset default',
                '-an',
                '-vsync 0',
                '-s 512:512',
                '-t 10',
                '-r 10'
            ])
            .save(stickerPath)
            .on('end', () => {
                console.log(`✅ Video sticker created: ${stickerPath}`);
                resolve(stickerPath);
            })
            .on('error', (err) => {
                console.error(`❌ Video processing error: ${err.message}`);
                reject(err);
            });
    });
}

// ---- START BOT ----
async function startBot() {
    const { state, saveCreds } = await useMultiFileAuthState('./auth_info');
    const logger = pino({ level: 'info' });

    const sock = makeWASocket({
        auth: state,
        logger: logger,
        generateHighQualityLinkPreview: true
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;
        
        if (qr) {
            console.log('🔗 Scan QR Code di WhatsApp:');
            qrcode.generate(qr, { small: true });
        }
        
        if (connection === 'close') {
            const error = lastDisconnect?.error;
            const shouldReconnect = error?.output?.statusCode !== DisconnectReason.loggedOut;
            console.log('Connection closed due to ', error, ', reconnecting ', shouldReconnect);
            if (shouldReconnect) startBot();
        } else if (connection === 'open') {
            console.log('✅ Bot connected! Listening for messages...');
        }
    });

    sock.ev.on('messages.upsert', async ({ messages }) => {
        const msg = messages[0];
        if (!msg.message) return; // ✅ self-reply enabled, remove fromMe check

        const from = msg.key.remoteJid;
        const fromMe = msg.key.fromMe; // true jika pesan dari bot sendiri
        console.log(`📨 Received message from ${from} (fromMe=${fromMe}): Type = ${Object.keys(msg.message)[0] || 'text'}`);

        const text = msg.message.conversation || (msg.message.extendedTextMessage?.text || '');
        console.log(`   Text: "${text}"`);

        const isStickerCmd = text.trim().startsWith('.s');
        const hasQuoted = msg.message.extendedTextMessage?.contextInfo?.quotedMessage;
        console.log(`   Is .s command: ${isStickerCmd}, Has quoted: ${!!hasQuoted}`);

        // ---- PING TEST ----
        if (text.trim() === '.ping') {
            console.log('🏓 Ping received, replying...');
            await sock.sendMessage(from, { text: 'Pong! Bot hidup dan siap buat stiker. 😊' });
            return;
        }

        const quotedMsg = hasQuoted ? msg.message.extendedTextMessage.contextInfo.quotedMessage : null;
        const quotedKey = hasQuoted ? msg.message.extendedTextMessage.contextInfo.stanzaId : null;

        // ---- CASE 1: REPLY TO IMAGE/VIDEO ----
        if (isStickerCmd && quotedMsg) {
            const mediaType = Object.keys(quotedMsg)[0];
            if (mediaType === 'imageMessage' || mediaType === 'videoMessage') {
                console.log(`🔄 Processing replied ${mediaType === 'imageMessage' ? 'image' : 'video'}...`);
                let filePath, stickerPath;
                try {
                    const buffer = await downloadMediaMessage(quotedMsg, 'buffer', {});
                    if (buffer.length === 0) throw new Error('Empty media buffer');

                    const ext = mediaType === 'imageMessage' ? 'jpg' : 'mp4';
                    filePath = path.join(mediaFolder, `temp_${Date.now()}.${ext}`);
                    fs.writeFileSync(filePath, buffer);

                    if (mediaType === 'imageMessage') {
                        stickerPath = await processImageToSticker(filePath);
                    } else {
                        stickerPath = await processVideoToSticker(filePath);
                    }

                    const stickerBuffer = fs.readFileSync(stickerPath);
                    await sock.sendMessage(from, { 
                        sticker: stickerBuffer,
                        mimetype: 'image/webp'
                    }, hasQuoted && !fromMe ? { quoted: quotedKey } : {});
                    console.log('✅ Sticker sent successfully!');
                } catch (err) {
                    console.error('❌ Error processing media:', err.message);
                    await sock.sendMessage(from, { text: `❌ Gagal buat stiker: ${err.message}` });
                } finally {
                    if (filePath && fs.existsSync(filePath)) fs.unlinkSync(filePath);
                    if (stickerPath && fs.existsSync(stickerPath)) fs.unlinkSync(stickerPath);
                }
            }
        }

        // ---- CASE 2: IMAGE/VIDEO WITH .s CAPTION ----
        const msgType = Object.keys(msg.message)[0];
        const caption = msg.message.imageMessage?.caption || msg.message.videoMessage?.caption || '';

        if ((msgType === 'imageMessage' || msgType === 'videoMessage') && caption.trim().startsWith('.s')) {
            console.log(`🔄 Processing ${msgType === 'imageMessage' ? 'image' : 'video'} with .s caption...`);
            let filePath, stickerPath;
            try {
                const buffer = await downloadMediaMessage(msg, 'buffer', {});
                if (buffer.length === 0) throw new Error('Empty media buffer');

                const ext = msgType === 'imageMessage' ? 'jpg' : 'mp4';
                filePath = path.join(mediaFolder, `temp_${Date.now()}.${ext}`);
                fs.writeFileSync(filePath, buffer);

                if (msgType === 'imageMessage') {
                    stickerPath = await processImageToSticker(filePath);
                } else {
                    stickerPath = await processVideoToSticker(filePath);
                }

                const stickerBuffer = fs.readFileSync(stickerPath);
                await sock.sendMessage(from, { 
                    sticker: stickerBuffer,
                    mimetype: 'image/webp'
                });
                console.log('✅ Sticker sent successfully!');
            } catch (err) {
                console.error('❌ Error processing media:', err.message);
                await sock.sendMessage(from, { text: `❌ Gagal buat stiker: ${err.message}` });
            } finally {
                if (filePath && fs.existsSync(filePath)) fs.unlinkSync(filePath);
                if (stickerPath && fs.existsSync(stickerPath)) fs.unlinkSync(stickerPath);
            }
        }
    });
}

// ---- GLOBAL ERROR HANDLING ----
process.on('uncaughtException', console.error);
process.on('unhandledRejection', console.error);

// ---- RUN BOT ----
startBot().catch((err) => {
    console.error('Failed to start bot:', err);
});
