package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"split_backend/internal/auth"
	"split_backend/internal/db"
	"split_backend/internal/middleware"
)

type fakeUserQuerier struct {
	users     map[string]db.User
	createErr error
	getErr    error
}

func newFakeUserQuerier() *fakeUserQuerier {
	return &fakeUserQuerier{
		users: make(map[string]db.User),
	}
}

func (f *fakeUserQuerier) CreateUser(ctx context.Context, arg db.CreateUserParams) (db.User, error) {
	if f.createErr != nil {
		return db.User{}, f.createErr
	}
	if _, exists := f.users[arg.Email]; exists {
		return db.User{}, errors.New("duplicate key value violates unique constraint")
	}
	u := db.User{
		ID:           pgtype.UUID{Bytes: [16]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true},
		Email:        arg.Email,
		PasswordHash: arg.PasswordHash,
		FullName:     arg.FullName,
	}
	f.users[arg.Email] = u
	return u, nil
}

func (f *fakeUserQuerier) GetUserByEmail(ctx context.Context, email string) (db.User, error) {
	if f.getErr != nil {
		return db.User{}, f.getErr
	}
	u, exists := f.users[email]
	if !exists {
		return db.User{}, pgx.ErrNoRows
	}
	return u, nil
}

func setupTestRouter(dbQuerier UserQuerier, secret string) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	logger := slog.New(slog.NewJSONHandler(httptest.NewRecorder(), nil))
	authH := NewAuthHandler(dbQuerier, secret, logger)
	api := r.Group("/api")
	{
		api.POST("/signup", authH.SignUp)
		api.POST("/signin", authH.SignIn)

		protected := api.Group("", middleware.JWTMiddleware(secret, logger))
		{
			protected.GET("/me", authH.GetCurrentUser)
		}
	}
	return r
}

func TestSignUp(t *testing.T) {
	tests := []struct {
		name           string
		rawBody        []byte
		payload        any
		setupQuerier   func() UserQuerier
		expectedStatus int
		checkResp      func(t *testing.T, body []byte)
	}{
		{
			name: "Success",
			payload: SignUpRequest{
				FullName: "John Doe",
				Email:    "john@example.com",
				Password: "password123",
			},
			setupQuerier:   func() UserQuerier { return newFakeUserQuerier() },
			expectedStatus: http.StatusCreated,
			checkResp: func(t *testing.T, body []byte) {
				var resp SuccessEnvelope
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to unmarshal JSON: %v", err)
				}
				if resp.Error != nil {
					t.Errorf("expected error nil, got %v", resp.Error)
				}
				dataMap, ok := resp.Data.(map[string]interface{})
				if !ok {
					t.Fatalf("unexpected data format: %v", resp.Data)
				}
				token, _ := dataMap["token"].(string)
				if strings.Count(token, ".") != 2 {
					t.Errorf("expected 3-part cryptographic JWT token, got %s", token)
				}
			},
		},
		{
			name:           "Invalid JSON",
			rawBody:        []byte("{invalid json"),
			setupQuerier:   func() UserQuerier { return newFakeUserQuerier() },
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "Missing Email",
			payload: SignUpRequest{
				FullName: "John Doe",
				Password: "password123",
			},
			setupQuerier:   func() UserQuerier { return newFakeUserQuerier() },
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "Duplicate Email",
			payload: SignUpRequest{
				FullName: "John Doe",
				Email:    "existing@example.com",
				Password: "password123",
			},
			setupQuerier: func() UserQuerier {
				fq := newFakeUserQuerier()
				fq.users["existing@example.com"] = db.User{Email: "existing@example.com"}
				return fq
			},
			expectedStatus: http.StatusConflict,
		},
		{
			name: "Password Too Short",
			payload: SignUpRequest{
				FullName: "John Doe",
				Email:    "short@example.com",
				Password: "123",
			},
			setupQuerier:   func() UserQuerier { return newFakeUserQuerier() },
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "DB Error",
			payload: SignUpRequest{
				FullName: "John Doe",
				Email:    "error@example.com",
				Password: "password123",
			},
			setupQuerier: func() UserQuerier {
				fq := newFakeUserQuerier()
				fq.createErr = errors.New("unexpected db failure")
				return fq
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			r := setupTestRouter(tc.setupQuerier(), "test-secret")
			var body []byte
			if tc.rawBody != nil {
				body = tc.rawBody
			} else {
				body, _ = json.Marshal(tc.payload)
			}
			req, _ := http.NewRequest(http.MethodPost, "/api/signup", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code != tc.expectedStatus {
				t.Errorf("expected status %d, got %d. Body: %s", tc.expectedStatus, w.Code, w.Body.String())
			}
			if tc.checkResp != nil {
				tc.checkResp(t, w.Body.Bytes())
			}
		})
	}
}

func TestSignIn(t *testing.T) {
	fq := newFakeUserQuerier()
	r := setupTestRouter(fq, "test-secret")

	signupReq := SignUpRequest{FullName: "Jane Doe", Email: "jane@example.com", Password: "validpassword123"}
	data, _ := json.Marshal(signupReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/signup", bytes.NewReader(data))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	tests := []struct {
		name           string
		rawBody        []byte
		payload        any
		setupQuerier   func() UserQuerier
		expectedStatus int
		checkResp      func(t *testing.T, body []byte)
	}{
		{
			name: "Success",
			payload: SignInRequest{
				Email:    "jane@example.com",
				Password: "validpassword123",
			},
			setupQuerier:   func() UserQuerier { return fq },
			expectedStatus: http.StatusOK,
			checkResp: func(t *testing.T, body []byte) {
				var resp SuccessEnvelope
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to unmarshal JSON: %v", err)
				}
				dataMap, ok := resp.Data.(map[string]interface{})
				if !ok {
					t.Fatalf("unexpected data format: %v", resp.Data)
				}
				token, _ := dataMap["token"].(string)
				if strings.Count(token, ".") != 2 {
					t.Errorf("expected 3-part cryptographic JWT token, got %s", token)
				}
			},
		},
		{
			name:           "Invalid JSON",
			rawBody:        []byte("{invalid json"),
			setupQuerier:   func() UserQuerier { return fq },
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "Missing Password",
			payload: SignInRequest{
				Email: "jane@example.com",
			},
			setupQuerier:   func() UserQuerier { return fq },
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "Invalid Password",
			payload: SignInRequest{
				Email:    "jane@example.com",
				Password: "wrongpassword",
			},
			setupQuerier:   func() UserQuerier { return fq },
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name: "User Not Found",
			payload: SignInRequest{
				Email:    "nonexistent@example.com",
				Password: "somepassword",
			},
			setupQuerier:   func() UserQuerier { return fq },
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name: "DB Error",
			payload: SignInRequest{
				Email:    "error@example.com",
				Password: "password123",
			},
			setupQuerier: func() UserQuerier {
				errFq := newFakeUserQuerier()
				errFq.getErr = errors.New("unexpected db failure")
				return errFq
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			router := setupTestRouter(tc.setupQuerier(), "test-secret")
			var body []byte
			if tc.rawBody != nil {
				body = tc.rawBody
			} else {
				body, _ = json.Marshal(tc.payload)
			}
			req, _ := http.NewRequest(http.MethodPost, "/api/signin", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if w.Code != tc.expectedStatus {
				t.Errorf("expected status %d, got %d. Body: %s", tc.expectedStatus, w.Code, w.Body.String())
			}
			if tc.checkResp != nil {
				tc.checkResp(t, w.Body.Bytes())
			}
		})
	}
}

func TestGetCurrentUser(t *testing.T) {
	fq := newFakeUserQuerier()
	secret := "test-secret-key"
	r := setupTestRouter(fq, secret)

	// Create user
	u, _ := fq.CreateUser(context.Background(), db.CreateUserParams{
		Email:        "me@example.com",
		PasswordHash: "hashed",
		FullName:     "Me User",
	})
	userIdStr := formatUUID(u.ID)
	token, _ := auth.GenerateToken(userIdStr, u.Email, secret, 1*time.Hour)

	t.Run("Success with valid token", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodGet, "/api/me", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d. body: %s", w.Code, w.Body.String())
		}
		var resp SuccessEnvelope
		json.Unmarshal(w.Body.Bytes(), &resp)
		dataMap := resp.Data.(map[string]interface{})
		if dataMap["email"] != "me@example.com" || dataMap["full_name"] != "Me User" {
			t.Errorf("unexpected user data: %v", resp.Data)
		}
	})

	t.Run("Unauthorized with missing token", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodGet, "/api/me", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Errorf("expected status 401, got %d", w.Code)
		}
	})

	t.Run("User deleted after token issued", func(t *testing.T) {
		delete(fq.users, "me@example.com")
		req, _ := http.NewRequest(http.MethodGet, "/api/me", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Errorf("expected status 401 when user deleted from db, got %d", w.Code)
		}
	})
}
