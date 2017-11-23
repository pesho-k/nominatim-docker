FROM phusion/baseimage:0.9.19

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get clean && apt-get update && apt-get install -y locales

ENV LANG C.UTF-8
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN apt-get -y update --fix-missing && \
		apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev \
    libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev \
    postgresql-server-dev-9.5 postgresql-9.5-postgis-2.2 postgresql-contrib-9.5 \
    apache2 php php-pgsql libapache2-mod-php php-pear php-db \
    php-intl git

RUN apt-get -y install python-pip python-dev build-essential libboost-all-dev && \
    pip install --upgrade pip && \
    pip install --upgrade virtualenv

# RUN apt-get clean && \
#     rm -rf /var/lib/apt/lists/* && \
#     rm -rf /tmp/* /var/tmp/*

# Configure postgres
RUN echo "host all  all    0.0.0.0/0  trust" >> /etc/postgresql/9.5/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

RUN useradd -d /srv/nominatim -s /bin/bash -m nominatim

RUN su - nominatim -c "chmod a+x /srv/nominatim"

RUN su nominatim -c "pip install --user osmium"

RUN service postgresql start

#RUN su - postgres -c "createuser -s nominatim"
#RUN su - postgres -c "createuser -s www-data"

COPY Nominatim-3.0.1.tar.bz2 /srv/nominatim/
RUN cd /srv/nominatim && tar xf Nominatim-3.0.1.tar.bz2
RUN mkdir /srv/nominatim/Nominatim-3.0.1/build
RUN cd /srv/nominatim/Nominatim-3.0.1/build && \
    cmake /srv/nominatim/Nominatim-3.0.1 && \
    make

COPY local.php /srv/nominatim/Nominatim-3.0.1/build/settings/

COPY monaco-latest.osm.pbf /srv/nominatim/data.osm.pbf

RUN chown -R nominatim:nominatim /srv/nominatim

RUN service postgresql start && \
    su postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='nominatim'\" | grep -q 1 || createuser -s nominatim" && \
    su postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='www-data'\" | grep -q 1 || createuser -SDR www-data" && \
    su postgres -c "psql postgres -c \"DROP DATABASE IF EXISTS nominatim\"" && \
    su - nominatim -c "cd /srv/nominatim/Nominatim-3.0.1/build && ./utils/setup.php --osm-file /srv/nominatim/data.osm.pbf --all --threads 8" && \
    service postgresql stop

COPY nominatim.conf /etc/apache2/sites-enabled/000-default.conf

# Tune postgresql
COPY postgresql.conf.sed /tmp/
RUN sed --file /tmp/postgresql.conf.sed --in-place /etc/postgresql/9.5/main/postgresql.conf

EXPOSE 5432
EXPOSE 8080

COPY start.sh /srv/nominatim/start.sh
RUN chmod +x /srv/nominatim/start.sh
CMD /srv/nominatim/start.sh

# Clean up
RUN rm /srv/nominatim/data.osm.pbf
