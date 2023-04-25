FROM flyway/flyway

COPY ./sql /flyway/sql/
# COPY ./flyway.conf /flyway/conf/

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "/flyway/flyway -url=$DATABASE_URL/$DATABASE_NAME -user=$POSTGRES_USER -password=$POSTGRES_PASSWORD -connectRetries=60 migrate"]
# CMD ["-c", "/flyway/flyway -url=jdbc:postgresql://langdb:5432/$$LANGCHAT_DB -user=$$POSTGRES_USER -password=$$POSTGRES_PASSWORD -connectRetries=60 migrate"]