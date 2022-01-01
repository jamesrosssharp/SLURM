TESTS := $(filter-out Makefile, $(wildcard *))

all: $(TESTS)

$(TESTS):
	@echo "Running test: $@"
	@make -C $@

.PHONY: all $(TESTS)

