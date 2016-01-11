
THREADING_OBJECTS = out/Threads.o out/Scheduler.o out/Signals.o out/Log.o

all: tests

tests: out/HelloWorld out/ProducerConsumer out/VBlankDrivenProducerConsumer

out/HelloWorld: out out/HelloWorld.o $(THREADING_OBJECTS)
	vlink out/HelloWorld.o $(THREADING_OBJECTS) -o $@

out/ProducerConsumer: out out/ProducerConsumer.o $(THREADING_OBJECTS)
	vlink out/ProducerConsumer.o $(THREADING_OBJECTS) -o $@

out/VBlankDrivenProducerConsumer: out out/VBlankDrivenProducerConsumer.o $(THREADING_OBJECTS)
	vlink out/VBlankDrivenProducerConsumer.o $(THREADING_OBJECTS) -o $@
	
out:
#	mkdir out
	md out

out/HelloWorld.o: Tests/HelloWorld.s
	vc -c Tests/HelloWorld.s -o $@

out/ProducerConsumer.o: Tests/ProducerConsumer.s
	vc -c Tests/ProducerConsumer.s -o $@

out/VBlankDrivenProducerConsumer.o: Tests/VBlankDrivenProducerConsumer.s
	vc -c Tests/VBlankDrivenProducerConsumer.s -o $@

out/Threads.o: Threading/Threads.s
	vc -c Threading/Threads.s -o $@

out/Scheduler.o: Threading/Scheduler.s
	vc -c Threading/Scheduler.s -o $@
	
out/Signals.o: Threading/Signals.s
	vc -c Threading/Signals.s -o $@
	
out/Log.o: Threading/Log.s
	vc -c Threading/Log.s -o $@

clean:
#	rm -rf out
	rd /s /q out
