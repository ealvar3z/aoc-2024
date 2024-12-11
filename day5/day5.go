package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

func parser(rules []string) map[int][]int {
	orderingRules := make(map[int][]int)
	for _, rule := range rules {
		parts := strings.Split(rule, "|")
		if len(parts) != 2 {
			continue
		}
		x, _ := strconv.Atoi(parts[0])
		y, _ := strconv.Atoi(parts[1])
		orderingRules[x] = append(orderingRules[x], y)
	}
	return orderingRules
}

func isValid(update []int, rules map[int][]int) bool {
	position := make(map[int]int)
	for i, page := range update {
		position[page] = i
	}
	for x, yList := range rules {
		for _, y := range yList {
			xPos, xOk := position[x]
			yPos, yOk := position[y]
			if xOk && yOk && xPos >= yPos {
				return false
			}
		}
	}
	return true
}

func mid(update []int) int {
	return update[len(update)/2]
}

func parse(updateStrings []string) [][]int {
	var updates [][]int
	for _, updateStr := range updateStrings {
		parts := strings.Split(updateStr, ",")
		var update []int
		for _, part := range parts {
			num, _ := strconv.Atoi(strings.TrimSpace(part))
			update = append(update, num)
		}
		updates = append(updates, update)
	}
	return updates
}

func readFile(filename string) ([]string, []string, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, nil, err
	}
	defer file.Close()

	var rules []string
	var updates []string

	buf := bufio.NewScanner(file)
	isRules := true
	for buf.Scan() {
		line := buf.Text()
		if line == "" {
			isRules = false
			continue
		}
		if isRules {
			rules = append(rules, line)
		} else {
			updates = append(updates, line)
		}
	}
	return rules, updates, buf.Err()
}

func partI(updates [][]int, rules map[int][]int) int {
	sum := 0
	for _, update := range updates {
		if isValid(update, rules) {
			sum += mid(update)
		}
	}
	return sum
}

func partII(updates [][]int, rules map[int][]int) int {
	sum := 0
	for _, update := range updates {
		if !isValid(update, rules) {
			corrected := correctOrder(update, rules)
			sum += mid(corrected)
		}
	}
	return sum
}

func correctOrder(update []int, rules map[int][]int) []int {
	topoSort := make([]int, 0, len(update))
	tracker := make(map[int]int)
	pageSet := make(map[int]bool)

	// Count dependencies
	for _, page := range update {
		pageSet[page] = true
	}

	for x, yList := range rules {
		if !pageSet[x] {
			continue
		}
		for _, y := range yList {
			if pageSet[y] {
				tracker[y]++
			}
		}
	}

	queue := []int{}
	for _, page := range update {
		if tracker[page] == 0 {
			queue = append(queue, page)
		}
	}

	// Topological sort
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		topoSort = append(topoSort, current)
		for _, dependent := range rules[current] {
			if pageSet[dependent] {
				tracker[dependent]--
				if tracker[dependent] == 0 {
					queue = append(queue, dependent)
				}
			}
		}
	}

	return topoSort
}

func main() {
	filename := os.Args[1]
	rulesInput, updateInput, err := readFile(filename)
	if err != nil {
		log.Fatalf("Error reading file: '%v'\n", err)
	}
	orderingRules := parser(rulesInput)
	updates := parse(updateInput)

	sum := partI(updates, orderingRules)
	fmt.Println("Sum of middle pages:", sum)

	correctOrderSum := partII(updates, orderingRules)
	fmt.Println("Sum of middle pages after correction", correctOrderSum)
}
