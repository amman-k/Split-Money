package server

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"split_backend/internal/handler"
	"split_backend/internal/middleware"
)

// ErrorResponse defines the standard error envelope per AGENTS.md.
type ErrorResponse struct {
	Data  any `json:"data"`
	Error struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

// New creates and configures a new Gin engine with slog logging, CORS, and error recovery.
func New(logger *slog.Logger, dbQuerier handler.Querier, jwtSecret string) *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()

	// CORS configuration for local development and client integration
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowAllOrigins = true
	corsConfig.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization"}
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	r.Use(cors.New(corsConfig))

	// Custom slog middleware per Section 3 of AGENTS.md
	r.Use(func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		if logger != nil {
			logger.Info("http_request",
				slog.Int("status", c.Writer.Status()),
				slog.String("method", c.Request.Method),
				slog.String("path", path),
				slog.String("query", query),
				slog.String("ip", c.ClientIP()),
				slog.Duration("latency", time.Since(start)),
			)
		}
	})

	// Custom recovery middleware
	r.Use(gin.CustomRecovery(func(c *gin.Context, err any) {
		c.AbortWithStatusJSON(http.StatusInternalServerError, ErrorResponse{
			Data: nil,
			Error: struct {
				Code    string `json:"code"`
				Message string `json:"message"`
			}{
				Code:    "internal_server_error",
				Message: "An unexpected error occurred",
			},
		})
	}))

	// Handle 404 NotFound
	r.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, ErrorResponse{
			Data: nil,
			Error: struct {
				Code    string `json:"code"`
				Message string `json:"message"`
			}{
				Code:    "not_found",
				Message: "Requested resource was not found",
			},
		})
	})

	// Health endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// API routes
	if dbQuerier != nil {
		authH := handler.NewAuthHandler(dbQuerier, jwtSecret, logger)
		groupH := handler.NewGroupHandler(dbQuerier, logger)
		expenseH := handler.NewExpenseHandler(dbQuerier, logger)
		api := r.Group("/api")
		{
			api.POST("/signup", authH.SignUp)
			api.POST("/signin", authH.SignIn)

			protected := api.Group("", middleware.JWTMiddleware(jwtSecret, logger))
			{
				protected.GET("/me", authH.GetCurrentUser)
				protected.POST("/groups", groupH.CreateGroup)
				protected.GET("/groups", groupH.ListGroups)
				protected.GET("/groups/:id", groupH.GetGroup)
				protected.DELETE("/groups/:id", groupH.DeleteGroup)
				protected.POST("/groups/:id/members", groupH.AddMembers)
				protected.POST("/groups/:id/expenses", expenseH.CreateExpense)
				protected.GET("/groups/:id/expenses", expenseH.ListExpenses)
				protected.GET("/groups/:id/expenses/:expenseId", expenseH.GetExpense)
				protected.PUT("/groups/:id/expenses/:expenseId", expenseH.UpdateExpense)
				protected.DELETE("/groups/:id/expenses/:expenseId", expenseH.DeleteExpense)
				protected.GET("/groups/:id/balances", expenseH.GetBalances)
				protected.GET("/groups/:id/settlements", expenseH.GetSettlements)
			}
		}
	}

	return r
}

