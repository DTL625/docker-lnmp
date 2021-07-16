ARG MYSQL_VERSION
FROM ${MYSQL_VERSION}

ARG TZ

# set timezome
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone