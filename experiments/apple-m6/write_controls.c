/* Controllable supplemental write cases; immutable referees are not modified.
 * Released to the public domain. Validation/description never read a clock. */
#define main shared_bench_main
#include "bench.c"
#undef main
#define main shared_write_validation_main
#include "write_validate.c"
#undef main
#include <errno.h>

enum { INPUTS = 4096, CASES = 33, MAX_UNITS = 262144 };
#ifdef __APPLE__
#ifndef HDR_M6_QOS_CLASS
#define HDR_M6_QOS_CLASS QOS_CLASS_USER_INITIATED
#endif
#endif
static const uint64_t referee_sweep = UINT64_C(399999999);
static const char* shapes[] = {"increasing", "constant", "iid", "correlated", "extremes",
    "offset_pos", "offset_neg", "offset_wrap_pos", "offset_wrap_neg", "offset_mixed",
    "reject_negative", "reject_above", "mixed_validity", "coarse_sig1", "coarse_sig2", "coarse_sig5"};

struct fixture
{
    struct hdr_histogram* h[2];
    int64_t* expected[2];
    int64_t input[INPUTS];
    unsigned char select[INPUTS];
    int64_t total[2], min[2], max[2];
    int atomic, histograms, reference;
    uint64_t input_hash, quantum;
    char name[80];
};

static void case_name(int id, char* name, size_t length)
{
    if (id == 0) snprintf(name, length, "referee_steady_sweep");
    else snprintf(name, length, "%s_%s", (id - 1) % 2 ? "atomic" : "write", shapes[(id - 1) / 2]);
}

static uint64_t hash_word(uint64_t hash, uint64_t word)
{
    /* Stable little-endian FNV-1a fingerprint; not a cryptographic digest. */
    for (unsigned byte = 0; byte < 8; byte++)
    { hash ^= (word >> (byte * 8U)) & 255U; hash *= UINT64_C(1099511628211); }
    return hash;
}

static uint32_t random_word(uint32_t* rng)
{
    *rng ^= *rng << 13U; *rng ^= *rng >> 17U; *rng ^= *rng << 5U;
    return *rng;
}

static void setup(struct fixture* f, int id, uint32_t seed)
{
    memset(f, 0, sizeof(*f));
    f->reference = id == 0;
    f->atomic = id == 0 ? 0 : (id - 1) % 2;
    int shape = id == 0 ? 0 : (id - 1) / 2;
    int sig = f->reference ? 4 : shape == 13 ? 1 : shape == 14 ? 2 : shape == 15 ? 5 : 3;
    int64_t low = shape == 13 ? 16 : shape >= 14 ? 1024 : 1;
    int64_t high = f->reference ? INT64_C(86400000000) : INT64_C(1000000000);
    f->histograms = shape == 9 ? 2 : 1;
    f->quantum = f->reference ? referee_sweep : INPUTS;
    case_name(id, f->name, sizeof(f->name));
    for (int j = 0; j < f->histograms; j++)
    {
        require(hdr_init(low, high, sig, &f->h[j]) == 0, "control init");
        struct hdr_histogram* h = f->h[j];
        h->normalizing_index_offset = shape == 5 || shape == 13 ? 1 :
            shape == 6 || shape == 14 ? -1 : shape == 7 || shape == 15 ? h->counts_len - 1 :
            shape == 8 ? 1 - h->counts_len : shape == 9 && j == 1 ? 1 : 0;
        f->expected[j] = calloc((size_t)h->counts_len, sizeof(int64_t));
        require(f->expected[j] != NULL, "control oracle allocation");
        f->min[j] = INT64_MAX;
    }
    uint64_t fingerprint = UINT64_C(14695981039346656037);
    fingerprint = hash_word(fingerprint, (uint64_t)id);
    fingerprint = hash_word(fingerprint, seed);
    if (f->reference)
    {
        /* Analytically seed exactly one prior complete sweep, reproducing the
           steady-state extrema/counts without an unrecorded 400M-call warmup. */
        struct hdr_histogram* h = f->h[0];
        for (int idx = 0; idx < h->counts_len; idx++)
        {
            int64_t begin = hdr_value_at_index(h, idx);
            int64_t end = hdr_next_non_equivalent_value(h, begin) - 1;
            if (begin < 1) begin = 1;
            if (end > (int64_t)referee_sweep) end = (int64_t)referee_sweep;
            h->counts[idx] = end >= begin ? end - begin + 1 : 0;
        }
        h->total_count = (int64_t)referee_sweep;
        h->min_value = 1; h->max_value = (int64_t)referee_sweep;
        fingerprint = hash_word(fingerprint, referee_sweep);
    }
    else
    {
        uint32_t rng = seed;
        int64_t current = 100000;
        for (int i = 0; i < INPUTS; i++)
        {
            uint32_t r = random_word(&rng);
            current += (int64_t)(r % 201) - 100;
            if (current < 1) current = 1;
            int64_t value = shape == 0 ? i + 1 : shape == 1 ? 100000 :
                shape == 2 ? r % (uint64_t)high + 1 : shape == 4 ? (i & 1 ? high : 1) : current;
            if (shape == 10) value = i & 1 ? INT64_MIN : -1;
            if (shape == 11) value = i & 1 ? INT64_MAX : high + 1;
            if (shape == 12) value = i % 4 == 0 ? -1 : i % 4 == 1 ? high + 1 : value;
            int which = f->histograms == 2 ? i & 1 : 0;
            f->input[i] = value; f->select[i] = (unsigned char)which;
            fingerprint = hash_word(hash_word(fingerprint, (uint64_t)value), (uint64_t)which);
            if (value < 0 || value > high) continue;
            f->expected[which][index_for(f->h[which], value)]++;
            f->total[which]++;
            if (value && value < f->min[which]) f->min[which] = value;
            if (value > f->max[which]) f->max[which] = value;
        }
    }
    f->input_hash = fingerprint;
}

static void destroy(struct fixture* f)
{
    for (int j = 0; j < f->histograms; j++) { free(f->expected[j]); hdr_close(f->h[j]); }
}

static void describe(const struct fixture* f)
{
    printf("{\"case\":\"%s\",\"quantum\":%"PRIu64",\"max_units\":%u,"
        "\"input_fnv1a64\":\"%016"PRIx64"\",\"histograms\":%d,\"sigfigs\":%d,"
        "\"lowest\":%"PRId64",\"highest\":%"PRId64",\"offsets\":[%d,%d],"
        "\"kind\":\"%s\"}\n", f->name, f->quantum, f->reference ? 1U : MAX_UNITS,
        f->input_hash, f->histograms, f->h[0]->significant_figures,
        f->h[0]->lowest_discernible_value, f->h[0]->highest_trackable_value,
        f->h[0]->normalizing_index_offset, f->histograms == 2 ? f->h[1]->normalizing_index_offset : 0,
        f->reference ? "full-sweep-finalist-only" : "supplemental-control");
}

static void execute(struct fixture* f, uint64_t units, int validation)
{
    double start = validation ? 0 : now();
    if (f->reference)
    {
        /* Monomorphic direct API calls and generated increasing values, as in
           the referee. Validation uses a small prefix, never the full sweep. */
        int64_t last = validation ? INPUTS : (int64_t)referee_sweep;
        for (int64_t value = 1; value <= last; value++) hdr_record_value(f->h[0], value);
    }
    else if (f->atomic)
        for (uint64_t rep = 0; rep < units; rep++)
            for (int i = 0; i < INPUTS; i++) hdr_record_value_atomic(f->h[f->select[i]], f->input[i]);
    else
        for (uint64_t rep = 0; rep < units; rep++)
            for (int i = 0; i < INPUTS; i++) hdr_record_value(f->h[f->select[i]], f->input[i]);
    double seconds = validation ? 0 : now() - start;
#ifdef WRITE_CONTROLS_FAULT
    /* Test-only negative control for the post-loop exact-bin oracle. */
    if (validation) f->h[0]->counts[0]++;
#endif
    uint64_t checksum = UINT64_C(14695981039346656037);
    for (int j = 0; j < f->histograms; j++)
    {
        struct hdr_histogram* h = f->h[j];
        if (f->reference)
        {
            int64_t extra = validation ? INPUTS : (int64_t)referee_sweep;
            int64_t total = 0;
            for (int idx = 0; idx < h->counts_len; idx++)
            {
                int64_t begin = hdr_value_at_index(h, idx);
                int64_t end = hdr_next_non_equivalent_value(h, begin) - 1;
                if (begin < 1) begin = 1;
                int64_t initial_end = end < (int64_t)referee_sweep ? end : (int64_t)referee_sweep;
                int64_t extra_end = end < extra ? end : extra;
                int64_t expected = (initial_end >= begin ? initial_end - begin + 1 : 0) +
                    (extra_end >= begin ? extra_end - begin + 1 : 0);
                require(h->counts[idx] == expected, "steady sweep bin oracle");
                total += h->counts[idx];
            }
            require(total == (int64_t)referee_sweep + extra && h->total_count == total, "steady sweep total");
            require(h->min_value == 1 && h->max_value == (int64_t)referee_sweep, "steady sweep extrema");
        }
        else
        {
            for (int idx = 0; idx < h->counts_len; idx++) f->expected[j][idx] *= (int64_t)units;
            rotate(f->expected[j], h->counts_len, h->normalizing_index_offset);
            require(memcmp(h->counts, f->expected[j], (size_t)h->counts_len * sizeof(int64_t)) == 0,
                "write control physical bins");
            require(h->total_count == f->total[j] * (int64_t)units &&
                h->min_value == f->min[j] && h->max_value == f->max[j], "write control metadata");
        }
        for (int idx = 0; idx < h->counts_len; idx++) checksum = hash_word(checksum, (uint64_t)h->counts[idx]);
        checksum = hash_word(hash_word(hash_word(checksum, (uint64_t)h->total_count),
            (uint64_t)h->min_value), (uint64_t)h->max_value);
    }
    if (!validation)
    {
        require(seconds > 0, "unresolved clock");
        uint64_t ops = units * f->quantum;
        printf("{\"case\":\"%s\",\"ops\":%"PRIu64",\"seconds\":%.9f,"
            "\"ns_per_op\":%.9f,\"checksum\":%"PRIu64",\"input_fnv1a64\":\"%016"PRIx64"\"}\n",
            f->name, ops, seconds, seconds * 1e9 / (double)ops, checksum, f->input_hash);
    }
}

static uint64_t number(const char* text)
{
    char* end; errno = 0;
    require(*text >= '0' && *text <= '9', "unsigned numeric argument");
    unsigned long long value = strtoull(text, &end, 0);
    require(!errno && *end == '\0', "numeric argument");
    return (uint64_t)value;
}

int main(int argc, char** argv)
{
    require(argc >= 2, "usage: write-controls validate | describe SEED | run CASE UNITS SEED");
    int validation = !strcmp(argv[1], "validate");
    int listing = !strcmp(argv[1], "describe");
    require(validation ? argc == 2 : listing ? argc == 3 : argc == 5 && !strcmp(argv[1], "run"), "arguments");
    uint64_t raw_seed = validation ? UINT64_C(0x6a09e667) : number(argv[listing ? 2 : 4]);
    require(raw_seed > 0 && raw_seed <= UINT32_MAX, "nonzero 32-bit seed");
    uint64_t units = validation || listing ? 2 : number(argv[3]);
    require(units > 0 && units <= MAX_UNITS, "unit cap");
#ifdef __APPLE__
    if (!validation && !listing)
        require(!pthread_set_qos_class_self_np(HDR_M6_QOS_CLASS, 0), "set QoS");
#endif
    int matched = 0;
    for (int id = 0; id < CASES; id++)
    {
        char name[80];
        case_name(id, name, sizeof(name));
        if (!validation && !listing && strcmp(name, argv[2])) continue;
        struct fixture f;
        setup(&f, id, (uint32_t)raw_seed);
        if (validation)
        {
            if (!f.reference)
            {
                for (int i = 0; i < INPUTS; i++)
                {
                    struct hdr_histogram* h = f.h[f.select[i]];
                    int expected = f.input[i] >= 0 && f.input[i] <= h->highest_trackable_value;
                    int actual = f.atomic ? hdr_record_value_atomic(h, f.input[i]) : hdr_record_value(h, f.input[i]);
                    require(actual == expected, "control return value");
                }
                for (int j = 0; j < f.histograms; j++) hdr_reset(f.h[j]);
            }
            execute(&f, f.reference ? 1 : units, 1); matched++;
        }
        else if (listing) { describe(&f); matched++; }
        else if (!strcmp(f.name, argv[2]))
        {
            require(!f.reference || units == 1, "full referee companion is one sweep only");
            execute(&f, units, 0); matched++;
        }
        destroy(&f);
    }
    require(matched > 0, "unknown case");
    if (validation) printf("{\"write_control_cases\":%d,\"timing\":false,\"referee_prefix_only\":true}\n", matched);
    return 0;
}
