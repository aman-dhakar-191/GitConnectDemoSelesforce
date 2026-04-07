public with sharing class TwitterService extends BaseAPIService {
    private static final String BASE_PATH = '/2/';
    private static final String YOUTUBE_API_KEY = 'AIzaSyBoUpgD5fiARVw6A3MpxlKutZwlqEEhwPg';
    private static final Integer TIMEOUT = 120000;
    private String payload;

        /**
     * @description Constructor initializing the Metadata API endpoint
     */
    public TwitterService(String namedCredential, String apiEndpoint) {
        super();
        setApiEndpoint(apiEndpoint);
        setNamedCredential(namedCredential);
    }
    // get user id
    public String getUserId(String username){
        APIService api = new APIService();
        List<Map<String, String>> searchVideoResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'users/by/username/' + username;
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to fetch user ID: ' + res.getBody());
        }

        Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String)((Map<String, Object>)json.get('data')).get('id');
    }
    // getTweetsByUserId
    public void getTweetsByUserId(String userId){
        APIService api = new APIService();
        List<Map<String, String>> searchVideoResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'users/' + userId + '/tweets?tweet.fields=created_at';
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to fetch tweets: ' + res.getBody());
        }
        System.debug('res: '+res);
    }
    // getConversationId
    public String getConversationId(String tweetId){
        APIService api = new APIService();
        List<Map<String, String>> searchVideoResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'tweets/' + tweetId + '?tweet.fields=conversation_id';
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to fetch tweet info: ' + res.getBody());
        }

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) response.get('data');
        return (String) data.get('conversation_id');
    }
    // getTweetReplies
    public String getTweetReplies(String tweetId){
        APIService api = new APIService();
        List<Map<String, String>> searchVideoResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'tweets/search/recent?query=' +
            EncodingUtil.urlEncode('conversation_id:' + tweetId, 'UTF-8') +
            '&tweet.fields=created_at,text,author_id,conversation_id,referenced_tweets' +
            '&max_results=20';
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to fetch replies: ' + res.getBody());
        }

        return res.getBody();
    }
    // replyToTweet
    public void replayToTweet(String tweetId, String message){
        APIService api = new APIService();
        List<Map<String, String>> videoCommentResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'tweets';
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json'
        };
        Map<String, Object> payload = new Map<String, Object>{ 
            'text' => message,
            'reply' => new Map<String, Object>{
                'in_reply_to_tweet_id' => tweetId
            }
        };
        System.debug('fullApiEndPoint: '+fullApiEndPoint);
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', JSON.serialize(payload), headers, 120000, true);
        System.debug('res: '+res);
        if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to reply: ' + res.getBody());
        }
    }
}