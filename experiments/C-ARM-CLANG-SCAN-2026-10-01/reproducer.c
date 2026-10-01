/* Minimal compiler diagnostic, not a replacement for the immutable benchmarks.
 * Released to the public domain, matching HdrHistogram_c's source dedication.
 */
typedef __INT64_TYPE__ i64;
typedef __UINT64_TYPE__ u64;

i64 scan(const i64* counts, int length, i64 target)
{
    int index = 0;
    i64 running = 0;
    const int limit = length - length % 4;
    for (; index < limit; index += 4)
    {
        u64 sum = 0;
        int j;
        for (j = 0; j < 4; j++)
            sum += (u64)counts[index + j];
        if (__builtin_expect((u64)running + sum >= (u64)target, 0))
        {
#if defined(PATCH) && defined(__aarch64__) && defined(__clang__)
#pragma clang loop unroll(disable)
#endif
            for (j = 0; j < 4; j++)
            {
                running += counts[index + j];
                if (running >= target)
                    return index + j;
            }
        }
        else
        {
            running += (i64)sum;
        }
    }
    for (; index < length; index++)
    {
        running += counts[index];
        if (running >= target)
            return index;
    }
    return -1;
}
