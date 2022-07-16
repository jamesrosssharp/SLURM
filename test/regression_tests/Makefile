TESTS := $(filter-out Makefile, $(wildcard *))

all: $(TESTS)
	@echo "-------------------"
	@echo "All tests passed.  "
	@echo "-------------------"

$(TESTS):
	@echo "Running test: $@"
	@make -C $@

.PHONY: all $(TESTS)

