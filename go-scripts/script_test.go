package main

import "testing"

func TestUpgradePackage(t *testing.T) {
	packages := []Package{
		{Name: "no-installed-version", InstalledVersion: []string{}, CurrentVersion: "2.0.0"},
		{Name: "needs-upgrade", InstalledVersion: []string{"1.0.0"}, CurrentVersion: "1.5.0"},
		{Name: "major-bump", InstalledVersion: []string{"1.0.0"}, CurrentVersion: "2.0.0"},
	}

	got := upgradePackage(packages, nil)

	want := []string{"needs-upgrade"}
	if len(got) != len(want) {
		t.Fatalf("upgradePackage() = %v, want %v", got, want)
	}
	for i, name := range want {
		if got[i] != name {
			t.Fatalf("upgradePackage() = %v, want %v", got, want)
		}
	}
}

func TestParseHomebrewJSON(t *testing.T) {
	t.Run("valid JSON with mixed casks and formulae", func(t *testing.T) {
		input := []byte(`{
			"casks": [
				{"name": "some-cask", "installed_versions": [], "current_version": "3.0.0"}
			],
			"formulae": [
				{"name": "some-formula", "installed_versions": ["1.2.0"], "current_version": "1.3.0"}
			]
		}`)

		hb, err := parseHomebrewJSON(input)
		if err != nil {
			t.Fatalf("parseHomebrewJSON() unexpected error: %v", err)
		}
		if len(hb.Casks) != 1 || len(hb.Formulae) != 1 {
			t.Fatalf("parseHomebrewJSON() = %+v, want 1 cask and 1 formula", hb)
		}
	})

	t.Run("malformed JSON returns an error", func(t *testing.T) {
		_, err := parseHomebrewJSON([]byte("not json"))
		if err == nil {
			t.Fatal("parseHomebrewJSON() expected error for malformed input, got nil")
		}
	})
}
