package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

const (
	LOOKING_FOR_INSTRUCTION = iota
	PARSING_FIRST_NUMBER
	EXPECTING_COMMA
	PARSING_SECOND_NUMBER
	EXPECTING_CLOSING_PAREN
)

func gonkulator(input string, enableToggle bool) int {
	state := LOOKING_FOR_INSTRUCTION
	var X, Y int
	var result int
	var mulEnabled = !enableToggle
	buf := strings.Builder{}

	for i := 0; i < len(input); i++ {
		remainingInput := input[i:]

		switch state {
		case LOOKING_FOR_INSTRUCTION:
			if strings.HasPrefix(remainingInput, "mul(") && (!enableToggle || mulEnabled) {
				state = PARSING_FIRST_NUMBER
				i += len("mul(") - 1
				buf.Reset()
			} else if enableToggle && strings.HasPrefix(remainingInput, "do()") {
				mulEnabled = true
				i += len("do()") - 1
			} else if enableToggle && strings.HasPrefix(remainingInput, "don't()") {
				mulEnabled = false
				i += len("don't()") - 1
			}
		case PARSING_FIRST_NUMBER:
			char := remainingInput[0]
			if char >= '0' && char <= '9' {
				buf.WriteByte(char)
			} else if char == ',' {
				num, err := strconv.Atoi(buf.String())
				if err != nil || num < 1 || num > 999 {
					state = LOOKING_FOR_INSTRUCTION
					buf.Reset()
				} else {
					X = num
					state = PARSING_SECOND_NUMBER
					buf.Reset()
				}
			} else {
				state = LOOKING_FOR_INSTRUCTION
				buf.Reset()
			}
		case PARSING_SECOND_NUMBER:
			char := remainingInput[0]
			if char >= '0' && char <= '9' {
				buf.WriteByte(char)
			} else if char == ')' {
				num, err := strconv.Atoi(buf.String())
				if err != nil || num < 1 || num > 999 {
					state = LOOKING_FOR_INSTRUCTION
					buf.Reset()
				} else {
					Y = num
					result += X * Y
					state = LOOKING_FOR_INSTRUCTION
					buf.Reset()
				}
			} else {
				state = LOOKING_FOR_INSTRUCTION
				buf.Reset()
			}
		}
	}

	return result
}

// ------ Part II -------

// learned a lot from Part I though I could extend it but it does not scale. My
// orig hacky parser for Part I is to janky to keep both states so.... In the
// spirit of Rob Pike, let's choose a DS, and operate on it.

type Parser struct {
	input    string
	position int
	goAhead  bool
	result   int
}

func newParser(input string) *Parser {
	return &Parser{
		input:    input,
		position: 0,
		goAhead:  true,
		result:   0,
	}
}

func (p *Parser) Parse() int {
	// Patterns for toggle and multiplication instructions
	toggle := regexp.MustCompile(`\b(do\(\)|don't\(\)|undo\(\))`)
	mult := regexp.MustCompile(`mul\((\d+),(\d+)\)`)

	for p.position < len(p.input) {
		remainingInput := p.input[p.position:]

		// Match valid tokens
		if toggleMatch := toggle.FindStringIndex(remainingInput); toggleMatch != nil && toggleMatch[0] == 0 {
			token := remainingInput[toggleMatch[0]:toggleMatch[1]]
			p.toggler(token)
			p.position += toggleMatch[1]
		} else if mulMatch := mult.FindStringIndex(remainingInput); mulMatch != nil && mulMatch[0] == 0 {
			token := remainingInput[mulMatch[0]:mulMatch[1]]
			if p.goAhead {
				p.multiplicate(token, mult)
			}
			p.position += mulMatch[1]
		} else {
			// Skip invalid tokens
			p.position++
		}
	}
	return p.result
}


func (p *Parser) multiplicate(tok string, pat *regexp.Regexp) {
	matches := pat.FindStringSubmatch(tok)
	if len(matches) != 3 {
		fmt.Printf("invalid mult token: '%s'\n", tok)
		return
	}

	X, errX := strconv.Atoi(matches[1])
	Y, errY := strconv.Atoi(matches[2])

	if errX == nil &&
		errY == nil &&
		X >= 1 &&
		X <= 999 &&
		Y >= 1 &&
		Y <= 999 {
		p.result += X * Y
		fmt.Printf("Processed mul(%d,%d) = %d, Result so far: %d\n", 
			X, Y, X*Y, p.result) // Debugging output

	}
}

func (p *Parser) toggler(tok string) {
	if tok == "do()" || tok == "undo()" {
		p.goAhead = true
		fmt.Println("Toggle: Enabled mul instructions")
	} else if tok == "don't()" {
		p.goAhead = false
		fmt.Println("Toggle: Disabled mul instructions")
	}
}

func slurp(fileName string) (string, error) {
	file, err := os.Open(fileName)
	if err != nil {
		return "", err
	}
	defer file.Close()

	var sb strings.Builder
	buf := bufio.NewScanner(file)
	for buf.Scan() {
		sb.WriteString(buf.Text())
	}

	return sb.String(), buf.Err()
}


func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <input-file>")
		return
	}

	inputFile := os.Args[1]
	instructions, err := slurp(inputFile)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		return
	}

	// Part I: Uncorrupted mul instructions
	partI := gonkulator(instructions, false)
	
	// Part II: Corrupted mul instructions
	p := newParser(instructions) 
	partII := p.Parse()

	fmt.Printf("Part I: %d\n", partI)
	fmt.Printf("Part II: %d\n", partII)
}
