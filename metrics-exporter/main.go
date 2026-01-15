package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	defaultIdleTimeoutMinutes = 10
	defaultMetricsPort        = 8080
)

var (
	// Prometheus metrics
	lastActivityTimestamp = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "claude_last_activity_timestamp_seconds",
			Help: "Unix timestamp of last Claude Code or Happy activity",
		},
		[]string{"pod", "repository"},
	)

	sessionActive = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "claude_session_active",
			Help: "Whether the agent is active (1) or idle (0) based on idle timeout",
		},
		[]string{"pod", "repository"},
	)

	sessionsTotal = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "claude_sessions_total",
			Help: "Total number of Claude Code sessions in history",
		},
		[]string{"pod", "repository"},
	)

	minutesSinceLastActivity = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "claude_minutes_since_last_activity",
			Help: "Minutes since last activity was detected",
		},
		[]string{"pod", "repository"},
	)

	exporterHealthy = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "claude_exporter_healthy",
			Help: "Whether the metrics exporter is healthy (1) or not (0)",
		},
		[]string{"pod"},
	)
)

func init() {
	// Register metrics with Prometheus
	prometheus.MustRegister(lastActivityTimestamp)
	prometheus.MustRegister(sessionActive)
	prometheus.MustRegister(sessionsTotal)
	prometheus.MustRegister(minutesSinceLastActivity)
	prometheus.MustRegister(exporterHealthy)
}

// Config holds the application configuration
type Config struct {
	ClaudeDir        string
	HappyDir         string
	IdleTimeoutMins  int
	MetricsPort      int
	PodName          string
	RepositoryName   string
	UpdateIntervalSec int
}

func loadConfig() *Config {
	config := &Config{
		ClaudeDir:        getEnv("CLAUDE_DIR", "/home/agent/.claude"),
		HappyDir:         getEnv("HAPPY_DIR", "/home/agent/.happy"),
		IdleTimeoutMins:  getEnvInt("IDLE_TIMEOUT_MINUTES", defaultIdleTimeoutMinutes),
		MetricsPort:      getEnvInt("METRICS_PORT", defaultMetricsPort),
		PodName:          getEnv("POD_NAME", "unknown"),
		RepositoryName:   getEnv("REPOSITORY_NAME", "unknown"),
		UpdateIntervalSec: getEnvInt("UPDATE_INTERVAL_SECONDS", 30),
	}

	log.Printf("Configuration loaded:")
	log.Printf("  Claude Dir: %s", config.ClaudeDir)
	log.Printf("  Happy Dir: %s", config.HappyDir)
	log.Printf("  Idle Timeout: %d minutes", config.IdleTimeoutMins)
	log.Printf("  Metrics Port: %d", config.MetricsPort)
	log.Printf("  Pod Name: %s", config.PodName)
	log.Printf("  Repository: %s", config.RepositoryName)
	log.Printf("  Update Interval: %d seconds", config.UpdateIntervalSec)

	return config
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}

// findLatestModTime finds the most recent modification time across multiple file patterns
func findLatestModTime(patterns []string) (time.Time, error) {
	var latest time.Time

	for _, pattern := range patterns {
		matches, err := filepath.Glob(pattern)
		if err != nil {
			log.Printf("Error globbing pattern %s: %v", pattern, err)
			continue
		}

		for _, match := range matches {
			info, err := os.Stat(match)
			if err != nil {
				continue // Skip files we can't stat
			}

			if info.ModTime().After(latest) {
				latest = info.ModTime()
			}
		}
	}

	if latest.IsZero() {
		return latest, fmt.Errorf("no files found matching patterns")
	}

	return latest, nil
}

// countSessions counts the number of session files
func countSessions(projectsDir string) int {
	count := 0
	pattern := filepath.Join(projectsDir, "*", "*.jsonl")
	matches, err := filepath.Glob(pattern)
	if err == nil {
		count = len(matches)
	}
	return count
}

// updateMetrics updates all Prometheus metrics based on current filesystem state
func updateMetrics(config *Config) error {
	labels := prometheus.Labels{
		"pod":        config.PodName,
		"repository": config.RepositoryName,
	}

	// Find last activity time from Claude projects and Happy logs
	patterns := []string{
		filepath.Join(config.ClaudeDir, "projects", "*", "*.jsonl"),
		filepath.Join(config.ClaudeDir, "history.jsonl"),
		filepath.Join(config.HappyDir, "logs", "*.log"),
	}

	lastActivity, err := findLatestModTime(patterns)
	if err != nil {
		log.Printf("Warning: Could not find activity files: %v", err)
		// Set metrics to indicate no activity found
		lastActivityTimestamp.With(labels).Set(0)
		sessionActive.With(labels).Set(0)
		minutesSinceLastActivity.With(labels).Set(999999) // Very large number
		exporterHealthy.With(prometheus.Labels{"pod": config.PodName}).Set(0)
		return err
	}

	// Calculate time since last activity
	now := time.Now()
	minutesSince := now.Sub(lastActivity).Minutes()
	isActive := minutesSince < float64(config.IdleTimeoutMins)

	// Update metrics
	lastActivityTimestamp.With(labels).Set(float64(lastActivity.Unix()))

	if isActive {
		sessionActive.With(labels).Set(1)
	} else {
		sessionActive.With(labels).Set(0)
	}

	minutesSinceLastActivity.With(labels).Set(minutesSince)

	// Count total sessions
	projectsDir := filepath.Join(config.ClaudeDir, "projects")
	totalSessions := countSessions(projectsDir)
	sessionsTotal.With(labels).Set(float64(totalSessions))

	// Mark exporter as healthy
	exporterHealthy.With(prometheus.Labels{"pod": config.PodName}).Set(1)

	log.Printf("Metrics updated - Last activity: %s (%.1f min ago), Active: %v, Sessions: %d",
		lastActivity.Format(time.RFC3339),
		minutesSince,
		isActive,
		totalSessions,
	)

	return nil
}

func main() {
	log.Println("Starting Claude Code Metrics Exporter")

	config := loadConfig()

	// Start metrics update loop
	go func() {
		ticker := time.NewTicker(time.Duration(config.UpdateIntervalSec) * time.Second)
		defer ticker.Stop()

		// Update immediately on start
		if err := updateMetrics(config); err != nil {
			log.Printf("Initial metrics update failed: %v", err)
		}

		for range ticker.C {
			if err := updateMetrics(config); err != nil {
				log.Printf("Metrics update failed: %v", err)
			}
		}
	}()

	// Expose metrics HTTP endpoint
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "OK\n")
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		fmt.Fprintf(w, `
<!DOCTYPE html>
<html>
<head><title>Claude Code Metrics Exporter</title></head>
<body>
<h1>Claude Code Metrics Exporter</h1>
<ul>
<li><a href="/metrics">Metrics</a> - Prometheus metrics endpoint</li>
<li><a href="/health">Health</a> - Health check endpoint</li>
</ul>
<p>Pod: %s</p>
<p>Repository: %s</p>
<p>Idle Timeout: %d minutes</p>
</body>
</html>
`, config.PodName, config.RepositoryName, config.IdleTimeoutMins)
	})

	addr := fmt.Sprintf(":%d", config.MetricsPort)
	log.Printf("Serving metrics on %s", addr)
	log.Printf("Endpoints:")
	log.Printf("  - http://0.0.0.0:%d/metrics (Prometheus metrics)", config.MetricsPort)
	log.Printf("  - http://0.0.0.0:%d/health (Health check)", config.MetricsPort)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start HTTP server: %v", err)
	}
}
