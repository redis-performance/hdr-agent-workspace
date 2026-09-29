// Released to the public domain under CC0.
#include <hdr/hdr_packed_histogram.h>
int main()
{
    hdr_packed_histogram *h = nullptr;
    int result = hdr_packed_init(1, 1000, 3, &h);
    if (!result) hdr_packed_close(h);
    return result;
}
