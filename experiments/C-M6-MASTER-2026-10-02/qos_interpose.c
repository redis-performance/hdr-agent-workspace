/* Load before an unchanged benchmark executable to set its main-thread QoS.
 * This is a scheduler request, not a physical-core pin.
 * Released to the public domain. */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef BENCH_QOS_CLASS
#define BENCH_QOS_CLASS QOS_CLASS_USER_INTERACTIVE
#endif

__attribute__((constructor)) static void set_benchmark_qos(void)
{
    qos_class_t observed = QOS_CLASS_UNSPECIFIED;
    int relative_priority = -1;
    int set_rc = pthread_set_qos_class_self_np(BENCH_QOS_CLASS, 0);
    int get_rc = pthread_get_qos_class_np(pthread_self(), &observed, &relative_priority);
    fprintf(stderr, "benchmark_qos requested=%u observed=%u relative_priority=%d set_rc=%d get_rc=%d\n",
            (unsigned)BENCH_QOS_CLASS, (unsigned)observed, relative_priority, set_rc, get_rc);
    if (set_rc || get_rc || observed != BENCH_QOS_CLASS)
        exit(125);
}
