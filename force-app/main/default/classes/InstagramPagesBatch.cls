public with sharing class InstagramPagesBatch implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
    private final String batchJobId;
    private Integer batchCount = 0;
    private String userId = '';
    private String socialMediaAccountId = '';
    private InstagramService service;
    List<Object> instaAccountList = new List<Object>();
    List<Object> mediaList = new List<Object>();
    List<Object> commentList = new List<Object>();

    public InstagramPagesBatch(InstagramService service, String userId, List<Object> instagramAccounts) {
        List<Social_Media_Account__c> accounts = [SELECT Id FROM Social_Media_Account__c WHERE Platform_Account_ID__c = :userId LIMIT 1];
        this.socialMediaAccountId = accounts[0].Id;
        this.userId = userId;
        this.service = service;
        this.instaAccountList = instagramAccounts;
        this.batchJobId = String.valueOf(System.currentTimeMillis());
    }
    
    public List<Object> start(Database.BatchableContext bc) {
        return this.instaAccountList;
    }
    
    public void execute(Database.BatchableContext bc, List<Object> scope) {        
        try {
            for (Object item : scope) {
                Map<String,Object> itemMap = (Map<String,Object>) item;
                String instaAccountId = (String) itemMap.get('id');
                Map<String, Object> mediaAndCommentMap = service.getMediaAndComments(this.socialMediaAccountId, instaAccountId);
                mediaList.addAll((List<Object>) mediaAndCommentMap.get('posts'));
                commentList.addAll((List<Object>) mediaAndCommentMap.get('comments'));
            }            
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in batch execution: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext bc) {        
        try {
            // Store post data
            if (!mediaList.isEmpty()) {
                SocialMediaContentService contnetService = new SocialMediaContentService('Social_Media_Manager','');
                contnetService.createContentRecords(mediaList);
            }
            // Store comment data
            if (!commentList.isEmpty()) {
                SocialMediaInteractionService interactionService = new SocialMediaInteractionService('Social_Media_Manager','');
                interactionService.createInteractionRecords(commentList);
            }    
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in finish method: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
        }
    }
}