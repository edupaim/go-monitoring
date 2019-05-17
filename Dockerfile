FROM ubuntu:bionic
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install tzdata
ENV TZ=America/Bahia
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
WORKDIR /app
COPY ./bin/monitoring /app/
ENTRYPOINT ["/app/monitoring"]