package auth

import (
	"testing"
	"time"
)

func TestJWTGenerateAndValidate(t *testing.T) {
	secret := "test-secret-key-12345"
	userID := "user-uuid-123"
	email := "test@example.com"

	token, err := GenerateToken(userID, email, secret, 1*time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}
	if token == "" {
		t.Fatal("expected token string, got empty string")
	}

	claims, err := ValidateToken(token, secret)
	if err != nil {
		t.Fatalf("ValidateToken failed: %v", err)
	}
	if claims.UserID != userID || claims.Email != email {
		t.Errorf("expected claims UserID=%s Email=%s, got UserID=%s Email=%s", userID, email, claims.UserID, claims.Email)
	}
}

func TestValidateTokenErrors(t *testing.T) {
	secret := "test-secret"
	token, _ := GenerateToken("id", "test@example.com", secret, 1*time.Hour)

	// Test invalid secret
	if _, err := ValidateToken(token, "wrong-secret"); err == nil {
		t.Error("expected error with wrong secret, got nil")
	}

	// Test empty secret on generate
	if _, err := GenerateToken("id", "email", "", 1*time.Hour); err == nil {
		t.Error("expected error with empty secret on generate, got nil")
	}

	// Test empty secret on validate
	if _, err := ValidateToken(token, ""); err == nil {
		t.Error("expected error with empty secret on validate, got nil")
	}

	// Test malformed token
	if _, err := ValidateToken("invalid.token.string", secret); err == nil {
		t.Error("expected error with malformed token, got nil")
	}

	// Test expired token
	expiredToken, _ := GenerateToken("id", "email", secret, -1*time.Second)
	if _, err := ValidateToken(expiredToken, secret); err == nil {
		t.Error("expected error with expired token, got nil")
	}
}
