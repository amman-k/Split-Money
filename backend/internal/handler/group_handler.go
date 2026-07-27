package handler

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"split_backend/internal/db"
)

// GroupQuerier defines the database operations required by GroupHandler.
type GroupQuerier interface {
	CreateGroup(ctx context.Context, arg db.CreateGroupParams) (db.Group, error)
	CreateGroupMember(ctx context.Context, arg db.CreateGroupMemberParams) (db.GroupMember, error)
	GetGroupByID(ctx context.Context, id pgtype.UUID) (db.Group, error)
	GetGroupsByOwnerID(ctx context.Context, ownerID pgtype.UUID) ([]db.Group, error)
	GetGroupMembersByGroupID(ctx context.Context, groupID pgtype.UUID) ([]db.GroupMember, error)
	DeleteGroup(ctx context.Context, arg db.DeleteGroupParams) error
}

type ExpenseQuerier interface {
	CreateExpense(ctx context.Context, arg db.CreateExpenseParams) (db.Expense, error)
	CreateExpenseSplit(ctx context.Context, arg db.CreateExpenseSplitParams) (db.ExpenseSplit, error)
	GetExpensesByGroupID(ctx context.Context, groupID pgtype.UUID) ([]db.Expense, error)
	GetExpenseSplitsByExpenseID(ctx context.Context, expenseID pgtype.UUID) ([]db.ExpenseSplit, error)
	CreateExpensePayment(ctx context.Context, arg db.CreateExpensePaymentParams) (db.ExpensePayment, error)
	GetExpensePaymentsByExpenseID(ctx context.Context, expenseID pgtype.UUID) ([]db.ExpensePayment, error)
	CreateExpenseItem(ctx context.Context, arg db.CreateExpenseItemParams) (db.ExpenseItem, error)
	GetExpenseItemsByExpenseID(ctx context.Context, expenseID pgtype.UUID) ([]db.ExpenseItem, error)
	CreateExpenseItemSplit(ctx context.Context, arg db.CreateExpenseItemSplitParams) (db.ExpenseItemSplit, error)
	GetExpenseItemSplitsByItemID(ctx context.Context, expenseItemID pgtype.UUID) ([]db.ExpenseItemSplit, error)
	GetExpenseByID(ctx context.Context, arg db.GetExpenseByIDParams) (db.Expense, error)
	UpdateExpense(ctx context.Context, arg db.UpdateExpenseParams) (db.Expense, error)
	DeleteExpense(ctx context.Context, arg db.DeleteExpenseParams) error
	DeleteExpensePayments(ctx context.Context, expenseID pgtype.UUID) error
	DeleteExpenseSplits(ctx context.Context, expenseID pgtype.UUID) error
	DeleteExpenseItems(ctx context.Context, expenseID pgtype.UUID) error
}

// Querier combines all database operations across handlers.
type Querier interface {
	UserQuerier
	GroupQuerier
	ExpenseQuerier
}


// GroupHandler handles group creation and retrieval endpoints.
type GroupHandler struct {
	db     GroupQuerier
	logger *slog.Logger
}

// NewGroupHandler creates a new GroupHandler instance with explicit dependency injection.
func NewGroupHandler(db GroupQuerier, logger *slog.Logger) *GroupHandler {
	return &GroupHandler{
		db:     db,
		logger: logger,
	}
}

type GroupMemberInput struct {
	Name    string `json:"name"`
	IsOwner bool   `json:"is_owner"`
}

type CreateGroupRequest struct {
	Name        string             `json:"name"`
	Description string             `json:"description"`
	Members     []GroupMemberInput `json:"members"`
}

type GroupMemberResponse struct {
	ID        string    `json:"id"`
	GroupID   string    `json:"group_id"`
	Name      string    `json:"name"`
	IsOwner   bool      `json:"is_owner"`
	CreatedAt time.Time `json:"created_at"`
}

type GroupResponse struct {
	ID          string                `json:"id"`
	Name        string                `json:"name"`
	Description string                `json:"description"`
	OwnerID     string                `json:"owner_id"`
	CreatedAt   time.Time             `json:"created_at"`
	UpdatedAt   time.Time             `json:"updated_at"`
	Members     []GroupMemberResponse `json:"members"`
}

func parseUUID(s string) (pgtype.UUID, error) {
	var u pgtype.UUID
	err := u.Scan(s)
	return u, err
}

func toGroupMemberResponse(m db.GroupMember) GroupMemberResponse {
	return GroupMemberResponse{
		ID:        formatUUID(m.ID),
		GroupID:   formatUUID(m.GroupID),
		Name:      m.Name,
		IsOwner:   m.IsOwner,
		CreatedAt: m.CreatedAt.Time,
	}
}

func toGroupResponse(g db.Group, members []db.GroupMember) GroupResponse {
	mRes := make([]GroupMemberResponse, 0, len(members))
	for _, m := range members {
		mRes = append(mRes, toGroupMemberResponse(m))
	}
	return GroupResponse{
		ID:          formatUUID(g.ID),
		Name:        g.Name,
		Description: g.Description,
		OwnerID:     formatUUID(g.OwnerID),
		CreatedAt:   g.CreatedAt.Time,
		UpdatedAt:   g.UpdatedAt.Time,
		Members:     mRes,
	}
}

// CreateGroup handles POST /api/groups endpoint.
func (h *GroupHandler) CreateGroup(c *gin.Context) {
	var req CreateGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid JSON payload")
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	if req.Name == "" {
		sendError(c, http.StatusBadRequest, "invalid_input", "Group name is required")
		return
	}

	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return
	}

	ownerID, err := parseUUID(userIDStr)
	if err != nil || !ownerID.Valid {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Invalid user identity")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	group, err := h.db.CreateGroup(ctx, db.CreateGroupParams{
		Name:        req.Name,
		Description: strings.TrimSpace(req.Description),
		OwnerID:     ownerID,
	})
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to create group in database", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to create group")
		return
	}

	// Ensure owner is included in the members list if not already specified
	hasOwner := false
	for _, m := range req.Members {
		if m.IsOwner || strings.EqualFold(strings.TrimSpace(m.Name), "You") {
			hasOwner = true
			break
		}
	}
	if !hasOwner {
		req.Members = append([]GroupMemberInput{{Name: "You", IsOwner: true}}, req.Members...)
	}

	var createdMembers []db.GroupMember
	for _, mInput := range req.Members {
		name := strings.TrimSpace(mInput.Name)
		if name == "" {
			continue
		}
		member, err := h.db.CreateGroupMember(ctx, db.CreateGroupMemberParams{
			GroupID: group.ID,
			Name:    name,
			IsOwner: mInput.IsOwner,
		})
		if err != nil {
			if h.logger != nil {
				h.logger.Error("failed to create group member", slog.String("error", err.Error()), slog.String("member_name", name))
			}
			sendError(c, http.StatusInternalServerError, "database_error", "Failed to save group members")
			return
		}
		createdMembers = append(createdMembers, member)
	}

	if h.logger != nil {
		h.logger.Info("group created successfully", slog.String("group_id", formatUUID(group.ID)), slog.Int("member_count", len(createdMembers)))
	}

	sendSuccess(c, http.StatusCreated, toGroupResponse(group, createdMembers))
}

// ListGroups handles GET /api/groups endpoint.
func (h *GroupHandler) ListGroups(c *gin.Context) {
	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return
	}

	ownerID, err := parseUUID(userIDStr)
	if err != nil || !ownerID.Valid {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Invalid user identity")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	groups, err := h.db.GetGroupsByOwnerID(ctx, ownerID)
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to query groups by owner", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve groups")
		return
	}

	var res []GroupResponse
	for _, g := range groups {
		members, err := h.db.GetGroupMembersByGroupID(ctx, g.ID)
		if err != nil {
			if h.logger != nil {
				h.logger.Warn("failed to fetch group members for list", slog.String("group_id", formatUUID(g.ID)), slog.String("error", err.Error()))
			}
			members = []db.GroupMember{}
		}
		res = append(res, toGroupResponse(g, members))
	}

	if res == nil {
		res = []GroupResponse{}
	}

	sendSuccess(c, http.StatusOK, res)
}

// GetGroup handles GET /api/groups/:id endpoint.
func (h *GroupHandler) GetGroup(c *gin.Context) {
	idParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(idParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return
	}

	ownerID, _ := parseUUID(userIDStr)

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	group, err := h.db.GetGroupByID(ctx, groupID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			sendError(c, http.StatusNotFound, "not_found", "Group not found")
			return
		}
		if h.logger != nil {
			h.logger.Error("failed to query group by id", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve group")
		return
	}

	if group.OwnerID != ownerID {
		sendError(c, http.StatusForbidden, "forbidden", "You do not have access to this group")
		return
	}

	members, err := h.db.GetGroupMembersByGroupID(ctx, group.ID)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		if h.logger != nil {
			h.logger.Error("failed to query group members", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve group members")
		return
	}
	if members == nil {
		members = []db.GroupMember{}
	}

	sendSuccess(c, http.StatusOK, toGroupResponse(group, members))
}

type AddMembersRequest struct {
	Members []GroupMemberInput `json:"members"`
}

// AddMembers handles POST /api/groups/:id/members endpoint.
func (h *GroupHandler) AddMembers(c *gin.Context) {
	idParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(idParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	var req AddMembersRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid JSON payload")
		return
	}

	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return
	}

	ownerID, _ := parseUUID(userIDStr)

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	group, err := h.db.GetGroupByID(ctx, groupID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			sendError(c, http.StatusNotFound, "not_found", "Group not found")
			return
		}
		if h.logger != nil {
			h.logger.Error("failed to query group by id", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve group")
		return
	}

	if group.OwnerID != ownerID {
		sendError(c, http.StatusForbidden, "forbidden", "You do not have access to modify this group")
		return
	}

	var createdMembers []db.GroupMember
	for _, mInput := range req.Members {
		name := strings.TrimSpace(mInput.Name)
		if name == "" {
			continue
		}
		member, err := h.db.CreateGroupMember(ctx, db.CreateGroupMemberParams{
			GroupID: group.ID,
			Name:    name,
			IsOwner: mInput.IsOwner,
		})
		if err != nil {
			if h.logger != nil {
				h.logger.Error("failed to create group member", slog.String("error", err.Error()), slog.String("member_name", name))
			}
			sendError(c, http.StatusInternalServerError, "database_error", "Failed to save group members")
			return
		}
		createdMembers = append(createdMembers, member)
	}

	members, err := h.db.GetGroupMembersByGroupID(ctx, group.ID)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		if h.logger != nil {
			h.logger.Error("failed to query group members", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve updated group members")
		return
	}
	if members == nil {
		members = []db.GroupMember{}
	}

	sendSuccess(c, http.StatusOK, toGroupResponse(group, members))
}

// DeleteGroup handles DELETE /api/groups/:id endpoint.
func (h *GroupHandler) DeleteGroup(c *gin.Context) {
	idParam := strings.TrimSpace(c.Param("id"))
	groupID, err := parseUUID(idParam)
	if err != nil || !groupID.Valid {
		sendError(c, http.StatusBadRequest, "invalid_input", "Invalid group ID format")
		return
	}

	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		sendError(c, http.StatusUnauthorized, "unauthorized", "Missing user identity in context")
		return
	}
	ownerID, _ := parseUUID(userIDStr)

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	// Verify group exists and user is owner
	group, err := h.db.GetGroupByID(ctx, groupID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			sendError(c, http.StatusNotFound, "not_found", "Group not found")
			return
		}
		if h.logger != nil {
			h.logger.Error("failed to query group by id", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to retrieve group")
		return
	}

	if group.OwnerID != ownerID {
		sendError(c, http.StatusForbidden, "forbidden", "Only the group owner can delete the group")
		return
	}

	err = h.db.DeleteGroup(ctx, db.DeleteGroupParams{
		ID:      groupID,
		OwnerID: ownerID,
	})
	if err != nil {
		if h.logger != nil {
			h.logger.Error("failed to delete group", slog.String("error", err.Error()))
		}
		sendError(c, http.StatusInternalServerError, "database_error", "Failed to delete group")
		return
	}

	sendSuccess(c, http.StatusOK, map[string]string{"message": "Group deleted successfully"})
}
