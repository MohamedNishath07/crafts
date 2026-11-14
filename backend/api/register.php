<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/db.php';

$input = json_decode(file_get_contents('php://input'), true);
$fullName = trim($input['full_name'] ?? '');
$email = trim($input['email'] ?? '');
$phone = trim($input['phone'] ?? '');
$username = trim($input['username'] ?? '');
$password = $input['password'] ?? '';

if ($fullName === '' || $email === '' || $password === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid email']);
    exit;
}
if (strlen($password) < 6) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Password too short']);
    exit;
}

// email uniqueness
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['success' => false, 'message' => 'Email already registered']);
    exit;
}

// username uniqueness
$stmt = $pdo->prepare('SELECT id FROM users WHERE username = ?');
$stmt->execute([$username]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['success' => false, 'message' => 'Username already taken']);
    exit;
}

// default role Recovery (id 2)
$roleId = 2;
$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $pdo->prepare('INSERT INTO users (full_name, email, phone, username, password_hash, role_id) VALUES (?,?,?,?,?,?)');
$stmt->execute([$fullName, $email, $phone, $username, $hash, $roleId]);

echo json_encode(['success' => true, 'message' => 'Registration successful', 'user' => ['id' => (int)$pdo->lastInsertId(), 'full_name' => $fullName, 'email' => $email, 'username' => $username]]);
?>