FROM golang:1.16-alpine
WORKDIR /app

RUN go mod init httpClient

COPY *.go ./

RUN go build -o /main 

EXPOSE 3000

CMD [ "/main" ]