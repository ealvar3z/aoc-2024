#include <u.h>
#include <libc.h>
#include <bio.h>


typedef struct {
  int *l;
  int *r;
  int lcount;
  int rcount;
} Input;

int
slurp(Input *data, char *filename)
{
  Biobuf *buf;
  char *line;

  buf = Bopen(filename, OREAD);
  if (buf == nil){
    fprint(2, "oops: %s\n", filename);  
    return -1;
  }
  data->l = nil;
  data->r = nil;
  data->lcount = 0;
  data->rcount = 0;

  while ((line = Brdline(buf, '\n')) != nil){
    char *lval, *rval;
    line[Blinelen(buf) - 1] = '\0'; // trailing newline
    lval = strtok(line, " ");
    rval = strtok(nil, " ");

    if (!lval || !rval){
      fprint(2, "oops line: %s:, line");
      free(data->l);
      free(data->r);
      Bterm(buf);
      return -1;
     }

    int *new_l = realloc(data->l, (data->lcount + 1) * sizeof(int));
    int *new_r = realloc(data->r, (data->rcount + 1) * sizeof(int));

    if (!new_l || !new_r) {
    	fprint(2, "realloc failed\n");
    	free(data->l);
    	free(data->r);
    	Bterm(buf);
    	return -1;
    }

    data->l = new_l;
    data->r = new_r;

	  data->l[data->lcount++] = atoi(lval);
	  data->r[data->rcount++] = atoi(rval);
  }
  Bterm(buf);
  return 0;
}

void
sort(int *arr, int count) {
	for (int i = 0; i < count - 1; i++) {
		for (int j = 0; j < count - i - 1; j++) {
			if (arr[j] > arr[j + 1]) {
				int temp = arr[j];
				arr[j] = arr[j + 1];
				arr[j+1] = temp;
			}
		}
	}
}

int
calc_dist(Input *data) {
	sort(data->l, data->lcount);
	sort(data->r, data->rcount);

	int diff = 0;
	for (int i = 0; i < data->lcount; i++) {
		diff += abs(data->l[i] - data->r[i]);
	}
	return diff;
}

int
sim_score(Input *data) {
	int score = 0;
	int max_r = 0;
		
	for (int i = 0; i < data->rcount; i++) {
			if (data->r[i] > max_r) max_r = data->r[i];
	}

	
	int *counts = calloc(max_r + 1, sizeof(int));
	if (!counts) {
			fprint(2, "calloc failed\n");
			return -1;
	}

	for (int i = 0; i < data->rcount; i++) {
		counts[data->r[i]]++;
	}

	for (int i = 0; i < data->lcount; i++) {
		if (data->l[i] <= max_r)
				score += data->l[i] * counts[data->l[i]];
	}

	free(counts);
	return score;
}

void
main() {
	Input data;

	if (slurp(&data, "input.txt") < 0) {
		fprint(2, "File Not Found\n");
		exits("error");
	}

	int dist = calc_dist(&data);
	int sim = sim_score(&data);

	if (sim < 0) {
		fprint(2, "sim score failed\n");
		free(data.l);
		free(data.r);
		exits("error");
	}

	print("Part I: \t%d\n", dist);
	print("Part II:\t%d\n", sim);

	free(data.l);
	free(data.r);

	exits(0);
}
