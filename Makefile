.PHONY: lint
lint:
	zig fmt src/
	zlint --deny-warnings

.PHONY: release
release:
	zig build --release=fast
	mkdir -p release
	cd zig-out/bin; tar -czf ../../release/happy-fathers-day.tar.gz *
