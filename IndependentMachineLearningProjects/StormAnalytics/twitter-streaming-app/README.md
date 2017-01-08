twitter-streaming-app
=====================

## Prerequisites
* [Apache Kafka](http://kafka.apache.org/) 0.8+
* [Apache Storm](http://storm.apache.org/) 0.10+
* [Apache Cassandra](http://cassandra.apache.org/) 2.2+
* make sure python is 2.7.11 to avoid cassandra and python conflict.
You can use the following repository to get the above infrastructure on docker containers: https://github.com/mserrate/CoreOS-BigData

### Create Kafka topic
```
$KAFKA_HOME/bin/kafka-topics.sh --create --topic twitter-raw-topic --partitions 3 --zookeeper $ZK --replication-factor 2
# Get the created topic
$KAFKA_HOME/bin/kafka-topics.sh --describe --topic twitter-raw-topic --zookeeper $ZK
```

### Create Cassandra keyspace and tables
```
echo "CREATE KEYSPACE stormtwitter WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };" | cqlsh 127.0.0.1
echo "CREATE TABLE IF NOT EXISTS stormtwitter.tweet_sentiment_analysis ( tweet_id bigint, created_at text, tweet text, sentiment double, hashtags set<text>, PRIMARY KEY (tweet_id) \
);" | cqlsh 127.0.0.1
echo "CREATE INDEX ON stormtwitter.tweet_sentiment_analysis (hashtags);" | cqlsh 127.0.0.1
echo "CREATE TABLE IF NOT EXISTS stormtwitter.top_hashtag_by_day ( date text, bucket_time timestamp, ranking map<text, bigint>, PRIMARY KEY (date, bucket_time), ) WITH CLUSTERING O\
RDER BY (bucket_time DESC);" | cqlsh 127.0.0.1
```

## Building the code
For both [twitter-kafka-producer](twitter-kafka-producer) and [twitter-storm-topology](twitter-storm-topology) execute
```
mvn clean package
```


## Running the solution
Configure the properties file [config.properties](conf/config.properties)
```
# Twitter conf
consumerKey=
consumerSecret=
accessToken=
accessTokenSecret=

# Kafka conf
kafka.broker.list=127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094
kafka.twitter.raw.topic=twitter-raw-topic

#ZooKeeper Host
zookeeper.host=127.0.0.1:2181

#Storm conf
#Location in ZK for the Kafka spout to store state.
kafka.zkRoot=/twitter_spout
kafka.consumer.group=storm

#Cassandra Host
cassandra.host=127.0.0.1
cassandra.keyspace=stormtwitter
```


### Run the twitter producer
```
java -jar twitter-kafka-producer-1.0-SNAPSHOT-jar-with-dependencies.jar conf/config.properties
```

### Submit the storm topology
```
storm jar twitter-storm-topology-1.0-SNAPSHOT-jar-with-dependencies.jar TwitterProcessorTopology conf/config.properties
```