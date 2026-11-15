.PHONY: all test host-test setup clean

all:
	./tools/build.sh

test:
	./tools/build.sh --tests
	./tools/test-vm.sh

host-test:
	prove -v t/04-host.t

setup:
	./tools/ci-setup.sh

clean:
	rm -f build/*.prg build/*.d64 build/*.asm build/*.vice-mon-list build/expected.p8
	rm -rf build/test-results
