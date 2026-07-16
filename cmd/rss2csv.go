package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/Stephan5/podcasts/internal/feedcsv"
	"github.com/Stephan5/podcasts/internal/feedrss"
	"github.com/spf13/cobra"
)

func newRSS2CSVCmd() *cobra.Command {
	var (
		repoDir   string
		delimiter string
	)

	cmd := &cobra.Command{
		Use:   "rss2csv <input.xml>",
		Short: "Convert an RSS podcast feed to a CSV file",
		Long: `Parses an RSS XML podcast feed and writes a CSV file with columns:
title, description, date, url.

Episodes are sorted by publication date (ascending).
The output CSV is written alongside the input XML file.`,
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runRSS2CSV(args[0], repoDir, runeFromString(delimiter))
		},
	}

	cmd.Flags().StringVar(&repoDir, "repo-dir", "", "Feed subdirectory name under feed/ (required)")
	cmd.Flags().StringVar(&delimiter, "delimiter", string(rune(feedcsv.DefaultDelimiter)), "CSV field delimiter")
	cmd.MarkFlagRequired("repo-dir") //nolint:errcheck

	return cmd
}

func runRSS2CSV(inputFile, repoDir string, delim rune) error {
	inputAbs, err := filepath.Abs(inputFile)
	if err != nil {
		return fmt.Errorf("resolve input path: %w", err)
	}
	if _, err := os.Stat(inputAbs); err != nil {
		return fmt.Errorf("input file %q not found", inputAbs)
	}

	// Ensure feed/<repoDir> directory exists (relative to parent of input file)
	feedBaseDir := filepath.Dir(filepath.Dir(inputAbs))
	feedRepoPath := filepath.Join(feedBaseDir, "feed", repoDir)
	if err := os.MkdirAll(feedRepoPath, 0755); err != nil {
		return fmt.Errorf("create feed directory: %w", err)
	}

	// If input file is not already in the target dir, copy it
	xmlInTarget := filepath.Join(feedRepoPath, filepath.Base(inputAbs))
	if inputAbs != xmlInTarget {
		data, err := os.ReadFile(inputAbs)
		if err != nil {
			return err
		}
		if err := os.WriteFile(xmlInTarget, data, 0644); err != nil {
			return err
		}
	}

	outputFile := replaceExt(xmlInTarget, ".csv")

	fmt.Printf("Input File:   %q\n", inputAbs)
	fmt.Printf("Repo Dir:     %q\n", repoDir)
	fmt.Printf("Output File:  %q\n", outputFile)
	fmt.Println()

	f, err := os.Open(inputAbs)
	if err != nil {
		return fmt.Errorf("open XML: %w", err)
	}
	defer f.Close()

	parsed, err := feedrss.Parse(f)
	if err != nil {
		return fmt.Errorf("parse RSS: %w", err)
	}

	fmt.Printf("Feed Title:       %q\n", parsed.Title)
	fmt.Printf("Feed Description: %q\n", parsed.Description)
	fmt.Printf("Feed Link:        %q\n", parsed.Link)
	fmt.Printf("Image URL:        %q\n", parsed.ImageURL)
	fmt.Println()

	for _, rec := range parsed.Records {
		fmt.Printf("Title:   %q\nPubDate: %q\nURL:     %q\n\n", rec.Title, rec.Date, rec.URL)
	}

	if err := feedcsv.Write(outputFile, delim, parsed.Records); err != nil {
		return fmt.Errorf("write CSV: %w", err)
	}

	fmt.Printf("Created CSV from podcast XML feed: %s\n", outputFile)
	return nil
}
