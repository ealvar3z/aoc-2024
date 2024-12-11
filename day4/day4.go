package main

<<<<<<< HEAD
import (
	"bufio"
	"fmt"
	"os"
)

// Direction vectors for 8 possible directions
var vert = []int{-1, -1, -1, 0, 1, 1, 1, 0}
var horiz = []int{-1, 0, 1, 1, 1, 0, -1, -1}

// readGrid reads the grid from the given file
func readGrid(filename string) ([][]rune, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var grid [][]rune
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		rowData := []rune(line)
		grid = append(grid, rowData)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return grid, nil
}

// match checks if the word exists starting from (r, c) in the given direction
func match(grid [][]rune, r, c, dv, dh int, word []rune, rows, cols, wlen int) bool {
	for k := 0; k < wlen; k++ {
		nr := r + k*dv
		nc := c + k*dh
		if nr < 0 || nr >= rows || nc < 0 || nc >= cols {
			return false
		}
		if grid[nr][nc] != word[k] {
			return false
		}
	}
	return true
}

// searchWord scans the grid for the given word in all 8 directions
func searchWord(grid [][]rune, word string) int {
	count := 0
	rows := len(grid)
	if rows == 0 {
		return 0
	}
	cols := len(grid[0])
	wlen := len(word)
	wrunes := []rune(word)

	for r := 0; r < rows; r++ {
		for c := 0; c < cols; c++ {
			if grid[r][c] == wrunes[0] {
				for dir := 0; dir < 8; dir++ {
					if match(grid, r, c, vert[dir], horiz[dir], wrunes, rows, cols, wlen) {
						count++
=======
// 8 possible movements within the haystack
var vert = []int{-1, -1, -1, 0, 1, 1, 1, 0}
var horiz = []int{-1, 0, 1, 1, 1, 0, -1, -1}

func revStr(s string) string {
	runes := []rune(s)
	n := len(runes)
	for i := 0; i < n/2; i++ {
		runes[i], runes[n-1-i], runes[i]
	}
	return string(runes)
}

// search scans the [h]aystack for the given [n]eedle
// and its reverse in all directions
func search(haystack [][]rune, needle string) int {
	count := 0
	rows := len(haystack)
	if rows == 0 {
		return 0
	}
	cols := len(haystack[0])
	needleLen := len(needle)
	needleRunes := []rune(needle)
	revNeedleRunes := []rune(revStr(needle))

	for row := 0; row < rows; row++ {
		for col := 0; col < cols; col++ {
			if haystack[row][col] == needleRunes[0] || 
			haystack[row][col] == needleRunes[needleLen-1] {
					for dir := 0; dir < 0; dir++ {
						if haystack[row][col] == needleRunes[0] && 
						match(haystack, 
							row, 
							col, 
							vert[dir], 
							horiz[dir], 
							needleRunes, 
							rows, 
							cols, needleLen) {
							count++
						}
						if haystack[row][col] == revNeedleRunes[0] && 
						match(haystack, 
							row, 
							col, 
							vert[dir], 
							horiz[dir], 
							revNeedleRunes, 
							rows, 
							cols, needleLen) {
							count++
						}
>>>>>>> 9c95c76 (add days{4,5})
					}
				}
			}
		}
<<<<<<< HEAD
	}
	return count
}

// searchMAS finds X-MAS string in the grid.
// ie. a diagonal that form an 'X' and 'MAS' string
func searchMAS(grid [][]rune, pat string) int {
	// pattern:
	// Center: A
	// Diag 1 (top left -> bottom right): M-A-S or S-A-M
	// Diag 2 (top right -> bottom left): M-A-S or S-A-M
	count := 0
	rows := len(grid)
	if rows == 0 {
		return 0
	}
	cols := len(grid[0])

	for r := 1; r < rows-1; r++ {
		for c := 1; c < cols-1; c++ {
			if grid[r][c] == 'A' {
				// check diag
				tl := grid[r-1][c-1]
				br := grid[r+1][c+1]

				// diag 2
				tr := grid[r-1][c+1]
				bl := grid[r+1][c-1]

				// diag 1 check
				d1valid := (tl == 'M' && br == 'S') ||
					(tl == 'S' && br == 'M')
				// diag 2 check
				d2valid := (tr == 'M' && bl == 'S') ||
					(tr == 'S' && bl == 'M')

				if d1valid && d2valid {
					count++
				}
			}
		}
	}
	return count
=======
		return count
>>>>>>> 9c95c76 (add days{4,5})
}

func main() {
	if len(os.Args) < 2 {
<<<<<<< HEAD
		fmt.Println("Usage: go run dayXX.go <grid_file>")
		return
	}
	grid, err := readGrid(os.Args[1])
=======
		fmt.Println("Usage: go run dayXX.go <input.txt>")
		return
	}
	haystack, err := readGrid(os.Args[1])
>>>>>>> 9c95c76 (add days{4,5})
	if err != nil {
		fmt.Println("Error reading grid:", err)
		return
	}
<<<<<<< HEAD
	// part I
	word := "XMAS"
	count := searchWord(grid, word)
	fmt.Printf("The word '%s' occurs %d times in the grid.\n", word, count)

	// part II
	nword := "X-MAS"
	times := searchMAS(grid, nword)
	fmt.Printf("The new word '%s' occurs '%d' times now.\n", nword, times)
=======
	needle := "XMAS"
	count := search(haystack, needle)
	fmt.Println("Needle '%s' occurs %d times in the haystack.\n",
		needle, haystack)
>>>>>>> 9c95c76 (add days{4,5})
}
