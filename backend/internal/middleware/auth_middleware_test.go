package middleware

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"split_backend/internal/auth"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func setupTestRouter(secret string) *gin.Engine {
	r := gin.New()
	r.Use(JWTMiddleware(secret, nil))
	r.GET("/protected", func(c *gin.Context) {
		userID := c.GetString("user_id")
		email := c.GetString("user_email")
		c.JSON(http.StatusOK, gin.H{
			"user_id": userID,
			"email":   email,
		})
	})
	return r
}

func TestJWTMiddlewareSuccess(t *testing.T) {
	secret := "my-secret-key"
	router := setupTestRouter(secret)

	token, err := auth.GenerateToken("user-123", "test@example.com", secret, 1*time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}

	req := httptest.NewRequest("GET", "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d. body: %s", w.Code, w.Body.String())
	}

	var resp map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}
	if resp["user_id"] != "user-123" || resp["email"] != "test@example.com" {
		t.Errorf("unexpected response body: %v", resp)
	}
}

func TestJWTMiddlewareErrors(t *testing.T) {
	secret := "my-secret-key"
	router := setupTestRouter(secret)

	tests := []struct {
		name         string
		authHeader   string
		expectedCode int
	}{
		{
			name:         "Missing Header",
			authHeader:   "",
			expectedCode: http.StatusUnauthorized,
		},
		{
			name:         "Invalid Scheme",
			authHeader:   "Basic dXNlcjpwYXNz",
			expectedCode: http.StatusUnauthorized,
		},
		{
			name:         "Empty Bearer Token",
			authHeader:   "Bearer   ",
			expectedCode: http.StatusUnauthorized,
		},
		{
			name:         "Invalid Token String",
			authHeader:   "Bearer invalid-jwt-token",
			expectedCode: http.StatusUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/protected", nil)
			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedCode {
				t.Errorf("expected status %d, got %d. body: %s", tt.expectedCode, w.Code, w.Body.String())
			}
		})
	}
}
