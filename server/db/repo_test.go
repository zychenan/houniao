package db

import (
	"testing"
)

func setupTestDB(t *testing.T) *DB {
	t.Helper()
	dir := t.TempDir()
	db, err := New(dir)
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	t.Cleanup(func() { db.Close() })
	return db
}

func TestSaveAndPullSince(t *testing.T) {
	db := setupTestDB(t)

	seq1, err := db.SaveItem("clipboard", "hello", "d1", "phone")
	if err != nil {
		t.Fatalf("SaveItem 1: %v", err)
	}
	if seq1 != 1 {
		t.Errorf("seq1 = %d, want 1", seq1)
	}

	seq2, err := db.SaveItem("clipboard", "world", "d2", "pc")
	if err != nil {
		t.Fatalf("SaveItem 2: %v", err)
	}
	if seq2 != 2 {
		t.Errorf("seq2 = %d, want 2", seq2)
	}

	items, err := db.PullSince("clipboard", 0)
	if err != nil {
		t.Fatalf("PullSince: %v", err)
	}
	if len(items) != 2 {
		t.Fatalf("len(items) = %d, want 2", len(items))
	}
	if items[0].Content != "hello" || items[1].Content != "world" {
		t.Errorf("unexpected content: %+v", items)
	}
}

func TestDuplicateHash(t *testing.T) {
	db := setupTestDB(t)

	_, err := db.SaveItem("clipboard", "dup", "d1", "phone")
	if err != nil {
		t.Fatalf("first save: %v", err)
	}

	// The hash of "dup" should already exist — verify ExistsByHash works
	exists, err := db.ExistsByHash("clipboard", "dup")
	if err != nil {
		t.Fatalf("ExistsByHash: %v", err)
	}
	if !exists {
		t.Error("should detect duplicate")
	}
}

func TestCleanExpired(t *testing.T) {
	db := setupTestDB(t)

	if _, err := db.SaveItem("clipboard", "x", "d1", "p"); err != nil {
		t.Fatal(err)
	}
	if err := db.CleanExpired("clipboard", -1); err != nil {
		t.Fatal(err)
	}
	items, _ := db.PullSince("clipboard", 0)
	if len(items) != 0 {
		t.Errorf("expected empty after clean, got %d", len(items))
	}
}
