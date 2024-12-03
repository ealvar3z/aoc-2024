%: %.go
	go build -o $stem $stem.go

run: $stem
	./$stem $INPUT

clean:
	rm -f day* *.out

