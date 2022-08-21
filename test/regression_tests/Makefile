TESTS := $(filter-out Makefile, $(wildcard *))
TESTCLEAN=$(addsuffix clean,$(TESTS))

.PHONY: all 
all: $(TESTS)
	@echo "-------------------"
	@echo "All tests passed.  "
	@echo "-------------------"

.PHONY: $(TESTS)
$(TESTS):
	@echo "Running test: $@"
	@make -C $@


