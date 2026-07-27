package handler

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"

	"split_backend/internal/db"
)

// GetExpense handles GET /api/groups/:id/expenses/:expenseId endpoint.
func (h *ExpenseHandler) GetExpense(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	expenseIDParam := strings.TrimSpace(c.Param("expenseId"))
	expenseID, err := parseUUID(expenseIDParam)
	if err != nil || !expenseID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid expense ID format")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	e, err := h.db.GetExpenseByID(ctx, db.GetExpenseByIDParams{
		ID:      expenseID,
		GroupID: groupID,
	})
	if err != nil {
		sendError(c, http.StatusNotFound, "not_found", "Expense not found")
		return
	}

	var res ExpenseDetailResponse
	res.ID = formatUUID(e.ID)
	res.Title = e.Title
	res.Description = e.Description.String
	res.Amount = numericToFloat(e.Amount)
	res.SplitType = e.SplitType
	res.TaxAmount = numericToFloat(e.TaxAmount)
	res.DiscountAmount = numericToFloat(e.DiscountAmount)
	res.Date = e.CreatedAt.Time
	res.Metadata = e.Metadata

	splits, err := h.db.GetExpenseSplitsByExpenseID(ctx, e.ID)
	if err == nil {
		for _, s := range splits {
			res.Splits = append(res.Splits, ExpenseSplitInput{
				MemberID: formatUUID(s.MemberID),
				Amount:   numericToFloat(s.Amount),
			})
		}
	}
	if res.Splits == nil {
		res.Splits = []ExpenseSplitInput{}
	}

	payments, err := h.db.GetExpensePaymentsByExpenseID(ctx, e.ID)
	if err == nil {
		for _, p := range payments {
			res.Payments = append(res.Payments, ExpensePaymentInput{
				MemberID: formatUUID(p.MemberID),
				Amount:   numericToFloat(p.Amount),
			})
		}
	}
	if res.Payments == nil {
		res.Payments = []ExpensePaymentInput{}
	}

	items, err := h.db.GetExpenseItemsByExpenseID(ctx, e.ID)
	if err == nil {
		for _, i := range items {
			itemSplits, err := h.db.GetExpenseItemSplitsByItemID(ctx, i.ID)
			var memberIDs []string
			if err == nil {
				for _, s := range itemSplits {
					memberIDs = append(memberIDs, formatUUID(s.MemberID))
				}
			}
			res.Items = append(res.Items, ExpenseItemInput{
				Name:    i.Name,
				Amount:  numericToFloat(i.Amount),
				Members: memberIDs,
			})
		}
	}
	if res.Items == nil {
		res.Items = []ExpenseItemInput{}
	}

	sendSuccess(c, http.StatusOK, res)
}

// UpdateExpense handles PUT /api/groups/:id/expenses/:expenseId endpoint.
func (h *ExpenseHandler) UpdateExpense(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	expenseIDParam := strings.TrimSpace(c.Param("expenseId"))
	expenseID, err := parseUUID(expenseIDParam)
	if err != nil || !expenseID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid expense ID format")
		return
	}

	var req CreateExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid request body")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	// 1. Update the main expense row
	desc := pgtype.Text{String: req.Description, Valid: req.Description != ""}

	expense, err := h.db.UpdateExpense(ctx, db.UpdateExpenseParams{
		ID:             expenseID,
		GroupID:        groupID,
		Title:          req.Title,
		Description:    desc,
		Amount:         floatToNumeric(req.Amount),
		SplitType:      req.SplitType,
		TaxAmount:      floatToNumeric(req.TaxAmount),
		DiscountAmount: floatToNumeric(req.DiscountAmount),
		Metadata:       req.Metadata,
	})
	if err != nil {
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to update expense")
		return
	}

	// 2. Clear existing related records
	_ = h.db.DeleteExpensePayments(ctx, expenseID)
	_ = h.db.DeleteExpenseSplits(ctx, expenseID)
	_ = h.db.DeleteExpenseItems(ctx, expenseID)

	// 3. Insert payments
	for _, p := range req.Payments {
		memberUUID, _ := parseUUID(p.MemberID)
		_, _ = h.db.CreateExpensePayment(ctx, db.CreateExpensePaymentParams{
			ExpenseID: expense.ID,
			MemberID:  memberUUID,
			Amount:    floatToNumeric(p.Amount),
		})
	}

	// 4. Insert splits
	for _, s := range req.Splits {
		memberUUID, _ := parseUUID(s.MemberID)
		_, _ = h.db.CreateExpenseSplit(ctx, db.CreateExpenseSplitParams{
			ExpenseID: expense.ID,
			MemberID:  memberUUID,
			Amount:    floatToNumeric(s.Amount),
		})
	}

	// 5. Insert items
	if req.SplitType == "BY_ITEMS" {
		for _, item := range req.Items {
			dbItem, err := h.db.CreateExpenseItem(ctx, db.CreateExpenseItemParams{
				ExpenseID: expense.ID,
				Name:      item.Name,
				Amount:    floatToNumeric(item.Amount),
			})
			if err == nil {
				for _, mID := range item.Members {
					mUUID, _ := parseUUID(mID)
					_, _ = h.db.CreateExpenseItemSplit(ctx, db.CreateExpenseItemSplitParams{
						ExpenseItemID: dbItem.ID,
						MemberID:      mUUID,
					})
				}
			}
		}
	}

	sendSuccess(c, http.StatusOK, gin.H{"id": formatUUID(expense.ID)})
}

// DeleteExpense handles DELETE /api/groups/:id/expenses/:expenseId endpoint.
func (h *ExpenseHandler) DeleteExpense(c *gin.Context) {
	groupIDParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(groupIDParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	expenseIDParam := strings.TrimSpace(c.Param("expenseId"))
	expenseID, err := parseUUID(expenseIDParam)
	if err != nil || !expenseID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid expense ID format")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	if !h.verifyGroupOwner(c, ctx, groupID) {
		return
	}

	err = h.db.DeleteExpense(ctx, db.DeleteExpenseParams{
		ID:      expenseID,
		GroupID: groupID,
	})
	if err != nil {
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to delete expense")
		return
	}

	sendSuccess(c, http.StatusOK, gin.H{"message": "Expense deleted successfully"})
}
