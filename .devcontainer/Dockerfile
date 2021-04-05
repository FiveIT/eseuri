FROM cypress/base:14.16.0

SHELL ["/bin/bash", "-c"]

RUN apt-get update -y && apt-get install wget curl make -y && apt-get upgrade -y

RUN touch /root/.bashrc

# Install Go and required tooling
ARG GO_VERSION=1.16.2
ENV GO_FILENAME=go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH /usr/local/go/bin:$PATH
RUN wget https://golang.org/dl/${GO_FILENAME} \
  && tar -C /usr/local -xzf ${GO_FILENAME} \
  && rm -rf ${GO_FILENAME}
RUN go get golang.org/x/tools/gopls@latest
RUN go install github.com/go-delve/delve/cmd/dlv@latest
RUN go get github.com/uudashr/gopkgs/cmd/gopkgs@v2
RUN go get github.com/ramya-rao-a/go-outline
RUN go get github.com/fatih/gomodifytags
RUN go get github.com/josharian/impl
RUN go get github.com/cweill/gotests/...
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.37.1
RUN go get -u github.com/cosmtrek/air
RUN go get golang.org/x/tools/cmd/goimports
RUN echo 'export PATH=/root/go/bin:$PATH'
ENV PATH /root/go/bin:${PATH}

# Install NVM, Node, and pnpm 
ARG NODE_VERSION=15.13.0
ENV NVM_DIR /root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash \
  && . ${NVM_DIR}/nvm.sh \
  && nvm install ${NODE_VERSION} \
  && npm i -g npm \
  && npm i -g pnpm \
  && echo 'export PATH=/root/.nvm/versions/node/v${NODE_VERSION}/bin:$PATH' > /root/.bashrc
ENV PATH /root/.nvm/versions/node/v${NODE_VERSION}/bin:$PATH

WORKDIR /workspace
