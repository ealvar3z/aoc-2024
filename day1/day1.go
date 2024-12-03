package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
)

type input struct {
	l []int
	r []int
}

func (i *input) slurp(fn string) error {
	file, err := os.Open(fn)
	if err != nil {
		return err
	}
	defer file.Close()

	buf := bufio.NewScanner(file)
	for buf.Scan() {
		line := buf.Text()
		cols := strings.Fields(line)
		if len(cols) != 2 {
			return fmt.Errorf("you parsed the wrong file: %s:", line)
		}
		lvalue, err := strconv.Atoi(cols[0])
		if err != nil {
			return err
		}
		rvalue, err := strconv.Atoi(cols[1])
		if err != nil {
			return err
		}

		i.l = append(i.l, lvalue)
		i.r = append(i.r, rvalue)

	}
	if err := buf.Err(); err != nil {
		return err
	}
	return nil
}

func (i *input) calc_dist() int {
	sort.Ints(i.l)
	sort.Ints(i.r)

	diff := 0
	for j := 0; j < len(i.l); j++ {
		diff += int(math.Abs(float64(i.l[j] - i.r[j])))
	}
	return diff
}

func (i *input) sim_score() int {
	score := 0
	counts := make(map[int]int)
	for _, n := range i.r {
		counts[n]++
	}
	for _, n := range i.l {
		score += n * counts[n]
	}
	return score

}

func main() {
	data := &input{}

	err := data.slurp("input.txt")
	if err != nil {
		fmt.Println("oops:", err)
		return
	}

	dist := data.calc_dist()
	sim := data.sim_score()

	fmt.Println("part 1:", dist)
	fmt.Println("part 2:", sim)
}
