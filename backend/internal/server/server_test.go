package server

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
	"split_backend/internal/db"
)


type dummyQuerier struct{}

func (d *dummyQuerier) CreateUser(ctx context.Context, arg db.CreateUserParams) (db.User, error) {
	return db.User{}, nil
}

func (d *dummyQuerier) GetUserByEmail(ctx context.Context, email string) (db.User, error) {
	return db.User{}, nil
}

func (d *dummyQuerier) CreateGroup(ctx context.Context, arg db.CreateGroupParams) (db.Group, error) {
	return db.Group{}, nil
}

func (d *dummyQuerier) CreateGroupMember(ctx context.Context, arg db.CreateGroupMemberParams) (db.GroupMember, error) {
	return db.GroupMember{}, nil
}

func (d *dummyQuerier) DeleteGroup(ctx context.Context, arg db.DeleteGroupParams) error {
	return nil
}

func (d *dummyQuerier) CreateExpenseItem(ctx context.Context, arg db.CreateExpenseItemParams) (db.ExpenseItem, error) {
	return db.ExpenseItem{}, nil
}

func (d *dummyQuerier) CreateExpenseItemSplit(ctx context.Context, arg db.CreateExpenseItemSplitParams) (db.ExpenseItemSplit, error) {
	return db.ExpenseItemSplit{}, nil
}

func (d *dummyQuerier) CreateExpensePayment(ctx context.Context, arg db.CreateExpensePaymentParams) (db.ExpensePayment, error) {
	return db.ExpensePayment{}, nil
}

func (d *dummyQuerier) GetGroupByID(ctx context.Context, id pgtype.UUID) (db.Group, error) {
	return db.Group{}, nil
}

func (d *dummyQuerier) GetGroupsByOwnerID(ctx context.Context, ownerID pgtype.UUID) ([]db.Group, error) {
	return nil, nil
}

func (d *dummyQuerier) GetGroupMembersByGroupID(ctx context.Context, groupID pgtype.UUID) ([]db.GroupMember, error) {
	return nil, nil
}

func (d *dummyQuerier) CreateExpense(ctx context.Context, arg db.CreateExpenseParams) (db.Expense, error) {
	return db.Expense{}, nil
}

func (d *dummyQuerier) CreateExpenseSplit(ctx context.Context, arg db.CreateExpenseSplitParams) (db.ExpenseSplit, error) {
	return db.ExpenseSplit{}, nil
}

func (d *dummyQuerier) GetExpensesByGroupID(ctx context.Context, groupID pgtype.UUID) ([]db.Expense, error) {
	return nil, nil
}

func (d *dummyQuerier) DeleteExpense(ctx context.Context, arg db.DeleteExpenseParams) error {
	return nil
}

func (d *dummyQuerier) DeleteExpenseItems(ctx context.Context, expenseID pgtype.UUID) error {
	return nil
}

func (d *dummyQuerier) DeleteExpensePayments(ctx context.Context, expenseID pgtype.UUID) error {
	return nil
}

func (d *dummyQuerier) DeleteExpenseSplits(ctx context.Context, expenseID pgtype.UUID) error {
	return nil
}

func (d *dummyQuerier) GetExpenseByID(ctx context.Context, arg db.GetExpenseByIDParams) (db.Expense, error) {
	return db.Expense{}, nil
}

func (d *dummyQuerier) GetExpenseItemSplitsByItemID(ctx context.Context, expenseItemID pgtype.UUID) ([]db.ExpenseItemSplit, error) {
	return nil, nil
}

func (d *dummyQuerier) GetExpenseItemsByExpenseID(ctx context.Context, expenseID pgtype.UUID) ([]db.ExpenseItem, error) {
	return nil, nil
}

func (d *dummyQuerier) UpdateExpense(ctx context.Context, arg db.UpdateExpenseParams) (db.Expense, error) {
	return db.Expense{}, nil
}

func (d *dummyQuerier) GetExpensePaymentsByExpenseID(ctx context.Context, expenseID pgtype.UUID) ([]db.ExpensePayment, error) {
	return nil, nil
}

func (d *dummyQuerier) GetExpenseSplitsByExpenseID(ctx context.Context, expenseID pgtype.UUID) ([]db.ExpenseSplit, error) {
	return nil, nil
}
func TestRouterEndpoints(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(httptest.NewRecorder(), nil))
	engine := New(logger, &dummyQuerier{}, "test-secret")

	tests := []struct {
		name           string
		method         string
		path           string
		expectedStatus int
		checkBody      func(t *testing.T, body []byte)
	}{
		{
			name:           "Health Check Endpoint Returns OK",
			method:         http.MethodGet,
			path:           "/health",
			expectedStatus: http.StatusOK,
			checkBody: func(t *testing.T, body []byte) {
				var resp map[string]string
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to unmarshal JSON: %v", err)
				}
				if resp["status"] != "ok" {
					t.Errorf("expected status 'ok', got '%s'", resp["status"])
				}
			},
		},
		{
			name:           "404 Not Found Returns Standard Error Envelope",
			method:         http.MethodGet,
			path:           "/non-existent-route",
			expectedStatus: http.StatusNotFound,
			checkBody: func(t *testing.T, body []byte) {
				var resp ErrorResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to unmarshal JSON: %v", err)
				}
				if resp.Error.Code != "not_found" {
					t.Errorf("expected error code 'not_found', got '%s'", resp.Error.Code)
				}
			},
		},
		{
			name:           "Protected Route Requires Auth",
			method:         http.MethodGet,
			path:           "/api/me",
			expectedStatus: http.StatusUnauthorized,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest(tc.method, tc.path, nil)
			if err != nil {
				t.Fatalf("failed to create request: %v", err)
			}
			w := httptest.NewRecorder()
			engine.ServeHTTP(w, req)

			if w.Code != tc.expectedStatus {
				t.Errorf("expected status %d, got %d", tc.expectedStatus, w.Code)
			}
			if tc.checkBody != nil {
				tc.checkBody(t, w.Body.Bytes())
			}
		})
	}
}

func TestRecoveryMiddleware(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(httptest.NewRecorder(), nil))
	engine := New(logger, nil, "test-secret")

	// Add a route that panics to test CustomRecovery
	engine.GET("/panic", func(c *gin.Context) {
		panic("intentional test panic")
	})

	req, _ := http.NewRequest(http.MethodGet, "/panic", nil)
	w := httptest.NewRecorder()
	engine.ServeHTTP(w, req)

	if w.Code != http.StatusInternalServerError {
		t.Errorf("expected status 500 on panic, got %d", w.Code)
	}

	var resp ErrorResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal JSON from panic response: %v", err)
	}
	if resp.Error.Code != "internal_server_error" {
		t.Errorf("expected error code 'internal_server_error', got '%s'", resp.Error.Code)
	}
}
