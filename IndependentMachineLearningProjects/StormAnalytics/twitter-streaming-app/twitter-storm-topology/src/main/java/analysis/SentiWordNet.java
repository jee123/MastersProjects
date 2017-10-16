package analysis;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Map;

public class SentiWordNet {
    private static volatile SentiWordNet instance;

    private Map<String, Double> dictionary;

    public static SentiWordNet getInstance() throws IOException {
        if (instance == null) {
            synchronized(SentiWordNet.class) {
                if (instance == null) {
                    instance = new SentiWordNet();
                }
            }
        }
        return instance;
    }

    private SentiWordNet() throws IOException {
        this("SentiWord.txt");
    }

    private SentiWordNet(String resourceName) throws IOException {
        // This is our main dictionary representation
        dictionary = new HashMap<String, Double>();

        // tempDictionary with key as String and value as a map.
        HashMap<String, HashMap<Integer, Double>> tempDictionary = new
                HashMap<String, HashMap<Integer, Double>>();

        BufferedReader csv = null;
        try {
            csv = new BufferedReader(new InputStreamReader(
                    ClassLoader.getSystemResourceAsStream(resourceName)));
            int lineNumber = 0;

            String line;
            while ((line = csv.readLine()) != null) {
                lineNumber++;

                // If it's a comment, skip this line.
                if (!line.trim().startsWith("#")) {
                    // We use tab separation
                    String[] data = line.split("\t");
                    //wordTypeMarker would be like a or n where a -> adjective and n -> noun.
                    String wordTypeMarker = data[0];

                    // Example line:
                    // POS ID PosS NegS SynsetTerm#sensenumber Desc
                    // a 00009618 0.5 0.25 spartan#4 austere#3 ascetical#2

                    if (data.length != 6) {
                        throw new IllegalArgumentException(
                                "Incorrect tabulation format in file, line: "
                                        + lineNumber);
                    }

                    // Calculate synset score as score = PosS - NegS
                    //synsetScore used as value in map later.
                    Double synsetScore = Double.parseDouble(data[2])
                            - Double.parseDouble(data[3]);

                    // Get all Synset terms
                    String[] synTermsSplit = data[4].split(" ");

                    // Go through all terms of current synset.
                    for (String synTermSplit : synTermsSplit) {
                        String[] synTermAndRank = synTermSplit.split("#");
                        //example of synTerm would be ascetic#a or good#a
                        String synTerm = synTermAndRank[0] + "#"
                                + wordTypeMarker;

                        //synTermRank used as key in map later.
                        int synTermRank = Integer.parseInt(synTermAndRank[1]);
                        // What we get here is a map of the type:
                        // term -> {score of synset#1, score of synset#2...}

                        // Add map to term if it doesn't have one
                        if (!tempDictionary.containsKey(synTerm)) {
                            tempDictionary.put(synTerm,
                                    new HashMap<Integer, Double>());
                        }

                        // Get the map corresponding to synTerm key and
                        // put synTermRank as key and synsetScore as value.
                        tempDictionary.get(synTerm).put(synTermRank,
                                synsetScore);
                    }
                }
            }

            // Go through all the terms.
            for (Map.Entry<String, HashMap<Integer, Double>> entry : tempDictionary
                    .entrySet()) {
                String word = entry.getKey();
                Map<Integer, Double> synSetScoreMap = entry.getValue();

                // Calculate weighted average. Weigh the synsets according to
                // their rank.
                // score = score_first/rank_first + score_second/rank_second +....
                // sum = 1/rank_first + 1/rank_second + 1/rank_third....
                // final_score = score/sum
                // dictionary.put(word, final_score)
                double score = 0.0;
                double sum = 0.0;
                for (Map.Entry<Integer, Double> setScore : synSetScoreMap
                        .entrySet()) {
                    //synTermRank == setScore.getKey()
                    //synsetScore == setScore.getValue()
                    score += setScore.getValue() / (double) setScore.getKey();
                    sum += 1.0 / (double) setScore.getKey();
                }
                score /= sum;

                //using word from before like synterm as key and score as value.
                dictionary.put(word, score);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (csv != null) {
                csv.close();
            }
        }
    }

    //returns value from a dictionary where key is word#pos.
    public double extract(String word, String pos) {
        String key = word + "#" + pos;
        if (dictionary.containsKey(key))
            return dictionary.get(word + "#" + pos);
        else
            return 0;
    }

    public static void main(String [] args) throws IOException {
        if(args.length<1) {
            System.err.println("Usage: java SentiWordNetDemoCode <pathToSentiWordNetFile>");
            return;
        }

        String pathToSWN = args[0];
        SentiWordNet sentiwordnet = new SentiWordNet(pathToSWN);
        //returns score corresponding to the given key like good#a, blue#n
        System.out.println("good#a "+sentiwordnet.extract("good", "a"));
        System.out.println("bad#a "+sentiwordnet.extract("bad", "a"));
        System.out.println("blue#a "+sentiwordnet.extract("blue", "a"));
        System.out.println("blue#n "+sentiwordnet.extract("blue", "n"));
    }
}
