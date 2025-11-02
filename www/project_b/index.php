<?php
// www/project_b/index.php
// Contoh proyek PHP 7.4

echo "<h1>Selamat Datang di Proyek B (PHP 7.4)</h1>";
echo "<p>Ini adalah contoh proyek yang berjalan dengan PHP 7.4 FPM.</p>";

// Menampilkan informasi versi PHP
echo "<h2>Informasi PHP</h2>";
echo "<p>Versi PHP: " . phpversion() . "</p>";

// Koneksi ke database MySQL
echo "<h2>Koneksi Database MySQL</h2>";
$host = 'db-mysql';
$user = getenv('MYSQL_USER') ?: 'dev_user';
$password = getenv('MYSQL_PASSWORD') ?: 'dev_pass';
$database = getenv('MYSQL_DATABASE') ?: 'db_mysql';

// Membuat koneksi
$mysqli = new mysqli($host, $user, $password, $database);

// Memeriksa koneksi
if ($mysqli->connect_error) {
    echo "<p style='color: red;'>Koneksi MySQL gagal: " . $mysqli->connect_error . "</p>";
} else {
    echo "<p style='color: green;'>Koneksi MySQL berhasil!</p>";
    
    // Mengecek apakah tabel users ada
    $result = $mysqli->query("SHOW TABLES LIKE 'users'");
    if ($result && $result->num_rows > 0) {
        echo "<p>Tabel 'users' ditemukan.</p>";
        
        // Mengambil data dari tabel users
        $users_result = $mysqli->query("SELECT * FROM users LIMIT 5");
        if ($users_result && $users_result->num_rows > 0) {
            echo "<h3>Data Pengguna:</h3>";
            echo "<ul>";
            while ($row = $users_result->fetch_assoc()) {
                echo "<li>" . htmlspecialchars($row['username']) . " (" . htmlspecialchars($row['email']) . ")</li>";
            }
            echo "</ul>";
        }
    } else {
        echo "<p>Tabel 'users' tidak ditemukan.</p>";
    }
}

$mysqli->close();

// Koneksi ke database PostgreSQL
echo "<h2>Koneksi Database PostgreSQL</h2>";
$host = 'db-postgre';
$user = getenv('POSTGRES_USER') ?: 'dev_user';
$password = getenv('POSTGRES_PASSWORD') ?: 'dev_pass';
$database = getenv('POSTGRES_DB') ?: 'db_postgre';

// Membuat koneksi
$dsn = "pgsql:host=$host;dbname=$database";
try {
    $pdo = new PDO($dsn, $user, $password);
    echo "<p style='color: green;'>Koneksi PostgreSQL berhasil!</p>";
    
    // Mengecek apakah tabel users ada
    $stmt = $pdo->query("SELECT tablename FROM pg_catalog.pg_tables WHERE tablename = 'users'");
    if ($stmt && $stmt->rowCount() > 0) {
        echo "<p>Tabel 'users' ditemukan.</p>";
        
        // Mengambil data dari tabel users
        $users_stmt = $pdo->query("SELECT * FROM users LIMIT 5");
        if ($users_stmt) {
            echo "<h3>Data Pengguna:</h3>";
            echo "<ul>";
            while ($row = $users_stmt->fetch(PDO::FETCH_ASSOC)) {
                echo "<li>" . htmlspecialchars($row['username']) . " (" . htmlspecialchars($row['email']) . ")</li>";
            }
            echo "</ul>";
        }
    } else {
        echo "<p>Tabel 'users' tidak ditemukan.</p>";
    }
} catch (PDOException $e) {
    echo "<p style='color: red;'>Koneksi PostgreSQL gagal: " . $e->getMessage() . "</p>";
}

echo "<h2>Informasi Server</h2>";
echo "<p>Server Software: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Server Address: " . $_SERVER['SERVER_ADDR'] . "</p>";
echo "<p>Server Port: " . $_SERVER['SERVER_PORT'] . "</p>";

echo "<h2>Informasi Tambahan</h2>";
echo "<p>Waktu Server: " . date('Y-m-d H:i:s') . "</p>";
?>