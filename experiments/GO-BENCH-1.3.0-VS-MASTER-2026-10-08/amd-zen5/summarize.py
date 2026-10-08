import re,sys,statistics as st,collections,glob
d=collections.defaultdict(list)
for f in glob.glob(sys.argv[1]+"/raw/*.txt"):
    v=f.split("/")[-1].split("_")[1][0]
    for l in open(f):
        m=re.match(r"(Benchmark\S+?)(?:-\d+)?\s+\d+\s+([\d.]+) ns/op",l)
        if m: d[(m.group(1),v)].append(float(m.group(2)))
names=sorted({k[0] for k in d})
print("%-52s %12s %12s %9s  %s"%("benchmark","A ns/op","B ns/op","A/B","spread A | B (min-max/median)"))
for n in names:
    a,b=d.get((n,"A")),d.get((n,"B"))
    sp=lambda x:"%.1f%%"%(100*(max(x)-min(x))/st.median(x)) if x else "-"
    if a and b: print("%-52s %12.1f %12.1f %8.2fx  %s | %s"%(n,st.median(a),st.median(b),st.median(a)/st.median(b),sp(a),sp(b)))
    else: print("%-52s %12s %12s %9s"%(n,("%.1f"%st.median(a)) if a else "-",("%.1f"%st.median(b)) if b else "-","only "+("A" if a else "B")))
