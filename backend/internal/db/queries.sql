-- name: CreateUser :one
INSERT INTO users (email, password_hash, full_name)
VALUES ($1, $2, $3)
RETURNING id, email, password_hash, full_name, created_at, updated_at;

-- name: GetUserByEmail :one
SELECT id, email, password_hash, full_name, created_at, updated_at
FROM users
WHERE email = $1 LIMIT 1;

-- name: CreateGroup :one
INSERT INTO groups (name, description, owner_id)
VALUES ($1, $2, $3)
RETURNING id, name, description, owner_id, created_at, updated_at;

-- name: CreateGroupMember :one
INSERT INTO group_members (group_id, name, is_owner)
VALUES ($1, $2, $3)
RETURNING id, group_id, name, is_owner, created_at;

-- name: GetGroupByID :one
SELECT id, name, description, owner_id, created_at, updated_at
FROM groups
WHERE id = $1 LIMIT 1;

-- name: GetGroupsByOwnerID :many
SELECT id, name, description, owner_id, created_at, updated_at
FROM groups
WHERE owner_id = $1
ORDER BY created_at DESC;

-- name: GetGroupMembersByGroupID :many
SELECT id, group_id, name, is_owner, created_at
FROM group_members
WHERE group_id = $1
ORDER BY is_owner DESC, created_at ASC;

-- name: CreateExpense :one
INSERT INTO expenses (group_id, title, description, amount, split_type, tax_amount, discount_amount, metadata)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING id, group_id, title, description, amount, split_type, tax_amount, discount_amount, metadata, created_at;

-- name: CreateExpenseSplit :one
INSERT INTO expense_splits (expense_id, member_id, amount)
VALUES ($1, $2, $3)
RETURNING id, expense_id, member_id, amount;

-- name: GetExpensesByGroupID :many
SELECT id, group_id, title, description, amount, split_type, tax_amount, discount_amount, metadata, created_at
FROM expenses
WHERE group_id = $1
ORDER BY created_at DESC;

-- name: GetExpenseSplitsByExpenseID :many
SELECT id, expense_id, member_id, amount
FROM expense_splits
WHERE expense_id = $1;

-- name: CreateExpensePayment :one
INSERT INTO expense_payments (expense_id, member_id, amount)
VALUES ($1, $2, $3)
RETURNING id, expense_id, member_id, amount;

-- name: GetExpensePaymentsByExpenseID :many
SELECT id, expense_id, member_id, amount
FROM expense_payments
WHERE expense_id = $1;

-- name: CreateExpenseItem :one
INSERT INTO expense_items (expense_id, name, amount)
VALUES ($1, $2, $3)
RETURNING id, expense_id, name, amount;

-- name: GetExpenseItemsByExpenseID :many
SELECT id, expense_id, name, amount
FROM expense_items
WHERE expense_id = $1;

-- name: CreateExpenseItemSplit :one
INSERT INTO expense_item_splits (expense_item_id, member_id)
VALUES ($1, $2)
RETURNING id, expense_item_id, member_id;

-- name: GetExpenseItemSplitsByItemID :many
SELECT id, expense_item_id, member_id
FROM expense_item_splits
WHERE expense_item_id = $1;

-- name: GetExpenseByID :one
SELECT id, group_id, title, description, amount, split_type, tax_amount, discount_amount, metadata, created_at
FROM expenses
WHERE id = $1 AND group_id = $2 LIMIT 1;

-- name: UpdateExpense :one
UPDATE expenses
SET title = $3, description = $4, amount = $5, split_type = $6, tax_amount = $7, discount_amount = $8, metadata = $9
WHERE id = $1 AND group_id = $2
RETURNING id, group_id, title, description, amount, split_type, tax_amount, discount_amount, metadata, created_at;

-- name: DeleteExpense :exec
DELETE FROM expenses
WHERE id = $1 AND group_id = $2;

-- name: DeleteExpensePayments :exec
DELETE FROM expense_payments WHERE expense_id = $1;

-- name: DeleteExpenseSplits :exec
DELETE FROM expense_splits WHERE expense_id = $1;

-- name: DeleteExpenseItems :exec
DELETE FROM expense_items WHERE expense_id = $1;

-- name: DeleteGroup :exec
DELETE FROM groups WHERE id = $1 AND owner_id = $2;
