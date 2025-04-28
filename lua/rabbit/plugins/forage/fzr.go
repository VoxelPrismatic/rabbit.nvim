package main

import (
	"bufio"
	"fmt"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"regexp"

	"strings"
)

type Color struct {
	R int
	G int
	B int
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
	Matches map[int]Query
}

func main() {
	lines := getLines()
	filters := [][]Query{}
	doOr := false

	for _, token := range os.Args {
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

		filters[len(filters)-1] = append(filters[len(filters)-1], query)
	}

	for _, line := range lines {
		haystack := collectHaystack(filters, line)
		if haystack != nil {
			for i, char := range haystack.Content {
				q, ok := haystack.Matches[i]
				if ok {
					fmt.Printf("\x1b[38;2;%d;%d;%dm%s\x1b[0m", q.Color.R, q.Color.G, q.Color.B, string(char))
				} else {
					fmt.Printf("%s", string(char))
				}
			}
			fmt.Println()
		}
	}

}

func getHaystack(query Query, line string) []int {
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

			ret := make([]int, len(query.Content))
			for i := 0; i < len(query.Content); i++ {
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

			ret := make([]int, len(query.Content))
			for i := range len(query.Content) {
				ret[i] = len(line) - len(query.Content) + i
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
					for q := idx; q < idx+len(query.Content); q++ {
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
		for i := range len(line) - len(query.Content) + 1 {
			if strings.HasPrefix(line[i:], query.Content) {
				for j := range len(query.Content) {
					ret = append(ret, i+j)
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
		Matches: map[int]Query{},
	}
	line = strings.ToLower(line)
	for _, group := range filters {
		didMatch := false
		for _, query := range group {
			idxs := getHaystack(query, line)
			if len(idxs) > 0 {
				didMatch = true
			}
			for _, idx := range idxs {
				ret.Matches[idx] = query
			}
		}
		if !didMatch {
			return nil
		}
	}
	return &ret
}

func parseToken(token string) Query {
	query := Query{
		Color: Color{
			R: rand.Intn(256),
			G: rand.Intn(256),
			B: rand.Intn(256),
		},
	}

PrefixToken:
	for len(token) > 0 {
		switch token[0] {
		case '!':
			query.Inverse = !query.Inverse
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
