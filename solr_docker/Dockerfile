FROM solr:6.3

RUN my_solr solr create_core -c gettingstarted

COPY schema.xml /opt/solr/configsets/sunspot/conf/schema.xml
