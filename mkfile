GO=go
SOURCES=`{ls day*.go}
BINARIES=`{echo $SOURCES | sed 's/\.go//g'}

all: $BINARIES

build_%: %.go
	$GO build -o $target $prereq
	
clean:
	rm -f $BINARIES

run_input_%: build_%
	./$prereq input.txt

run_sample_%: build_%
	./$prereq sample.txt
