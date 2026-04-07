public with sharing class SocialMediaContentService extends BaseAPIService {
    private static final String BASE_PATH = '/services/data/v64.0/composite/sobjects';

    /**
     * @description Constructor initializing the Metadata API endpoint
     */
    public SocialMediaContentService(String namedCredential, String apiEndpoint) {
        super();
        setApiEndpoint(apiEndpoint);
        setNamedCredential(namedCredential);
    }

    public void createContentRecords(List<Object> contentRecords){
        APIService api = new APIService();
        String endpoint = BASE_PATH;
        String fullApiEndPoint = 'callout:' + namedCredential + apiEndpoint + endpoint+'/Social_Media_Content__c/Platform_Content_ID__c';

        Map<String,Object> payload = new Map<String,Object>();
        Map<String,String> header = new Map<String,String>();
        header.put('Content-Type', 'application/json');
        payload.put('allOrNone', false);

        List<Map<String,Object>> records = new List<Map<String,Object>>();
        for (Object contentRecord : contentRecords) {
            Map<String,Object> contentRecordMap = (Map<String,Object>) contentRecord;
            String pageRef = null;
            Datetime timeStamp;
            if(contentRecordMap.containsKey('pageId')){
                pageRef = (String) contentRecordMap.get('pageId');
            }
            if(contentRecordMap.containsKey('timeStamp')){
                timeStamp = SocialMediaUtility.convertISO8601((String) contentRecordMap.get('timeStamp'));
            }else{
                timeStamp = System.now();
            }

            records.add(new Map<String, Object>{
                'attributes' => new Map<String, Object>{
                    'type' => 'Social_Media_Content__c'
                },
                'Platform_Content_ID__c' => (String) contentRecordMap.get('contentId'),
                'Content_Text__c' => (String) contentRecordMap.get('contentText'),
                'Social_Media_Account__c' => (String) contentRecordMap.get('socialMediaAccountId'),
                'Content_Type__c' => (String) contentRecordMap.get('contentType'),
                'Author_Name__c' => (String) contentRecordMap.get('authorName'),
                'Platform__c' => (String) contentRecordMap.get('platform'),
                'Published_Date__c'=> timeStamp,
                'Facebook_Page_ID__c' => pageRef
            });
            payload.put('records', records);
        }
        HttpResponse res = api.makeCallout(fullApiEndPoint, 'PATCH', JSON.serialize(payload), header, 120000, true);
    }
}