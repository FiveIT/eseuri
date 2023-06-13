.PHONY: \
	build-server build-client build \
	build-dev dev-server dev-client dev \
	test-client test-server test

go_module=github.com/FiveIT/eseuri
functions_base_path=/.netlify/functions/index

build-server:
	go build \
	-ldflags "\
	-X $(go_module)/server/meta.context=${CONTEXT} \
	-X $(go_module)/server/meta.url=${URL} \
	-X $(go_module)/server/meta.netlify=${NETLIFY} \
	-X $(go_module)/server/meta.FunctionsBasePath=$(functions_base_path) \
	" \
	-o .$(functions_base_path) ./cmd/index

build-client:
	cd web && npm run prebuild && npm run build

build: build-server build-client

build-dev:
	go build -o ./tmp/index ./cmd/index

dev-client:
	cd web && pnpm run dev

dev-server:
	air -c .air.toml

dev: dev-server dev-client

test-client:
	cd web && pnpm t

test-server:
	go test -v ./...

test: test-client test-server

cypress:
	pnpm cy:open
	
cypress-run:
	pnpm cy:run	

e2e: dev cypress

e2e-run: dev cypress-run
