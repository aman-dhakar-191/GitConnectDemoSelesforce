public with sharing class YoutubeService extends BaseAPIService {
    private static final String BASE_PATH = '/youtube/v3/';
    private static final String YOUTUBE_API_KEY = 'AIzaSyBoUpgD5fiARVw6A3MpxlKutZwlqEEhwPg';
    private static final Integer TIMEOUT = 120000;
    private String payload;
    private static final String NAMED_CREDENTIAL = 'Conscendo_HYD_Youtube_NamedCred';
    private static final String API_ENDPOINT = '';

        /**
     * @description Constructor initializing the Metadata API endpoint
     */
    public YoutubeService() {
        super();
        setApiEndpoint(NAMED_CREDENTIAL);
        setNamedCredential(API_ENDPOINT);
    }
    // search video
    public List<Map<String, String>> searchVideo(String query){
        APIService api = new APIService();
        List<Map<String, String>> searchVideoResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'search?part=snippet&type=channel&q=' + EncodingUtil.urlEncode(query, 'UTF-8') + '&access_token=' + Auth.AuthToken.getAccessToken(CustomSettingService.getGoogleProviderId(), 'Google');
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> items = (List<Object>) jsonResponse.get('items');
            for (Object item : items) {
                Map<String, Object> itemMap = (Map<String, Object>) item;
                Map<String, Object> id = (Map<String, Object>) itemMap.get('id');
                Map<String, Object> snippet = (Map<String, Object>) itemMap.get('snippet');

                Map<String, String> channel = new Map<String, String>();
                channel.put('id', (String) id.get('channelId'));
                channel.put('title', (String) snippet.get('title'));
                searchVideoResults.add(channel);
            }
        } else {
            System.debug('Failed to search YouTube channels. Status Code: ' + res.getStatusCode());
        }
        return searchVideoResults;
    }
    // get videos
    public List<Object> getVideos(String channelId){
        // get social media channel account id
        String socialMediaAccountId = '';
        List<Social_Media_Account__c> socialMediaAccounts = [SELECT Id FROM Social_Media_Account__c WHERE Platform_Account_ID__c = :channelId LIMIT 1];
        if(socialMediaAccounts != null && !socialMediaAccounts.isEmpty()){
            socialMediaAccountId = socialMediaAccounts[0].Id;
        }
        APIService api = new APIService();
        List<Object> videosResults = new List<Object>();
        String endpoint = BASE_PATH + 'search?part=snippet&channelId=' + EncodingUtil.urlEncode(channelId, 'UTF-8') + '&access_token=' + Auth.AuthToken.getAccessToken(CustomSettingService.getGoogleProviderId(), 'Google');
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);

        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> items = (List<Object>) jsonResponse.get('items');
            for (Object item : items) {
                Map<String, Object> itemMap = (Map<String, Object>) item;
                Map<String, Object> id = (Map<String, Object>) itemMap.get('id');
                Map<String, Object> snippet = (Map<String, Object>) itemMap.get('snippet');

                Map<String, String> video = new Map<String, String>();
                if((String) id.get('kind') == 'youtube#video'){
                    video.put('socialMediaAccountId', socialMediaAccountId);
                    video.put('contentId', (String) id.get('videoId'));
                    video.put('contentType', 'Video');
                    video.put('authorName', 'anonymous');
                    video.put('platform', 'Youtube');
                    video.put('contentText', (String) snippet.get('title'));
                    video.put('timeStamp', (String) snippet.get('publishTime'));
                    videosResults.add(video);
                }
            }
        } else {
            System.debug('Failed to retrieve videos. Status Code: ' + res.getStatusCode());
        }

        return videosResults;
    }
    // get comment
    public List<Object> getComments(String videoId){
        APIService api = new APIService();
        List<Object> videoCommentResults = new List<Object>();
        String endpoint = BASE_PATH + 'commentThreads?part=snippet&maxResults=10&videoId=' + EncodingUtil.urlEncode(videoId, 'UTF-8') + '&access_token=' + Auth.AuthToken.getAccessToken(CustomSettingService.getGoogleProviderId(), 'Google');
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> items = (List<Object>) jsonResponse.get('items');

            for (Object commentObj : items) {
                Map<String, Object> commentMap = (Map<String, Object>) commentObj;
                Map<String, Object> snippet = (Map<String, Object>) commentMap.get('snippet');
                Map<String, Object> topLevelComment = (Map<String, Object>) snippet.get('topLevelComment');
                Map<String, Object> commentSnippet = (Map<String, Object>) topLevelComment.get('snippet');

                Map<String, String> comment = new Map<String, String>();
                comment.put('interactionId', (String) topLevelComment.get('id'));
                comment.put('interactionText', (String) commentSnippet.get('textDisplay'));
                comment.put('contentId', videoId);
                comment.put('platform', 'Youtube');
                comment.put('authorName', (String) commentSnippet.get('authorDisplayName'));

                videoCommentResults.add(comment);
            }
        } else {
            System.debug('Failed to retrieve comments. Status Code: ' + res.getStatusCode());
        }
        return videoCommentResults;
    }
    public void syncComments(Id socialMediaAccountId, String channelId){
        YoutubeVideosBatch youtubeVideosBatch = new YoutubeVideosBatch(this, channelId);
        Database.executeBatch(youtubeVideosBatch, 1);
    }
    // reply to comment
    public String replyToComment(String commentId, String text){
        APIService api = new APIService();
        List<Map<String, String>> videoCommentResults = new List<Map<String, String>>();
        String endpoint = BASE_PATH + 'comments?part=snippet';
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json'
        };
        Map<String, Object> payload = new Map<String, Object>{ 'snippet' => new Map<String, Object>{
            'textOriginal'=>text,
            'parentId'=>commentId
        } };
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', JSON.serialize(payload), headers, 120000, true);
        if (res.getStatusCode() == 200) {
            return '✅ Reply posted successfully.';
        } else {
            return '❌ Failed to post reply. Code: ' + res.getStatusCode() + '. Body: ' + res.getBody();
        }
    }

}