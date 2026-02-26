/**
 * MongoDB Backup Script
 * 
 * mongodump yordamida backup yaratish va eski backuplarni tozalash.
 * 
 * Ishlatish:
 *   node scripts/backup.js
 * 
 * Environment:
 *   MONGODB_URI - MongoDB connection string (required)
 *   BACKUP_DIR  - Backup katalogi (default: ./backups)
 *   BACKUP_RETENTION_DAYS - Necha kunlik (default: 7)
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Config
const MONGODB_URI = process.env.MONGODB_URI;
const BACKUP_DIR = process.env.BACKUP_DIR || path.join(__dirname, '..', 'backups');
const RETENTION_DAYS = parseInt(process.env.BACKUP_RETENTION_DAYS) || 7;

if (!MONGODB_URI) {
    console.error('❌ MONGODB_URI environment variable majburiy');
    process.exit(1);
}

// Timestamp
const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
const backupPath = path.join(BACKUP_DIR, `backup-${timestamp}`);

// Backup katalogini yaratish
if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

console.log(`📦 Backup boshlanmoqda: ${backupPath}`);
console.log(`📅 Retention: ${RETENTION_DAYS} kun`);

try {
    // mongodump ishga tushirish
    execSync(
        `mongodump --uri="${MONGODB_URI}" --out="${backupPath}" --gzip`,
        { stdio: 'inherit' }
    );
    console.log(`✅ Backup muvaffaqiyatli yaratildi: ${backupPath}`);
} catch (err) {
    console.error('❌ Backup xatosi:', err.message);
    process.exit(1);
}

// Eski backuplarni tozalash
try {
    const cutoff = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;
    const dirs = fs.readdirSync(BACKUP_DIR)
        .filter(d => d.startsWith('backup-'))
        .map(d => ({
            name: d,
            path: path.join(BACKUP_DIR, d),
            stat: fs.statSync(path.join(BACKUP_DIR, d))
        }))
        .filter(d => d.stat.isDirectory() && d.stat.mtimeMs < cutoff);

    for (const dir of dirs) {
        fs.rmSync(dir.path, { recursive: true, force: true });
        console.log(`🗑️ Eski backup o'chirildi: ${dir.name}`);
    }

    if (dirs.length === 0) {
        console.log(`📋 O'chiriladigan eski backup yo'q`);
    }
} catch (err) {
    console.warn('⚠️ Eski backuplarni tozalashda xato:', err.message);
}

console.log('✅ Backup jarayoni tugadi');
