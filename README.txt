Advent of Code 2024
-------------------

Advent of Code solutions:

	- Go
	- Plan9 C
	- Plan9 rc

Usage:
------
To build all solutions:
    mk all

To build a specific day (e.g., day1.go):
    mk build_day1

To run a specific day with input.txt:
    mk run_input_day1

To run a specific day with sample.txt:
    mk run_sample_day1

To clean up all built binaries:
    mk clean

Input Files:
------------
Ensure that your input files (e.g., input.txt, sample.txt) are in the same directory as the code.

Dependencies:
-------------
This project requires Plan 9 tools for the `mk` build system:  

	-  `plan9port` or `9base`.
