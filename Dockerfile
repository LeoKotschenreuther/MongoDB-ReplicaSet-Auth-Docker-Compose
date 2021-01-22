FROM mongo:3.2

COPY keyfile /var/lib/mongodb/keyfile
RUN chmod 400 /var/lib/mongodb/keyfile
RUN chown mongodb:mongodb /var/lib/mongodb/keyfile