set -u
cd "/home/ubuntu/hdrfuzz/bench-20261008T061309Z"; export PATH=/home/ubuntu/hdrfuzz/gotool/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin GOTOOLCHAIN=local
idle(){ for i in $(seq 1 120); do
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 3; read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  t=$(( (u2+n2+s2+i2+w2+q2+sq2)-(u1+n1+s1+i1+w1+q1+sq1) )); idl=$(( (i2+w2)-(i1+w1) ))
  [ $(( (t-idl)*100 )) -le $(( t*8 )) ] && return 0; sleep 5; done; return 1; }
n=0
for r in A B B A A B B A; do n=$((n+1))
  idle || { echo "not idle, abort before $n$r" >> notes; exit 1; }
  taskset -c 2 env GOMAXPROCS=1 ./bin/$r.test -test.run='^$' -test.bench=. -test.benchmem -test.count=5 -test.timeout=40m > raw/${n}_${r}.txt 2>&1
  echo "$n $r exit $?" >> notes
done
python3 summarize.py "/home/ubuntu/hdrfuzz/bench-20261008T061309Z" > summary.txt; touch DONE
