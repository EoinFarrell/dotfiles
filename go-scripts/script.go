package main

import (
	"encoding/json"
	"strings"

	"github.com/Masterminds/semver"
	"github.com/bitfield/script"
)

type Package struct {
	Name             string   `json:"name"`
	InstalledVersion []string `json:"installed_versions"`
	CurrentVersion   string   `json:"current_version"`
	// Pinned           string   `json:"pinned"`
	// PinnedVersion    string   `json:"pinned_version"`
}

type Homebrew struct {
	Casks    []Package `json:"casks"`
	Formulae []Package `json:"formulae"`
}

func main() {
	var myStoredVariable Homebrew

	asdf, _ := script.Stdin().JQ(".").String()

	json.Unmarshal([]byte(asdf), &myStoredVariable)

	var toUpdate []string

	toUpdate = upgradePackage(myStoredVariable.Casks, toUpdate)
	toUpdate = upgradePackage(myStoredVariable.Formulae, toUpdate)

	// Join the slice into a single string with newlines
	toUpdateString := strings.Join(toUpdate, " ")

	// Create a reader from the string
	toUpdateReader := strings.NewReader(toUpdateString)

	// Use the reader (example: print its content)
	// fmt.Println("Packages to update:")
	script.NewPipe().WithReader(toUpdateReader).Stdout()
}

func upgradePackage(packages []Package, toUpdate []string) []string {
	for _, v := range packages {
		installed, err := semver.NewConstraint("^" + v.InstalledVersion[0])
		if err != nil {
			// Handle constraint not being parsable.
			// fmt.Println(err)
			continue
		}

		current, err := semver.NewVersion(v.CurrentVersion)
		if err != nil {
			// Handle version not being parsable.
			// fmt.Println(err)
			continue
		}

		if installed.Check(current) {
			toUpdate = append(toUpdate, v.Name)
			// fmt.Println("Update: " + v.Name + ": " + v.InstalledVersion[0] + " -> " + v.CurrentVersion)
		} else {
			// fmt.Println("Skip:" + v.Name + ": " + v.InstalledVersion[0] + " -> " + v.CurrentVersion)
		}
	}

	return toUpdate
}
