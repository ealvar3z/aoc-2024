package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

var UsageError = errors.New("Usage: mk run_input_dayXX or mk run_sample_dayXX")

type input struct {
	data         [][]int
	origReport   [][]int
	dampedReport []string
}

func die(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func (i *input) isSafe(r []int) bool {
	// empty or single list edge case
	if len(r) <= 1 {
		return true
	}
	inc := r[1] > r[0]
	dec := r[1] < r[0]

	for j := 1; j < len(r); j++ {
		diff := r[j] - r[j-1]

		// adjacency check
		if diff < -3 || diff > 3 {
			return false
		}

		// monotonicity check
		if (inc && diff < 0) || (dec && diff > 0) {
			return false
		}

		if diff == 0 {
			return false
		}
	}
	return true
}

func (i *input) dampened(r []int) (bool, string) {
	for idx := 0; idx < len(r); idx++ {
		dampenedRow := append([]int(nil), r[:idx]...)
		dampenedRow = append(dampenedRow, r[idx+1:]...)
		if i.isSafe(dampenedRow) {
			// Highlight the removed element and format the output
			var highlighted []string
			for j, val := range r {
				if j == idx {
					highlighted = append(highlighted, fmt.Sprintf("*%d*", val))
				} else {
					highlighted = append(highlighted, strconv.Itoa(val))
				}
			}
			return true, strings.Join(highlighted, " ")
		}
	}
	return false, ""
}

func (i *input) slurp(fn string) error {
	f, err := os.Open(fn)
	die(err)
	defer f.Close()

	var inputData [][]int
	buf := bufio.NewScanner(f)
	for buf.Scan() {
		line := strings.TrimSpace(buf.Text())
		if line == "" {
			continue
		}
		fields := strings.Fields(line)
		row := make([]int, len(fields))
		for j, field := range fields {
			num, err := strconv.Atoi(field)
			die(err)
			row[j] = num
		}
		inputData = append(inputData, row)
	}
	die(buf.Err())
	i.data = inputData
	return nil

}

func (i *input) analysis() {
	for _, row := range i.data {
		if i.isSafe(row) {
			i.origReport = append(i.origReport, row)
			// fmt.Printf("Row %v: safe w/out dampening.\n", row)
		} else if ok, modified := i.dampened(row); ok {
			i.dampedReport = append(i.dampedReport, modified)
			// fmt.Printf("Row %v: Safe by dampening as %s.\n", row, modified)
		} else {
			continue
			// fmt.Printf("Row %v: Unsafe.\n", row)
		}
	}
}

func (i *input) printReports() {
	fmt.Printf("Part I: %d reports are safe.\n", len(i.origReport))
	//	for _, row := range i.origReport {
	//		fmt.Println(row)
	//	}

	count := len(i.origReport) + len(i.dampedReport)
	fmt.Printf("Part II: Thanks to the Problem Dampener, %d reports are actually safe!\n", count)
	//	for _, row := range i.dampedReport {
	//		fmt.Println(row)
	//	}
}

func main() {
	if len(os.Args) != 2 {
		die(UsageError)
	}

	fn := os.Args[1]
	data := &input{}

	err := data.slurp(fn)
	die(err)

	data.analysis()
	data.printReports()
}
