#include <u.h>
#include <libc.h>
#include <bio.h>


typedef struct Input input;
struct input
{
  int *l;
  int *r;
  int lcount;
  int rcount;
};

int
slurp(input *data, char *filename)
{
  Biobuf *buf;
  char *line

  buf = Bopen(filename, OREAD)
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

    if (lvall || rval){
      fprintf(2, "oops line: %s:, line");
     }
     Bterm(buf);
     return -1;
    }

  data->[data->lcount++] = atoi(lval);
  data->[data->rcount++] = atoi(rval);
  }
  Bterm(buf);
  return 0;
}
