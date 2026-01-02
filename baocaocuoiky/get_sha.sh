#!/bin/bash

# Script để lấy SHA-1 và SHA-256 fingerprint cho Firebase
# Chạy script này và thêm SHA vào Firebase Console

echo "=========================================="
echo "Lấy SHA Fingerprint cho Firebase"
echo "=========================================="
echo ""

# Lấy SHA-1
echo "SHA-1 Fingerprint:"
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

echo ""
echo "SHA-256 Fingerprint:"
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256

echo ""
echo "=========================================="
echo "Hướng dẫn thêm SHA vào Firebase:"
echo "1. Vào https://console.firebase.google.com"
echo "2. Chọn project: baocaocuoiky-5851c"
echo "3. Vào Project Settings (⚙️) > Your apps"
echo "4. Click vào Android app (com.example.baocaocuoiky)"
echo "5. Click 'Add fingerprint'"
echo "6. Copy SHA-1 và SHA-256 ở trên và paste vào"
echo "7. Click 'Save'"
echo "=========================================="

