package bolts;

import backtype.storm.topology.BasicOutputCollector;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.base.BaseBasicBolt;
import backtype.storm.tuple.Fields;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Values;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * Bolt implementation to fix count of hashtag occurences.
 */
public class HashtagCounterBolt extends BaseBasicBolt {
    private static final Logger LOG = LoggerFactory.getLogger(HashtagCounterBolt.class);
    //map holding frequency of occurence of each hashtag.
    private Map<String, Long> hashtag_count = new HashMap<String, Long>();

    @Override
    public void execute(Tuple tuple, BasicOutputCollector collector) {
        String hashtag = tuple.getStringByField("tweet_hashtag");
        Long count = hashtag_count.get(hashtag);

        if (count == null)
            count = 0L;

        count++;
        hashtag_count.put(hashtag, count);

        collector.emit(new Values(hashtag, count));
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("hashtag", "count"));
    }
}
