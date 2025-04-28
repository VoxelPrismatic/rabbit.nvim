package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"regexp"
	"slices"
	"sort"

	"strings"
)

const (
	FZF_Match       = 10.0
	FZF_Bonus       = 10.0
	FZF_Consecutive = 5.0
	FZF_GapPenalty  = 3.0
	FZF_GapLength   = 1.0
)

type Color struct {
	R      int
	G      int
	B      int
	Rabbit string
}

func (c Color) wrap(char rune) string {
	return fmt.Sprintf("\x1b[38;2;%d;%d;%dm%s\x1b[0m", c.R, c.G, c.B, string(char))
}

type Query struct {
	Content string
	Exact   bool
	Word    bool
	Prefix  bool
	Suffix  bool
	Inverse bool
	Color
}

type Haystack struct {
	Content string
	Matches map[int][]Query
}

type RabbitHLLine struct {
	Text string   `json:"text"`
	Hl   []string `json:"hl"`
}

type RabbitOutput struct {
	Lines []RabbitHLLine `json:"lines"`
	Text  string         `json:"text"`
}

func main() {
	lines := getLines()
	stacks := Compute(os.Args, lines)
	joy := []RabbitOutput{}
	for _, stack := range stacks {
		joy = append(joy, stack.Rabbit())
		stack.Print()
	}
	data, err := json.Marshal(joy)
	if err != nil {
		panic(err)
	}
	fmt.Fprintln(os.Stderr, string(data))
}

func Compute(tokens []string, lines []string) []Haystack {
	filters := [][]Query{}
	doOr := false

	for _, token := range tokens {
		if token == "|" {
			doOr = true
			continue
		}

		if doOr {
			doOr = false
		} else {
			filters = append(filters, []Query{})
		}

		query := parseToken(token)

		last := len(filters) - 1
		filters[last] = append(filters[last], query)
	}

	stacks := map[float64][]Haystack{}

	for _, line := range lines {
		haystack := collectHaystack(filters, line)
		if haystack != nil {
			score := haystack.Score()
			stacks[score] = append(stacks[score], *haystack)
		}
	}

	ret := []Haystack{}
	scores := []float64{}
	for k := range stacks {
		scores = append(scores, k)
	}

	sort.Float64s(scores)
	slices.Reverse(scores)

	for _, score := range scores {
		ret = append(ret, stacks[score]...)
	}

	return ret
}

func (query Query) Haystack(line string) []int {
	l := len(query.Content)
	if query.Prefix {
		if strings.HasPrefix(line, query.Content) {
			if query.Inverse {
				return []int{}
			}

			if query.Word {
				re := regexp.MustCompile(fmt.Sprintf(`^%s\b`, query.Content))
				if !re.MatchString(line) {
					return []int{}
				}
			}

			ret := make([]int, l)
			for i := range l {
				ret[i] = i
			}
			return ret
		} else if query.Inverse {
			return []int{-1}
		}

		return []int{}
	}

	if query.Suffix {
		if strings.HasSuffix(line, query.Content) {
			if query.Inverse {
				return []int{}
			}

			if query.Word {
				re := regexp.MustCompile(fmt.Sprintf(`\b%s$`, query.Content))
				if !re.MatchString(line) {
					return []int{}
				}
			}

			ret := make([]int, l)
			for i := range l {
				ret[i] = len(line) - l + i
			}
			return ret
		} else if !query.Inverse {
			return []int{-1}
		}

		return []int{}
	}

	if query.Exact {
		if query.Word {
			re := regexp.MustCompile(fmt.Sprintf(`\b%s\b`, query.Content))
			matches := re.FindAllStringIndex(line, -1)
			ret := []int{}
			for _, group := range matches {
				for _, idx := range group {
					if line[idx:min(idx+l, len(line))] != query.Content {
						continue
					}
					for q := idx; q < idx+l; q++ {
						ret = append(ret, q)
					}
				}
			}

			if query.Inverse && len(ret) > 0 {
				return []int{}
			} else if query.Inverse && len(ret) == 0 {
				return []int{-1}
			} else {
				return ret
			}
		}

		ret := []int{}

		sum := 0
		next := strings.Index(line[sum:], query.Content)
		for next != -1 {
			sum = sum + next
			for i := sum; i < sum+l; i++ {
				ret = append(ret, i)
			}
			sum = sum + l
			next = strings.Index(line[sum:], query.Content)
		}

		if query.Inverse && len(ret) > 0 {
			return []int{}
		} else if query.Inverse && len(ret) == 0 {
			return []int{-1}
		} else {
			return ret
		}
	}

	ret := []int{}
	token := query.Content
	for i := len(line) - 1; i >= 0; i-- {
		if line[i] == token[len(token)-1] {
			token = token[:len(token)-1]
			ret = append(ret, i)
			if len(token) == 0 {
				break
			}
		}
	}

	if query.Inverse && len(token) != 0 {
		return []int{-1}
	} else if query.Inverse && len(token) == 0 {
		return []int{}
	} else if len(token) == 0 {
		return ret
	} else {
		return []int{}
	}
}

func collectHaystack(filters [][]Query, line string) *Haystack {
	ret := Haystack{
		Content: line,
		Matches: map[int][]Query{},
	}
	line = strings.ToLower(line)
	for _, group := range filters {
		didMatch := false
		for _, query := range group {
			idxs := query.Haystack(line)
			if len(idxs) > 0 {
				didMatch = true
			}
			for _, idx := range idxs {
				ret.Matches[idx] = append(ret.Matches[idx], query)
			}
		}
		if !didMatch {
			return nil
		}
	}
	return &ret
}

func (hay Haystack) Bonus() []float64 {
	ret := make([]float64, len(hay.Content))
	for i := range ret {
		char := rune(hay.Content[max(0, i-1)])
		if i == 0 || strings.ContainsRune("/_-.: ", char) {
			ret[i] = 1.0
		} else if 'A' <= char && char <= 'Z' {
			ret[i] = 0.5
		} else if 'a' <= char && char <= 'z' {
			ret[i] = 0.5
		} else if '0' <= char && char <= '9' {
			ret[i] = 0.5
		} else {
			ret[i] = 0.0
		}
	}
	return ret
}

func (hay Haystack) Score() float64 {
	inverse := map[Query][]int{}
	for p, q := range hay.Matches {
		for _, query := range q {
			inverse[query] = append(inverse[query], p)
		}
	}

	total := 0.0
	bonuses := hay.Bonus()
	for _, pos := range inverse {
		if len(pos) == 0 {
			continue
		}

		sort.Ints(pos)
		score := 0.0
		for _, p := range pos {
			if p >= 0 {
				score += FZF_Match + FZF_Bonus*bonuses[p]
			}
		}

		for i := range len(pos) - 1 {
			gap := pos[i+1] - pos[i]
			if gap == 1 {
				score += FZF_Consecutive
			} else {
				score -= FZF_GapPenalty + float64(gap)*FZF_GapLength
			}
		}

		total += score
	}
	return total
}

func (hay Haystack) Print() {
	for i, char := range hay.Content {
		q, ok := hay.Matches[i]
		if ok {
			fmt.Printf(q[0].Color.wrap(char))
		} else {
			fmt.Printf("%s", string(char))
		}
	}
	fmt.Println()
}

func (hay Haystack) Rabbit() RabbitOutput {
	ret := []RabbitHLLine{}
	for i, char := range hay.Content {
		q, ok := hay.Matches[i]
		hl := []string{}
		if ok {
			for _, query := range q {
				hl = append(hl, query.Color.Rabbit)
			}
		} else {
			hl = append(hl, "rabbit.files.file")
		}

		if len(ret) == 0 || !slices.Equal(ret[len(ret)-1].Hl, hl) {
			ret = append(ret, RabbitHLLine{
				Text: string(char),
				Hl:   hl,
			})
		} else {
			ret[len(ret)-1].Text += string(char)
		}
	}

	return RabbitOutput{
		Lines: ret,
		Text:  hay.Content,
	}
}

func parseToken(token string) Query {
	query := Query{
		Color: Color{
			R: rand.Intn(256),
			G: rand.Intn(256),
			B: rand.Intn(256),
		},
	}

	switch rand.Intn(7) {
	case 0:
		query.Color.Rabbit = "rabbit.paint.love"
	case 1:
		query.Color.Rabbit = "rabbit.paint.rose"
	case 2:
		query.Color.Rabbit = "rabbit.paint.gold"
	case 3:
		query.Color.Rabbit = "rabbit.paint.iris"
	case 4:
		query.Color.Rabbit = "rabbit.paint.foam"
	case 5:
		query.Color.Rabbit = "rabbit.paint.tree"
	case 6:
		query.Color.Rabbit = "rabbit.paint.pine"
	}

PrefixToken:
	for len(token) > 0 {
		switch token[0] {
		case '!':
			query.Inverse = true
			query.Exact = true
		case '^':
			query.Prefix = true
			query.Exact = true
		case '\'':
			query.Exact = true
		default:
			break PrefixToken
		}
		token = token[1:]
	}

SuffixToken:
	for len(token) > 0 {
		switch token[len(token)-1] {
		case '$':
			query.Suffix = true
			query.Exact = true
		case '\'':
			query.Word = true
			query.Exact = true
		default:
			break SuffixToken
		}
		token = token[:len(token)-1]
	}

	query.Content = strings.ToLower(token)
	return query
}

func getLines() []string {
	_, err := os.Stdin.Stat()
	if err != nil {
		lines := []string{}
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			lines = append(lines, scanner.Text())
		}

		os.Args = os.Args[1:]
		return lines
	}

	if len(os.Args) < 2 {
		fmt.Println("No directory to scan. Either provide a directory or pipe output into this program.")
		os.Exit(1)
	}

	cmd := exec.Command("find", os.Args[1], "-type", "f", "-print0")
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		panic(err)
	}
	if err = cmd.Start(); err != nil {
		panic(err)
	}

	stdout, err := io.ReadAll(stdoutPipe)
	if err != nil {
		panic(err)
	}

	if err = cmd.Wait(); err != nil {
		panic(err)
	}

	os.Args = os.Args[2:]
	return strings.Split(string(stdout), "\x00")
}
