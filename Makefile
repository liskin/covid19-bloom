STACK_EXEC = stack exec \
	--package bloomfilter \
	--package bytestring \
	--package cassava

covid19-bloom: covid19-bloom.hs
	$(STACK_EXEC) -- ghc --make $<

ghci: covid19-bloom.hs
	$(STACK_EXEC) -- ghci $<

ghcid: covid19-bloom.hs
	$(STACK_EXEC) -- ghcid $<
