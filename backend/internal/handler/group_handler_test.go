package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"split_backend/internal/db"
)

type fakeGroupQuerier struct {
	groups        map[string]db.Group
	groupMembers  map[string][]db.GroupMember
	createGrpErr  error
	createMemErr  error
	getGrpErr     error
	listGrpsErr   error
	getMembersErr error
}

func newFakeGroupQuerier() *fakeGroupQuerier {
	return &fakeGroupQuerier{
		groups:       make(map[string]db.Group),
		groupMembers: make(map[string][]db.GroupMember),
	}
}

func (f *fakeGroupQuerier) CreateGroup(ctx context.Context, arg db.CreateGroupParams) (db.Group, error) {
	if f.createGrpErr != nil {
		return db.Group{}, f.createGrpErr
	}
	id := pgtype.UUID{Bytes: [16]byte{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true}
	g := db.Group{
		ID:          id,
		Name:        arg.Name,
		Description: arg.Description,
		OwnerID:     arg.OwnerID,
	}
	idStr := formatUUID(id)
	f.groups[idStr] = g
	return g, nil
}

func (f *fakeGroupQuerier) CreateGroupMember(ctx context.Context, arg db.CreateGroupMemberParams) (db.GroupMember, error) {
	if f.createMemErr != nil {
		return db.GroupMember{}, f.createMemErr
	}
	mID := pgtype.UUID{Bytes: [16]byte{3, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, byte(len(f.groupMembers[formatUUID(arg.GroupID)]) + 1)}, Valid: true}
	m := db.GroupMember{
		ID:      mID,
		GroupID: arg.GroupID,
		Name:    arg.Name,
		IsOwner: arg.IsOwner,
	}
	gIDStr := formatUUID(arg.GroupID)
	f.groupMembers[gIDStr] = append(f.groupMembers[gIDStr], m)
	return m, nil
}

func (f *fakeGroupQuerier) DeleteGroup(ctx context.Context, arg db.DeleteGroupParams) error {
	return nil
}

func (f *fakeGroupQuerier) GetGroupByID(ctx context.Context, id pgtype.UUID) (db.Group, error) {
	if f.getGrpErr != nil {
		return db.Group{}, f.getGrpErr
	}
	g, exists := f.groups[formatUUID(id)]
	if !exists {
		return db.Group{}, pgx.ErrNoRows
	}
	return g, nil
}

func (f *fakeGroupQuerier) GetGroupsByOwnerID(ctx context.Context, ownerID pgtype.UUID) ([]db.Group, error) {
	if f.listGrpsErr != nil {
		return nil, f.listGrpsErr
	}
	var res []db.Group
	for _, g := range f.groups {
		if formatUUID(g.OwnerID) == formatUUID(ownerID) {
			res = append(res, g)
		}
	}
	return res, nil
}

func (f *fakeGroupQuerier) GetGroupMembersByGroupID(ctx context.Context, groupID pgtype.UUID) ([]db.GroupMember, error) {
	if f.getMembersErr != nil {
		return nil, f.getMembersErr
	}
	return f.groupMembers[formatUUID(groupID)], nil
}

func setupGroupTestRouter(h *GroupHandler, userID string) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(func(c *gin.Context) {
		if userID != "" {
			c.Set("user_id", userID)
		}
		c.Next()
	})
	r.POST("/api/groups", h.CreateGroup)
	r.GET("/api/groups", h.ListGroups)
	r.GET("/api/groups/:id", h.GetGroup)
	return r
}

func TestCreateGroup(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(httptest.NewRecorder(), nil))
	ownerUUID := "01020304-0506-0708-090a-0b0c0d0e0f10"

	tests := []struct {
		name           string
		userID         string
		payload        any
		setupQuerier   func(*fakeGroupQuerier)
		expectedStatus int
		expectedCode   string
	}{
		{
			name:   "Success_With_Owner_Prepend",
			userID: ownerUUID,
			payload: CreateGroupRequest{
				Name:        "Ski Trip 2024",
				Description: "Annual getaway",
				Members: []GroupMemberInput{
					{Name: "Alex", IsOwner: false},
					{Name: "Sarah", IsOwner: false},
				},
			},
			expectedStatus: http.StatusCreated,
		},
		{
			name:   "Success_Owner_Already_Present",
			userID: ownerUUID,
			payload: CreateGroupRequest{
				Name:        "Dinner Club",
				Description: "",
				Members: []GroupMemberInput{
					{Name: "You", IsOwner: true},
					{Name: "Alex", IsOwner: false},
				},
			},
			expectedStatus: http.StatusCreated,
		},
		{
			name:           "Invalid_JSON",
			userID:         ownerUUID,
			payload:        "not a json struct",
			expectedStatus: http.StatusBadRequest,
			expectedCode:   "invalid_input",
		},
		{
			name:   "Missing_Group_Name",
			userID: ownerUUID,
			payload: CreateGroupRequest{
				Name: "",
			},
			expectedStatus: http.StatusBadRequest,
			expectedCode:   "invalid_input",
		},
		{
			name:   "Missing_User_ID_In_Context",
			userID: "",
			payload: CreateGroupRequest{
				Name: "Test Group",
			},
			expectedStatus: http.StatusUnauthorized,
			expectedCode:   "unauthorized",
		},
		{
			name:   "Invalid_User_ID_Format",
			userID: "invalid-uuid",
			payload: CreateGroupRequest{
				Name: "Test Group",
			},
			expectedStatus: http.StatusUnauthorized,
			expectedCode:   "unauthorized",
		},
		{
			name:   "DB_Error_Create_Group",
			userID: ownerUUID,
			payload: CreateGroupRequest{
				Name: "Test Group",
			},
			setupQuerier: func(fq *fakeGroupQuerier) {
				fq.createGrpErr = errors.New("db error")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedCode:   "database_error",
		},
		{
			name:   "DB_Error_Create_Member",
			userID: ownerUUID,
			payload: CreateGroupRequest{
				Name: "Test Group",
				Members: []GroupMemberInput{
					{Name: "Alex", IsOwner: false},
				},
			},
			setupQuerier: func(fq *fakeGroupQuerier) {
				fq.createMemErr = errors.New("db member error")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedCode:   "database_error",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fq := newFakeGroupQuerier()
			if tt.setupQuerier != nil {
				tt.setupQuerier(fq)
			}
			h := NewGroupHandler(fq, logger)
			r := setupGroupTestRouter(h, tt.userID)

			var body bytes.Buffer
			_ = json.NewEncoder(&body).Encode(tt.payload)

			req := httptest.NewRequest(http.MethodPost, "/api/groups", &body)
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			r.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Fatalf("expected status %d, got %d. Body: %s", tt.expectedStatus, w.Code, w.Body.String())
			}

			if tt.expectedCode != "" {
				var env ErrorEnvelope
				if err := json.Unmarshal(w.Body.Bytes(), &env); err != nil {
					t.Fatalf("failed to unmarshal error envelope: %v", err)
				}
				if env.Error.Code != tt.expectedCode {
					t.Errorf("expected error code '%s', got '%s'", tt.expectedCode, env.Error.Code)
				}
			} else {
				var env SuccessEnvelope
				if err := json.Unmarshal(w.Body.Bytes(), &env); err != nil {
					t.Fatalf("failed to unmarshal success envelope: %v", err)
				}
				dataMap, ok := env.Data.(map[string]any)
				if !ok {
					t.Fatalf("expected Data map, got %T", env.Data)
				}
				if dataMap["name"] != "Ski Trip 2024" && dataMap["name"] != "Dinner Club" {
					t.Errorf("unexpected group name: %v", dataMap["name"])
				}
			}
		})
	}
}

func TestListGroups(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(httptest.NewRecorder(), nil))
	ownerUUID := "01020304-0506-0708-090a-0b0c0d0e0f10"

	t.Run("Success", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		id := pgtype.UUID{Bytes: [16]byte{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true}
		owner := pgtype.UUID{Bytes: [16]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true}
		fq.groups[formatUUID(id)] = db.Group{ID: id, Name: "Trip", OwnerID: owner}

		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, ownerUUID)

		req := httptest.NewRequest(http.MethodGet, "/api/groups", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", w.Code, w.Body.String())
		}
	})

	t.Run("DB_Error", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		fq.listGrpsErr = errors.New("list error")
		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, ownerUUID)

		req := httptest.NewRequest(http.MethodGet, "/api/groups", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusInternalServerError {
			t.Fatalf("expected status 500, got %d: %s", w.Code, w.Body.String())
		}
	})

	t.Run("Unauthorized_Missing_User", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, "")

		req := httptest.NewRequest(http.MethodGet, "/api/groups", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Fatalf("expected status 401, got %d: %s", w.Code, w.Body.String())
		}
	})
}

func TestGetGroup(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(httptest.NewRecorder(), nil))
	ownerUUID := "01020304-0506-0708-090a-0b0c0d0e0f10"
	groupUUIDStr := "02020304-0506-0708-090a-0b0c0d0e0f10"

	t.Run("Success", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		id := pgtype.UUID{Bytes: [16]byte{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true}
		owner := pgtype.UUID{Bytes: [16]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true}
		fq.groups[formatUUID(id)] = db.Group{ID: id, Name: "Trip", OwnerID: owner}

		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, ownerUUID)

		req := httptest.NewRequest(http.MethodGet, "/api/groups/"+groupUUIDStr, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", w.Code, w.Body.String())
		}
	})

	t.Run("Not_Found", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, ownerUUID)

		req := httptest.NewRequest(http.MethodGet, "/api/groups/"+groupUUIDStr, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusNotFound {
			t.Fatalf("expected status 404, got %d: %s", w.Code, w.Body.String())
		}
	})

	t.Run("Forbidden_Different_Owner", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		id := pgtype.UUID{Bytes: [16]byte{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, Valid: true}
		otherOwner := pgtype.UUID{Bytes: [16]byte{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9}, Valid: true}
		fq.groups[formatUUID(id)] = db.Group{ID: id, Name: "Trip", OwnerID: otherOwner}

		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, ownerUUID)

		req := httptest.NewRequest(http.MethodGet, "/api/groups/"+groupUUIDStr, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusForbidden {
			t.Fatalf("expected status 403, got %d: %s", w.Code, w.Body.String())
		}
	})

	t.Run("Invalid_UUID", func(t *testing.T) {
		fq := newFakeGroupQuerier()
		h := NewGroupHandler(fq, logger)
		r := setupGroupTestRouter(h, ownerUUID)

		req := httptest.NewRequest(http.MethodGet, "/api/groups/not-a-uuid", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d: %s", w.Code, w.Body.String())
		}
	})
}
