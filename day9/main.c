#include <stdint.h>
#include <sys/types.h>

#include "aoc.h"

struct file_info {
    size_t start;
    size_t len;
};

/*
    Expand s[] into disk[], fill files[], return count of files.
*/
static size_t
expand_layout(const char *s, size_t len,
              int64_t *disk, size_t nblk,
              struct file_info *files, size_t max_files)
{
    size_t pos = 0;
    size_t fid = 0;

    for (size_t i = 0; i < len; i++) {
        int d = s[i] - '0';

        if ((i & 1u) == 0) {
            /* file run */
            files[fid].start = pos;
            files[fid].len   = (size_t)d;

            for (int k = 0; k < d; k++)
                disk[pos++] = (int64_t)fid;

            fid++;
        } else {
            /* free run */
            for (int k = 0; k < d; k++)
                disk[pos++] = -1;
        }
    }

    if (pos != nblk) {
        fprintf(stderr, "expand_layout internal error: pos=%zu nblk=%zu\n", pos, nblk);
        exit(1);
    }

    return fid;  /* file_count */
}

/*
    Part 1: block-level compaction
*/
static uint64_t
compute_part1(int64_t *disk, size_t nblk)
{
    size_t left  = 0;
    size_t right = (nblk ? nblk - 1 : 0);

    for (;;) {
        while (left < nblk && disk[left] != -1)
            left++;

        while (right > left && disk[right] == -1)
            right--;

        if (left >= right)
            break;

        disk[left]  = disk[right];
        disk[right] = -1;
    }

    uint64_t sum = 0;
    for (size_t i = 0; i < nblk; i++) {
        if (disk[i] >= 0)
            sum += (uint64_t)i * (uint64_t)disk[i];
    }
    return sum;
}

/*
    Part 2: whole-file movement
*/
static uint64_t
compute_part2(int64_t *disk,
              struct file_info *files,
              size_t file_count,
              size_t nblk)
{
    /* Move files in descending ID order */
    for (ssize_t id = (ssize_t)file_count - 1; id >= 0; id--) {
        size_t flen = files[id].len;
        size_t cur  = files[id].start;
        if (flen == 0) continue;

        size_t pos_free = 0;

        while (pos_free < cur) {
            /* find start of free run */
            while (pos_free < cur && disk[pos_free] != -1)
                pos_free++;
            if (pos_free >= cur)
                break;

            size_t free_start = pos_free;

            /* find end */
            while (pos_free < cur && disk[pos_free] == -1)
                pos_free++;

            size_t free_len = pos_free - free_start;

            if (free_len >= flen) {
                /* move whole file */
                for (size_t k = 0; k < flen; k++)
                    disk[free_start + k] = (int64_t)id;
                for (size_t k = 0; k < flen; k++)
                    disk[cur + k] = -1;

                files[id].start = free_start;
                break;
            }
        }
    }

    /* checksum */
    uint64_t sum = 0;
    for (size_t i = 0; i < nblk; i++) {
        if (disk[i] >= 0)
            sum += (uint64_t)i * (uint64_t)disk[i];
    }
    return sum;
}


int
main(void)
{
    struct aoc_buf b;

    if (!read_file("input.txt", NULL, &b)) {
        fprintf(stderr, "read failed\n");
        return 1;
    }

    chomp(b.p);
    char *s   = b.p;
    size_t len = strlen(s);

    if (len == 0) {
        fprintf(stderr, "empty input\n");
        free(b.p);
        return 1;
    }

    /* total blocks */
    size_t nblk = 0;
    for (size_t i = 0; i < len; i++) {
        int d = s[i] - '0';
        if (d < 0 || d > 9) {
            fprintf(stderr, "bad digit\n");
            free(b.p);
            return 1;
        }
        nblk += (size_t)d;
    }

    /* allocate disk + file table */
    int64_t *disk = malloc(nblk * sizeof *disk);
    int64_t *disk_copy = malloc(nblk * sizeof *disk);
    size_t   max_files = (len + 1u) / 2u;
    struct file_info *files = malloc(max_files * sizeof *files);
    struct file_info *files_copy = malloc(max_files * sizeof *files_copy);

    if (!disk || !disk_copy || !files || !files_copy) {
        fprintf(stderr, "oom\n");
        free(b.p);
        free(disk);
        free(disk_copy);
        free(files);
        free(files_copy);
        return 1;
    }

    /*
       Parse once, then copy for Part 1 and Part 2
    */
    size_t file_count =
        expand_layout(s, len, disk, nblk, files, max_files);

    memcpy(disk_copy, disk, nblk * sizeof *disk);
    memcpy(files_copy, files, file_count * sizeof *files);

    /* part 1 */
    uint64_t part1 = compute_part1(disk_copy, nblk);

    /* restore and run part 2 */
    memcpy(disk_copy, disk, nblk * sizeof *disk);
    memcpy(files_copy, files, file_count * sizeof *files);

    uint64_t part2 =
        compute_part2(disk_copy, files_copy, file_count, nblk);

    printf("Part 1: %llu\n", (unsigned long long)part1);
    printf("Part 2: %llu\n", (unsigned long long)part2);

    free(b.p);
    free(disk);
    free(disk_copy);
    free(files);
    free(files_copy);

    return 0;
}
