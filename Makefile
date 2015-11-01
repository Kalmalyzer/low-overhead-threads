
THREADING_OBJECTS = out/Threads.o out/Scheduler.o

all: tests

tests: out/HelloWorld

out/HelloWorld: out out/HelloWorld.o $(THREADING_OBJECTS)
	vlink out/HelloWorld.o out/Threads.o out/Scheduler.o -o $@
out:
#	mkdir out
	md out

out/HelloWorld.o: Tests/HelloWorld.s
	vc -c Tests/HelloWorld.s -o $@

out/Threads.o: Threading/Threads.s
	vc -c Threading/Threads.s -o $@

out/Scheduler.o: Threading/Scheduler.s
	vc -c Threading/Scheduler.s -o $@
	
clean:
#	rm -rf out
	rd /s /q out
