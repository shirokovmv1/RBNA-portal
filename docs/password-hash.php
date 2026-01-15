<?php
// CLI usage: php password-hash.php "YourPassword"
// Outputs a password_hash compatible with api/auth.php

$password = $argv[1] ?? '';
if (!$password) {
    fwrite(STDERR, "Usage: php password-hash.php \"YourPassword\"\n");
    exit(1);
}

echo password_hash($password, PASSWORD_DEFAULT) . PHP_EOL;
