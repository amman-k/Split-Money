package handler

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"split_backend/internal/db"
)

// ExpenseHandler handles expenses and balance calculations endpoints.
type ExpenseHandler struct {
	db     Querier
	logger *slog.Logger
}

// NewExpenseHandler creates a new ExpenseHandler instance.
func NewExpenseHandler(db Querier, logger *slog.Logger) *ExpenseHandler {
	return &ExpenseHandler{
		db:     db,
		logger: logger,
	}
}

// helper to format numeric cleanly to float64
func numericToFloat(n pgtype.Numeric) float64 {
	f, err := n.Float64Value()
	if err != nil || !f.Valid {
		return 0.0
	}
	return f.Float64
}

// helper to convert float64 to numeric
func floatToNumeric(f float64) pgtype.Numeric {
	n := pgtype.Numeric{}
	_ = n.Scan(fmt.Sprintf("%.2f", f))
	return n
}

type ExpenseSplitInput struct {
	MemberID string  `json:"member_id"`
	Amount   float64 `json:"amount"`
}

type ExpenseItemInput struct {
	Name    string   `json:"name"`
	Amount  float64  `json:"amount"`
	Members []string `json:"members"`
}

type ExpensePaymentInput struct {
	MemberID string  `json:"member_id"`
	Amount   float64 `json:"amount"`
}

type CreateExpenseRequest struct {
	Title          string                `json:"title"`
	Description    string                `json:"description"`
	Amount         float64               `json:"amount"`
	SplitType      string                `json:"split_type"`
	TaxAmount      float64               `json:"tax_amount"`
	DiscountAmount float64               `json:"discount_amount"`
	Metadata       json.RawMessage       `json:"metadata"`
	Payments       []ExpensePaymentInput `json:"payments"`
	Splits         []ExpenseSplitInput   `json:"splits"`
	Items          []ExpenseItemInput    `json:"items"`
}

type ExpenseResponse struct {
	ID             string              `json:"id"`
	Title          string              `json:"title"`
	Description    string              `json:"description"`
	Amount         float64             `json:"amount"`
	SplitType      string              `json:"split_type"`
	TaxAmount      float64             `json:"tax_amount"`
	DiscountAmount float64             `json:"discount_amount"`
	Date           time.Time           `json:"date"`
	UserAmount     float64             `json:"user_amount"`
	PaidBy         map[string]string   `json:"paid_by"`
	Splits         []ExpenseSplitInput `json:"splits"`
}

type ExpenseDetailResponse struct {
	ID             string                `json:"id"`
	Title          string                `json:"title"`
	Description    string                `json:"description"`
	Amount         float64               `json:"amount"`
	SplitType      string                `json:"split_type"`
	TaxAmount      float64               `json:"tax_amount"`
	DiscountAmount float64               `json:"discount_amount"`
	Date           time.Time             `json:"date"`
	Metadata       json.RawMessage       `json:"metadata"`
	Payments       []ExpensePaymentInput `json:"payments"`
	Splits         []ExpenseSplitInput   `json:"splits"`
	Items          []ExpenseItemInput    `json:"items"`
}

type BalancesResponse struct {
	UserBalance       float64 `json:"user_balance"`
	TotalGroupBalance float64 `json:"total_group_balance"`
}

type SettlementResponse struct {
	FromMemberID   string  `json:"from_member_id"`
	FromMemberName string  `json:"from_member_name"`
	ToMemberID     string  `json:"to_member_id"`
	ToMemberName   string  `json:"to_member_name"`
	Amount         float64 `json:"amount"`
}

// CreateExpense handles POST /api/groups/:id/expenses endpoint.
func (h *ExpenseHandler) CreateExpense(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	var req CreateExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid JSON payload")
		return
	}

	req.Title = strings.TrimSpace(req.Title)
	if req.Title == "" {
		sendError(c, http.StatusBadRequest, "invalid_input", "Title is required")
		return
	}
	if req.Amount <= 0 {
		sendError(c, http.StatusBadRequest, "invalid_input", "Amount must be greater than zero")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	// Verify group exists and user is owner
	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	// Create expense
	expense, err := h.db.CreateExpense(ctx, db.CreateExpenseParams{
		GroupID:        groupID,
		Title:          req.Title,
		Description:    pgtype.Text{String: req.Description, Valid: req.Description != ""},
		Amount:         floatToNumeric(req.Amount),
		SplitType:      req.SplitType,
		TaxAmount:      floatToNumeric(req.TaxAmount),
		DiscountAmount: floatToNumeric(req.DiscountAmount),
		Metadata:       req.Metadata,
	})
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to create expense", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to create expense")
		return
	}

	// Create payments
	for _, payment := range req.Payments {
		memberID, err := parseUUID(payment.MemberID)
		if err != nil || !memberID.Valid {
			continue
		}
		_, _ = h.db.CreateExpensePayment(ctx, db.CreateExpensePaymentParams{
			ExpenseID: expense.ID,
			MemberID:  memberID,
			Amount:    floatToNumeric(payment.Amount),
		})
	}

	// Create splits
	for _, split := range req.Splits {
		memberID, err := parseUUID(split.MemberID)
		if err != nil || !memberID.Valid {
			continue // Skip invalid members
		}
		_, err = h.db.CreateExpenseSplit(ctx, db.CreateExpenseSplitParams{
			ExpenseID: expense.ID,
			MemberID:  memberID,
			Amount:    floatToNumeric(split.Amount),
		})
		if err != nil {
			if h.logger != nil {
				h.logger.Error("failed to create expense split", slog.String("error", err.Error()))
			}
		}
	}

	// Create items if any
	for _, item := range req.Items {
		dbItem, err := h.db.CreateExpenseItem(ctx, db.CreateExpenseItemParams{
			ExpenseID: expense.ID,
			Name:      item.Name,
			Amount:    floatToNumeric(item.Amount),
		})
		if err == nil {
			for _, mIDStr := range item.Members {
				mID, err := parseUUID(mIDStr)
				if err == nil && mID.Valid {
					_, _ = h.db.CreateExpenseItemSplit(ctx, db.CreateExpenseItemSplitParams{
						ExpenseItemID: dbItem.ID,
						MemberID:      mID,
					})
				}
			}
		}
	}

	sendSuccess(c, http.StatusCreated, gin.H{"id": formatUUID(expense.ID)})
}

// getLoggedInUserMemberID finds the group_member ID representing the current user in the group.
// It assumes the member with is_owner = true is the logged-in user.
func (h *ExpenseHandler) getLoggedInUserMemberID(ctx context.Context, groupID pgtype.UUID) (pgtype.UUID, string, bool) {
	members, err := h.db.GetGroupMembersByGroupID(ctx, groupID)
	if err != nil {
		return pgtype.UUID{}, "", false
	}
	for _, m := range members {
		if m.IsOwner {
			return m.ID, m.Name, true
		}
	}
	return pgtype.UUID{}, "", false
}

// verifyGroupOwner checks if the current user from context is the owner of the given group.
// If not, it sends an appropriate error response and returns false.
func (h *ExpenseHandler) verifyGroupOwner(c *gin.Context, ctx context.Context, groupID pgtype.UUID) bool {
	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return false
	}
	ownerID, err := parseUUID(userIDStr)
	if err != nil || !ownerID.Valid {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Invalid user identity")
		return false
	}

	group, err := h.db.GetGroupByID(ctx, groupID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			sendError(c, http.StatusNotFound, "not_found", "Group not found")
			return false
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve group")
		return false
	}

	if group.OwnerID != ownerID {
		sendError(c, http.StatusForbidden, "forbidden", "Only the group owner can access this resource")
		return false
	}
	return true
}

// ListExpenses handles GET /api/groups/:id/expenses endpoint.
func (h *ExpenseHandler) ListExpenses(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	userMemberID, _, hasUser := h.getLoggedInUserMemberID(ctx, groupID)
	
	// Fetch all members to resolve names
	members, err := h.db.GetGroupMembersByGroupID(ctx, groupID)
	if err != nil {
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to fetch members")
		return
	}
	memberMap := make(map[string]string)
	for _, m := range members {
		memberMap[formatUUID(m.ID)] = m.Name
	}

	expenses, err := h.db.GetExpensesByGroupID(ctx, groupID)
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to fetch expenses", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve expenses")
		return
	}

	var res []ExpenseResponse
	for _, e := range expenses {
		// Calculate userAmount
		splits, err := h.db.GetExpenseSplitsByExpenseID(ctx, e.ID)
		if err != nil {
			splits = []db.ExpenseSplit{}
		}

		payments, err := h.db.GetExpensePaymentsByExpenseID(ctx, e.ID)
		if err != nil {
			payments = []db.ExpensePayment{}
		}
		
		userAmount := 0.0
		if hasUser {
			userMemberStr := formatUUID(userMemberID)
			
			paidByUser := 0.0
			for _, p := range payments {
				if formatUUID(p.MemberID) == userMemberStr {
					paidByUser += numericToFloat(p.Amount)
				}
			}
			
			owedByUser := 0.0
			for _, s := range splits {
				if formatUUID(s.MemberID) == userMemberStr {
					owedByUser += numericToFloat(s.Amount)
				}
			}
			
			userAmount = paidByUser - owedByUser
		}
		
		paidBy := map[string]string{}
		if len(payments) > 0 {
			pid := formatUUID(payments[0].MemberID)
			paidBy["id"] = pid
			paidBy["name"] = memberMap[pid]
		}
		
		outSplits := []ExpenseSplitInput{}
		for _, s := range splits {
			outSplits = append(outSplits, ExpenseSplitInput{
				MemberID: formatUUID(s.MemberID),
				Amount:   numericToFloat(s.Amount),
			})
		}

		res = append(res, ExpenseResponse{
			ID:             formatUUID(e.ID),
			Title:          e.Title,
			Description:    e.Description.String,
			Amount:         numericToFloat(e.Amount),
			SplitType:      e.SplitType,
			TaxAmount:      numericToFloat(e.TaxAmount),
			DiscountAmount: numericToFloat(e.DiscountAmount),
			Date:           e.CreatedAt.Time,
			UserAmount:     userAmount,
			PaidBy:         paidBy,
			Splits:         outSplits,
		})
	}

	if res == nil {
		res = []ExpenseResponse{}
	}

	sendSuccess(c, http.StatusOK, res)
}

// GetBalances handles GET /api/groups/:id/balances endpoint.
func (h *ExpenseHandler) GetBalances(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	userMemberID, _, hasUser := h.getLoggedInUserMemberID(ctx, groupID)
	userMemberStr := formatUUID(userMemberID)

	expenses, err := h.db.GetExpensesByGroupID(ctx, groupID)
	if err != nil {
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve expenses")
		return
	}

	totalGroupBalance := 0.0
	userBalance := 0.0

	for _, e := range expenses {
		amount := numericToFloat(e.Amount)
		totalGroupBalance += amount

		if hasUser {
			payments, _ := h.db.GetExpensePaymentsByExpenseID(ctx, e.ID)
			paidByUser := 0.0
			for _, p := range payments {
				if formatUUID(p.MemberID) == userMemberStr {
					paidByUser += numericToFloat(p.Amount)
				}
			}

			splits, err := h.db.GetExpenseSplitsByExpenseID(ctx, e.ID)
			if err == nil {
				owedByUser := 0.0
				for _, s := range splits {
					if formatUUID(s.MemberID) == userMemberStr {
						owedByUser += numericToFloat(s.Amount)
					}
				}
				userBalance += (paidByUser - owedByUser)
			}
		}
	}

	sendSuccess(c, http.StatusOK, BalancesResponse{
		UserBalance:       userBalance,
		TotalGroupBalance: totalGroupBalance,
	})
}

// GetSettlements handles GET /api/groups/:id/settlements endpoint.
func (h *ExpenseHandler) GetSettlements(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	members, err := h.db.GetGroupMembersByGroupID(ctx, groupID)
	if err != nil {
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve members")
		return
	}

	memberMap := make(map[string]string)
	balances := make(map[string]float64)

	for _, m := range members {
		idStr := formatUUID(m.ID)
		memberMap[idStr] = m.Name
		balances[idStr] = 0.0
	}

	expenses, err := h.db.GetExpensesByGroupID(ctx, groupID)
	if err != nil {
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve expenses")
		return
	}

	for _, e := range expenses {
		payments, err := h.db.GetExpensePaymentsByExpenseID(ctx, e.ID)
		if err == nil {
			for _, p := range payments {
				balances[formatUUID(p.MemberID)] += numericToFloat(p.Amount)
			}
		}

		splits, err := h.db.GetExpenseSplitsByExpenseID(ctx, e.ID)
		if err == nil {
			for _, s := range splits {
				balances[formatUUID(s.MemberID)] -= numericToFloat(s.Amount)
			}
		}
	}

	type Person struct {
		ID     string
		Name   string
		Amount float64
	}

	var debtors []Person
	var creditors []Person

	for id, balance := range balances {
		// Round to 2 decimal places to avoid floating point precision issues
		balance = float64(int(balance*100)) / 100
		if balance < 0 {
			debtors = append(debtors, Person{ID: id, Name: memberMap[id], Amount: -balance})
		} else if balance > 0 {
			creditors = append(creditors, Person{ID: id, Name: memberMap[id], Amount: balance})
		}
	}

	var settlements []SettlementResponse

	// Simple greedy algorithm for settling up
	// To minimize transactions, one would need a more complex max-flow or subset-sum algorithm,
	// but a greedy approach is standard for simplified debt payment in many apps.
	for len(debtors) > 0 && len(creditors) > 0 {
		debtor := &debtors[0]
		creditor := &creditors[0]

		settleAmount := debtor.Amount
		if creditor.Amount < settleAmount {
			settleAmount = creditor.Amount
		}
		
		// Round to 2 decimal places
		settleAmount = float64(int(settleAmount*100)) / 100

		if settleAmount > 0 {
			settlements = append(settlements, SettlementResponse{
				FromMemberID:   debtor.ID,
				FromMemberName: debtor.Name,
				ToMemberID:     creditor.ID,
				ToMemberName:   creditor.Name,
				Amount:         settleAmount,
			})
		}

		debtor.Amount -= settleAmount
		creditor.Amount -= settleAmount

		// Round to 2 decimal places
		debtor.Amount = float64(int(debtor.Amount*100)) / 100
		creditor.Amount = float64(int(creditor.Amount*100)) / 100

		if debtor.Amount == 0 {
			debtors = debtors[1:]
		}
		if creditor.Amount == 0 {
			creditors = creditors[1:]
		}
	}

	if settlements == nil {
		settlements = []SettlementResponse{}
	}

	sendSuccess(c, http.StatusOK, settlements)
}
