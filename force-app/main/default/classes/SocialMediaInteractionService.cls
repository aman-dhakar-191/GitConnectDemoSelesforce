public with sharing class SocialMediaInteractionService extends BaseAPIService {
    private static final String BASE_PATH = '/services/data/v64.0/composite/sobjects';
    
    /**
     * @description Constructor initializing the Metadata API endpoint
     */
    public SocialMediaInteractionService(String namedCredential, String apiEndpoint) {
        super();
        setApiEndpoint(apiEndpoint);
        setNamedCredential(namedCredential);
    }
    
    public void createInteractionRecords(List<Object> interactionRecords){
        Map<String,String> socialMediaConentIdMap = new Map<String,String>();
        Set<String> contentIds = new Set<String>();
        for (Object interactionRecordObj : interactionRecords) {
            Map<String,Object> interactionRecordMap = (Map<String,Object>) interactionRecordObj;
            contentIds.add((String)interactionRecordMap.get('contentId'));
        }
        for( Social_Media_Content__c content : [SELECT Id, Platform_Content_ID__c FROM Social_Media_Content__c WHERE Platform_Content_ID__c IN :contentIds]) {
            socialMediaConentIdMap.put(content.Platform_Content_ID__c, content.Id);
        }
        APIService api = new APIService();
        List<Map<String, String>> searchVideoResults = new List<Map<String, String>>();
        
        // Fixed endpoint - removed the field-specific path for general composite sobjects
        String endpoint = BASE_PATH;
        String fullApiEndPoint = 'callout:' + namedCredential + apiEndpoint + endpoint+'/Social_Media_Interaction__c/Platform_Interaction_Id__c';
        
        Map<String,Object> payload = new Map<String,Object>();
        Map<String,String> header = new Map<String,String>();
        header.put('Content-Type', 'application/json');
        payload.put('allOrNone', false);
        
        List<Map<String,Object>> records = new List<Map<String,Object>>();
        // System.debug('interactionRecords: '+interactionRecords);
        for (Object interactionRecord : interactionRecords) {
            Map<String,Object> interactionRecordMap = (Map<String,Object>) interactionRecord;
            System.debug('interactionRecordMap: '+interactionRecordMap);
            String contentRef = null;
            String parentInteractionRef = null;
            String pageRef = null;
            Datetime timeStamp;
            if(interactionRecordMap.containsKey('contentId')){
                contentRef = (String) interactionRecordMap.get('contentId');
            }
            if(interactionRecordMap.containsKey('parentInteractionId')){
                parentInteractionRef = (String) interactionRecordMap.get('parentInteractionId');
            }
            if(interactionRecordMap.containsKey('pageId')){
                pageRef = (String) interactionRecordMap.get('pageId');
            }
            if(interactionRecordMap.containsKey('timeStamp')){
                timeStamp = SocialMediaUtility.convertISO8601((String) interactionRecordMap.get('timeStamp'));
            }
            // Added the required attributes field for each record
            records.add(new Map<String, Object>{
                'attributes' => new Map<String, Object>{
                    'type' => 'Social_Media_Interaction__c'
                },
                'Platform_Interaction_Id__c' => (String) interactionRecordMap.get('interactionId'),
                'Social_Media_Content_Id__c' => contentRef,
                'Parent_Interaction_Id__c'=> parentInteractionRef,
                'Interaction_Text__c' => (String) interactionRecordMap.get('interactionText'),
                'Interaction_Type__c'=>'comment',
                'Platform__c' => (String) interactionRecordMap.get('platform'),
                'Author_Name__c' => (String) interactionRecordMap.get('authorName'),
                'Response_Date__c'=> timeStamp,
                'Facebook_Page_ID__c' => pageRef
            });
        }
        payload.put('records', records);

        HttpResponse res = api.makeCallout(fullApiEndPoint, 'PATCH', JSON.serialize(payload), header, 120000, true);
    }
}