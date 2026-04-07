public with sharing class MapService extends BaseAPIService {
   private static final String BASE_PATH = '/v1/';
    private static final Integer TIMEOUT = 120000;
    private String payload;
    private static final String NAMED_CREDENTIAL = 'Conscendo_HYD_Map_NamedCred';
    private static final String API_ENDPOINT = '';

        /**
     * @description Constructor initializing the Metadata API endpoint
     */
    public MapService() {
        super();
        setApiEndpoint(NAMED_CREDENTIAL);
        setNamedCredential(API_ENDPOINT);
    }
    public List<Map<String,String>> searchPlaces(String searchText) {

        APIService api = new APIService();
        String endpoint = BASE_PATH + 'places:searchText';
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'X-Goog-FieldMask' => 'places.id,places.displayName,places.formattedAddress'
        };
        Map<String, Object> payload = new Map<String, Object>{ 'textQuery' => searchText };
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'POST', JSON.serialize(payload), headers, 120000, true);
        Map<String,Object> responseBodyMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> placeList = (List<Object>) responseBodyMap.get('places');
        List<Map<String,String>> placeInfo = new List<Map<String,String>>();
        for (Object place : placeList) {
            Map<String,Object> placeMap = (Map<String,Object>) place;
            Map<String, Object> displayNameMap = (Map<String,Object>) placeMap.get('displayName');
            placeInfo.add(new Map<String,String>{
                'id'=>(String)placeMap.get('id'),
                'address'=>(String)placeMap.get('formattedAddress'),
                'displayName'=>(String)displayNameMap.get('text')
            });
        }
        return placeInfo;
    }
    // search places
    public List<Object> getPlaceReviews(String placeId){
        List<Object> placeReviewResult = new List<Object>();
        APIService api = new APIService();
        System.debug('access_token: '+Auth.AuthToken.getAccessToken(CustomSettingService.getGoogleProviderId(), 'Google'));
        String endpoint = BASE_PATH + 'places/'+placeId+'?fields=reviews&access_token='+Auth.AuthToken.getAccessToken(CustomSettingService.getGoogleProviderId(), 'Google');
        String fullApiEndPoint = 'callout:'+namedCredential+apiEndpoint+endpoint;
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'GET', null, null, 120000, true);
        // process review responses
        Map<String,Object> responseBodyMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> reviewList = (List<Object>) responseBodyMap.get('reviews');
        for(Object review: reviewList){
            Map<String,Object> reiviewMap = (Map<String,Object>) review;
            Map<String, Object> authorAttribution = (Map<String, Object>) reiviewMap.get('authorAttribution');
            String authorName = authorAttribution != null ? (String) authorAttribution.get('displayName') : 'Anonymous';
            String contentPath = (String) reiviewMap.get('name');
            List<String> nameParts = contentPath.split('/');
            String contentId = nameParts[nameParts.size()-1];
            System.debug('contentId: '+contentId);
            placeReviewResult.add(new Map<String,Object>{
                'interactionId'=> contentId,
                'authorName'=>authorName,
                'rating'=>reiviewMap.get('rating'),
                'platform'=>'Google',
                'interactionText'=>((Map<String, Object>) reiviewMap.get('text')).get('text'),
                'publishTime'=>reiviewMap.get('publishTime')
            });
        }
        return placeReviewResult;
    }

    public void syncMapReviews(Id socialMediaAccountId, String placeId){
        // create a google content record
        List<Map<String,Object>> contentList = new List<Map<String,Object>>{
            new Map<String,Object>{
                'contentId' => placeId,
                'platform' => 'Google',
                'authorName' => 'Google Maps',
                'contentText' => 'Google Maps reviews for ' + placeId,
                'contentType' => 'Review',
                'socialMediaAccountId'=> socialMediaAccountId
                // 'pageId' => socialMediaAccountId
            }
        };
        SocialMediaContentService contentService = new SocialMediaContentService('Social_Media_Manager','');
        contentService.createContentRecords(contentList);
        System.debug('Successfully created content record for Google Maps reviews');
        List<Social_Media_Content__c> contentRecords = SocialMediaContentSelector.selectByPlatform('Google');
        List<Object> placeReviews = getPlaceReviews(placeId);
        List<Map<String, Object>> commentList = new List<Map<String, Object>>();
        for (Object contentObj : placeReviews) {
            Map<String,Object> contentMap = (Map<String, Object>) contentObj;
            commentList.add(new Map<String,Object>{
                'interactionId' => (String) contentMap.get('interactionId'),
                'contentId' => contentRecords[0].Id,
                'interactionText' => (String) contentMap.get('interactionText'),
                'timeStamp' => (String) contentMap.get('publishTime'),
                // 'pageId' => socialMediaAccountId,
                'platform' => 'Google',
                'authorName' => (String) contentMap.get('authorName')
            });
        }
        // Store comment data
        if (!commentList.isEmpty()) {
            SocialMediaInteractionService interactionService = new SocialMediaInteractionService('Social_Media_Manager','');
            interactionService.createInteractionRecords(commentList);
            System.debug('Successfully processed ' + commentList.size() + ' reviews');
        }
    }

}