package handler

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"golang.org/x/crypto/bcrypt"

	"split_backend/internal/auth"
	"split_backend/internal/db"
)

// UserQuerier defines the database interface required by AuthHandler.
type UserQuerier interface {
	CreateUser(ctx context.Context, arg db.CreateUserParams) (db.User, error)
	GetUserByEmail(ctx context.Context, email string) (db.User, error)
}

// AuthHandler handles user authentication requests.
type AuthHandler struct {
	db        UserQuerier
	jwtSecret string
	logger    *slog.Logger
}

// NewAuthHandler creates a new AuthHandler instance with explicit dependency injection.
func NewAuthHandler(db UserQuerier, jwtSecret string, logger *slog.Logger) *AuthHandler {
	return &AuthHandler{
		db:        db,
		jwtSecret: jwtSecret,
		logger:    logger,
	}
}

type SignUpRequest struct {
	FullName string `json:"full_name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type SignInRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type UserResponse struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	FullName string `json:"full_name"`
}

type AuthDataResponse struct {
	Token string       `json:"token"`
	User  UserResponse `json:"user"`
}

type ErrorEnvelope struct {
	Data  any `json:"data"`
	Error struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

type SuccessEnvelope struct {
	Data  any `json:"data"`
	Error any `json:"error"`
}

func sendError(c *gin.Context, status int, code, message string) {
	c.JSON(status, ErrorEnvelope{
		Data: nil,
		Error: struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		}{
			Code:    code,
			Message: message,
		},
	})
}

func sendSuccess(c *gin.Context, status int, data any) {
	c.JSON(status, SuccessEnvelope{
		Data:  data,
		Error: nil,
	})
}

func formatUUID(u pgtype.UUID) string {
	if !u.Valid {
		return ""
	}
	b := u.Bytes
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

// SignUp handles POST /api/signup endpoint.
func (h *AuthHandler) SignUp(c *gin.Context) {
	var req SignUpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid JSON payload")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	req.FullName = strings.TrimSpace(req.FullName)

	if req.Email == "" || req.Password == "" {
		sendError(c, http.StatusBadRequest, "invalid_input", "Email and password are required")
		return
	}
	if len(req.Password) < 8 {
		sendError(c, http.StatusBadRequest, "invalid_input", "Password must be at least 8 characters")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to hash password", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "internal_error", "Failed to process password")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	user, err := h.db.CreateUser(ctx, db.CreateUserParams{
		Email:        req.Email,
		PasswordHash: string(hash),
		FullName:     req.FullName,
	})
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "23505") || strings.Contains(err.Error(), "UNIQUE constraint failed") {
			sendError(c, http.StatusConflict, "email_taken", "An account with this email already exists")
			return
		}
		if h.logger != nil {
			h.logger.Error("failed to create user in database", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to create account")
		return
	}

	if h.logger != nil {
		h.logger.Info("user signed up successfully", slog.String("user_id", formatUUID(user.ID)), slog.String("email", user.Email))
	}

	userIdStr := formatUUID(user.ID)
	token, err := auth.GenerateToken(userIdStr, user.Email, h.jwtSecret, 7*24*time.Hour)
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to generate jwt token on signup", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "internal_error", "Failed to generate authentication token")
		return
	}

	sendSuccess(c, http.StatusCreated, AuthDataResponse{
		Token: token,
		User: UserResponse{
			ID:       userIdStr,
			Email:    user.Email,
			FullName: user.FullName,
		},
	})
}

// SignIn handles POST /api/signin endpoint.
func (h *AuthHandler) SignIn(c *gin.Context) {
	var req SignInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid JSON payload")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" {
		sendError(c, http.StatusBadRequest, "invalid_input", "Email and password are required")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	user, err := h.db.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			sendError(c, http.StatusUnauthorized, "invalid_credentials", "Invalid email or password")
			return
		}
		if h.logger != nil {
			h.logger.Error("failed to query user by email", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to process login")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		sendError(c, http.StatusUnauthorized, "invalid_credentials", "Invalid email or password")
		return
	}

	if h.logger != nil {
		h.logger.Info("user signed in successfully", slog.String("user_id", formatUUID(user.ID)), slog.String("email", user.Email))
	}

	userIdStr := formatUUID(user.ID)
	token, err := auth.GenerateToken(userIdStr, user.Email, h.jwtSecret, 7*24*time.Hour)
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to generate jwt token on signin", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "internal_error", "Failed to generate authentication token")
		return
	}

	sendSuccess(c, http.StatusOK, AuthDataResponse{
		Token: token,
		User: UserResponse{
			ID:       userIdStr,
			Email:    user.Email,
			FullName: user.FullName,
		},
	})
}

// GetCurrentUser handles GET /api/me endpoint, returning the authenticated user profile.
func (h *AuthHandler) GetCurrentUser(c *gin.Context) {
	email := c.GetString("user_email")
	if email == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	user, err := h.db.GetUserByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			sendError(c, http.StatusUnauthorized, "unauthorized", "User profile not found")
			return
		}
		if h.logger != nil {
			h.logger.Error("failed to query current user by email", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve user profile")
		return
	}

	userIdStr := formatUUID(user.ID)
	sendSuccess(c, http.StatusOK, UserResponse{
		ID:       userIdStr,
		Email:    user.Email,
		FullName: user.FullName,
	})
}
