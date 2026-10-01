#include <mach/mach.h>
#include <mach/mach_host.h>
#include <mach/processor_info.h>
#include <sys/wait.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

struct snapshot { natural_t n; processor_info_array_t info; mach_msg_type_number_t count; };

static struct snapshot read_load(void) {
    struct snapshot s = {0};
    kern_return_t rc = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                            &s.n, &s.info, &s.count);
    if (rc != KERN_SUCCESS) { fprintf(stderr, "host_processor_info failed: %d\n", rc); exit(2); }
    return s;
}

static void release(struct snapshot s) {
    vm_deallocate(mach_task_self(), (vm_address_t)s.info, s.count * sizeof(integer_t));
}

int main(int argc, char **argv) {
    if (argc < 2) return 2;
    struct snapshot before = read_load();
    pid_t pid = fork();
    if (pid < 0) return 2;
    if (pid == 0) { execvp(argv[1], argv + 1); _exit(127); }
    int status = 0;
    if (waitpid(pid, &status, 0) != pid) return 2;
    struct snapshot after = read_load();
    if (before.n != after.n) return 2;
    uint32_t best = 0;
    unsigned best_busy = 0;
    printf("probe_busy_ticks=[");
    for (natural_t i = 0; i < before.n; i++) {
        processor_cpu_load_info_t a = (processor_cpu_load_info_t)before.info + i;
        processor_cpu_load_info_t b = (processor_cpu_load_info_t)after.info + i;
        unsigned busy = (unsigned)(b->cpu_ticks[CPU_STATE_USER] - a->cpu_ticks[CPU_STATE_USER]) +
                        (unsigned)(b->cpu_ticks[CPU_STATE_SYSTEM] - a->cpu_ticks[CPU_STATE_SYSTEM]) +
                        (unsigned)(b->cpu_ticks[CPU_STATE_NICE] - a->cpu_ticks[CPU_STATE_NICE]);
        printf("%s%u", i ? "," : "", busy);
        if (busy > best_busy) { best_busy = busy; best = i; }
    }
    printf("] probe_top_cpu=%u probe_busy_ticks=%u probe_cpu_count=%u\n", best, best_busy, before.n);
    release(before); release(after);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 2;
}
