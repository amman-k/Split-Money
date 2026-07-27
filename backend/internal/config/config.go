package config

import (
	"os"

	"github.com/joho/godotenv"
)

// Config holds all startup configuration values loaded from environment variables.
type Config struct {
	Port        string
	DatabaseURL string
	JWTSecret   string
}

// Load reads environment variables into a typed Config struct.
// It loads .env files if present and panics on startup if critical required variables are missing in production mode.
func Load() *Config {
	// Attempt to load .env files silently (ignoring error if not found)
	_= godotenv.Load(".env")
	

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		if os.Getenv("ENV") == "production" {
			panic("DATABASE_URL environment variable is required in production")
		}
		// Default local database connection string for development
		dbURL = "postgres://postgres:nike@localhost:5432/split_money?sslmode=disable"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		if os.Getenv("ENV") == "production" {
			panic("JWT_SECRET environment variable is required in production")
		}
		jwtSecret = "dev-secret-key-split-money-change-in-prod"
	}

	return &Config{
		Port:        port,
		DatabaseURL: dbURL,
		JWTSecret:   jwtSecret,
	}
}
