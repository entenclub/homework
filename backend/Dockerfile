FROM golang:1.16.2

# All these steps will be cached
RUN mkdir /hello
WORKDIR /hello
COPY go.mod .
COPY go.sum .

# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download
# COPY the source code as the last step
COPY . .

RUN go build .

CMD ["/hello/homework"]

EXPOSE 8005
