// echo-go: a compiled Go binary, no dependencies beyond net/http. This is the sample that
// exercises a non-Python runtime and a build step that actually compiles something (the
// platform's build node, infra's remote build path).
//
// GET / serves the marker line every sample here serves. GET /echo reflects the request back:
// method, path, headers and body, which is the thing an "echo" service is for and a small proof
// that this is a real HTTP server rather than a static string generator.
package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

var (
	dataDir    = envOr("AGENTCELL_DATA", "/data")
	port       = envOr("PORT", "8080")
	markerPath = filepath.Join(dataDir, "marker")
)

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// marker returns AGENTCELL_SAMPLE_MARKER if the deploy set one, else a value generated once at
// container start and kept in /data/marker -- same contract as every sample here, so a redeploy
// (a new value, whichever source it came from) can be told from a restart (the same value, read
// back from /data).
func marker() string {
	if v := os.Getenv("AGENTCELL_SAMPLE_MARKER"); v != "" {
		return v
	}
	buf := make([]byte, 6)
	_, _ = rand.Read(buf)
	generated := hex.EncodeToString(buf)
	if err := os.MkdirAll(dataDir, 0o755); err != nil {
		log.Printf("cannot create %s: %v", dataDir, err)
		return generated
	}
	if existing, err := os.ReadFile(markerPath); err == nil {
		return strings.TrimSpace(string(existing))
	}
	// Printed rather than swallowed, same reasoning as infra/images/deploy-fixture/app.py: a cell
	// that cannot write its own /data must say so out loud.
	if err := os.WriteFile(markerPath, []byte(generated+"\n"), 0o644); err != nil {
		log.Printf("cannot persist marker to %s: %v", markerPath, err)
	}
	return generated
}

var currentMarker string

func rootHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "agentcell sample: echo-go %s\n", currentMarker)
}

func echoHandler(w http.ResponseWriter, r *http.Request) {
	body, _ := io.ReadAll(r.Body)
	fmt.Fprintf(w, "method: %s\n", r.Method)
	fmt.Fprintf(w, "path: %s\n", r.URL.Path)
	fmt.Fprintf(w, "headers:\n")
	for name, values := range r.Header {
		fmt.Fprintf(w, "  %s: %s\n", name, strings.Join(values, ", "))
	}
	fmt.Fprintf(w, "body: %s\n", string(body))
}

func main() {
	currentMarker = marker()

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		rootHandler(w, r)
	})
	mux.HandleFunc("/echo", echoHandler)

	// 0.0.0.0: a bind address inside the cell's own network namespace, not an address naming
	// another service -- same note as every other sample here.
	log.Printf("echo-go listening on 0.0.0.0:%s", port)
	if err := http.ListenAndServe("0.0.0.0:"+port, mux); err != nil {
		log.Fatal(err)
	}
}
