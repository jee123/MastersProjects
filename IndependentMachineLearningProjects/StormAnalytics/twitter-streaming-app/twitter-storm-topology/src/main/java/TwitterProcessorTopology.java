import backtype.storm.Config;
import backtype.storm.StormSubmitter;
import backtype.storm.spout.SchemeAsMultiScheme;
import backtype.storm.topology.TopologyBuilder;
import backtype.storm.tuple.Fields;
import bolts.*;
import storm.kafka.*;
import storm.kafka.bolt.KafkaBolt;

import java.util.Properties;

/**
 * Topology defining the spout and bolts in use.
 */
public class TwitterProcessorTopology extends BaseTopology {

    public TwitterProcessorTopology(String configFileLocation) throws Exception {
        super(configFileLocation);
    }

    private void configureKafkaSpout(TopologyBuilder topology) {
        BrokerHosts hosts = new ZkHosts(topologyConfig.getProperty("zookeeper.host"));

        SpoutConfig spoutConfig = new SpoutConfig(
                hosts,
                topologyConfig.getProperty("kafka.twitter.raw.topic"),
                topologyConfig.getProperty("kafka.zkRoot"),
                topologyConfig.getProperty("kafka.consumer.group"));
        spoutConfig.scheme= new SchemeAsMultiScheme(new StringScheme());

        KafkaSpout kafkaSpout= new KafkaSpout(spoutConfig);
        topology.setSpout("twitterSpout", kafkaSpout);
    }

    private void configureBolts(TopologyBuilder topology) {
        
        // bolt to filter out all non-english tweets.
        topology.setBolt("twitterFilter", new TwitterFilterBolt(), 2)
                .shuffleGrouping("twitterSpout");

        // bolt to carry out the text normalization inorder to be processed properly by the sentiment analysis algo.
        topology.setBolt("textSanitization", new TextSanitizationBolt(), 4)
                .shuffleGrouping("twitterFilter");

        // bolt analysing the tweet text word by word and classifying its value between -1 and 1.
        topology.setBolt("sentimentAnalysis", new SentimentAnalysisBolt(), 4)
                .shuffleGrouping("textSanitization");

        // bolt to store tweets and their sentiment score in cassandra. 
        topology.setBolt("sentimentAnalysisToCassandra", new SentimentAnalysisToCassandraBolt(topologyConfig), 4)
                .shuffleGrouping("sentimentAnalysis");

        // bolt to split different hashtags appearing in tweet.
        topology.setBolt("hashtagSplitter", new HashtagSplitterBolt(), 4)
                .shuffleGrouping("textSanitization");

        // bolt to count hashtag occurences.
        topology.setBolt("hashtagCounter", new HashtagCounterBolt(), 4)
                .fieldsGrouping("hashtagSplitter", new Fields("tweet_hashtag"));
        
        // bolt to rank top 20 hashtags.
        topology.setBolt("topHashtag", new TopHashtagBolt())
                .globalGrouping("hashtagCounter");

        // bolt to store top 20 hashtags in Cassandra.
        topology.setBolt("topHashtagToCassandra", new TopHashtagToCassandraBolt(topologyConfig), 4)
                .shuffleGrouping("topHashtag");

    }

    private void buildAndSubmit() throws Exception {
        TopologyBuilder builder = new TopologyBuilder();
        configureKafkaSpout(builder);
        configureBolts(builder);

        Config config = new Config();

        //set producer properties
        Properties props = new Properties();
        props.put("metadata.broker.list", topologyConfig.getProperty("kafka.broker.list"));
        props.put("request.required.acks", "1");
        props.put("serializer.class", "kafka.serializer.StringEncoder");
        config.put(KafkaBolt.KAFKA_BROKER_PROPERTIES, props);

        StormSubmitter.submitTopology("twitter-processor", config, builder.createTopology());
    }

    public static void main(String[] args) throws Exception {
        String configFileLocation = args[0];

        TwitterProcessorTopology topology = new TwitterProcessorTopology(configFileLocation);
        topology.buildAndSubmit();
    }
}
