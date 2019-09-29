FROM alpine:latest

COPY ci /home
EXPOSE 12224 12225
WORKDIR /home

CMD ["ping 1.1.1.1"]
