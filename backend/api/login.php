<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/db.php';

$input = json_decode(file_get_contents('php://input'), true);
$identifier = trim($input['identifier'] ?? $input['email'] ?? $input['username'] ?? '');
$password = $input['password'] ?? '';

if ($identifier === '' || $password === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

$stmt = $pdo->prepare('SELECT id, full_name, email, username, password_hash FROM users WHERE email = ? OR username = ? LIMIT 1');
$stmt->execute([$identifier, $identifier]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
    exit;
}

echo json_encode(['success' => true, 'message' => 'Login successful', 'user' => [
    'id' => (int)$user['id'],
    'full_name' => $user['full_name'],
    'email' => $user['email'],
    'username' => $user['username'],
]]);
?>