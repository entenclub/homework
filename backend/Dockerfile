FROM golang:1.16.2

COPY . /go/src/github.com/3nt3/homework

WORKDIR /go/src/github.com/3nt3/homework

RUN go build .

CMD ["/go/src/github.com/3nt3/homework/homework"]

EXPOSE 8005
