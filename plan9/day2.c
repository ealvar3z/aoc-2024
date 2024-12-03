/* Plan9 C solution ported from my Go code  */

#include <u.h>
#include <libc.h>
#include <bio.h>

typedef struct {
	int **data;
	int rows;
	int *cols;
	int **orig_report;
	int orig_rows;
	char **damped_report;
	int damped_rows;
} Input;

void
die(char *err)
{
	fprint(2, "Error: %s\n", err);
	exits("error");
}

int
is_safe(int *row, int n)
{
	if (n <= 1)
		return 1;

	int inc = row[1] > row[0];
	int dec = row[1] < row[0];

	for (int j = 1; j < n; j++)  {
		int diff = row[j] - row[j - 1];

		// adjacency check
		if (diff < -3 || diff > 3)
			return 0;

		// monotonicity check
		if ((inc && diff < 0) || (dec && diff > 0))
			return 0;

		// equality check
		if (diff == 0)
			return 0;
	}
	
	return 1;
}


void
main(int argc, char *argv[])
{
	if (argc != 2)
		die("Usage: 9c XX.c or mk run INPUT=input.txt");

	char *fn = argv[1];
	Input data;

	slurp(&data, fn); //TODO
	analysis(&data); //TODO
	print_reports(&data); //TODO

	// free everything
	for (int i = 0; i < data.rows; i++)
		free(data.data[i]);
	free(data.data);
	free(data.cols);


	for (int i = 0; i < data.damped_rows; i++)
		free(data.damped_report[i]);
	free(data.damped_report);

	exits(0);
}
