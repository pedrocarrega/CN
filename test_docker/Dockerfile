FROM mongo:latest
WORKDIR /srv
COPY entrypoint.sh .
COPY smallerLargeFile_3.csv smallerLargeFile.csv
#RUN chmod 777 entrypoint.sh \
#    && ln -s entrypoint.sh /
#RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
#Possivel wait no script