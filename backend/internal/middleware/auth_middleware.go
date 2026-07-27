package middleware

import (
	"log/slog"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"split_backend/internal/auth"
)

type ErrorEnvelope struct {
	Data  any `json:"data"`
	Error struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

func sendAuthError(c *gin.Context, code, message string) {
	c.AbortWithStatusJSON(http.StatusUnauthorized, ErrorEnvelope{
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

// JWTMiddleware verifies the Authorization Bearer token on protected endpoints.
func JWTMiddleware(jwtSecret string, logger *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			sendAuthError(c, "unauthorized", "Missing authorization header")
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			sendAuthError(c, "unauthorized", "Invalid authorization header format")
			return
		}

		tokenStr := strings.TrimSpace(parts[1])
		if tokenStr == "" {
			sendAuthError(c, "unauthorized", "Empty bearer token")
			return
		}

		claims, err := auth.ValidateToken(tokenStr, jwtSecret)
		if err != nil {
			if logger != nil {
				logger.Warn("JWT validation failed", slog.String("error", err.Error()), slog.String("path", c.Request.URL.Path))
			}
			sendAuthError(c, "unauthorized", "Invalid or expired token")
			return
		}

		// Inject user identity into Gin context
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Next()
	}
}
