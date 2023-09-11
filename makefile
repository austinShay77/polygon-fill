default:
	cp CG_hw3.py CG_hw3
	chmod +x CG_hw3

all:
	python3 ./CG_hw3.py > a.pbm
	python3 ./CG_hw3.py -a 0 -b 0 -c 500 -d 500 -j 0 -k 0 -o 500 -p 500 -s 1.0 -m 0 -n 0 -r 0 > b.pbm
	python3 ./CG_hw3.py -a 50 -b 0 -c 325 -d 500 -j 0 -k 110 -o 480 -p 410 -s 1 -m 0 -n 0 -r 0 > c.pbm
	python3 ./CG_hw3.py -a 10 -b 10 -c 550 -d 400 -j 10 -k 10 -o 500 -p 400 -s 1.2 -m 6 -n 25 -r 8 > d.pbm
	python3 ./CG_hw3.py -b 62 -c 500 -d 479 -r 75 -j 139 -o 404 -p 461 -s .85 -m 300 > e.pbm
	python3 ./CG_hw3.py -a 275 -b 81 -c 550 -d 502 -r -37 -j 123 -k 217 -o 373 -p 467 > f.pbm
	python3 ./CG_hw3.py -d 301 -c 435 -b 170 -a -100 -r -23 > g.pbm
	python3 ./CG_hw3.py -a -135 -b -53 -c 633 -d 842 -m -23 -j 101 -p 415 -s 3.6 > h.pbm
	
	
