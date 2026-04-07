public with sharing class FacebookPagesBatch implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
    private final String batchJobId;
    private Integer batchCount = 0;
    private String userId = '';
    private String socialMediaAccountId = '';
    private FacebookService facebookService;
    private InstagramService instagramService;
    List<Object> postList = new List<Object>();
    List<Object> commentList = new List<Object>();
    List<Object> connectInstagramAccountList = new List<Object>();
    Map<String,Object> postListMap = new Map<String,Object>();

    public FacebookPagesBatch(FacebookService facebookService,  String userId) {
        List<Social_Media_Account__c> accounts = [SELECT Id FROM Social_Media_Account__c WHERE Platform_Account_ID__c = :userId LIMIT 1];
        this.socialMediaAccountId = accounts[0].Id;
        this.userId = userId;
        this.facebookService = facebookService;
        this.instagramService = new InstagramService();
        this.batchJobId = String.valueOf(System.currentTimeMillis());
    }
    
    public List<Object> start(Database.BatchableContext bc) {
        List<Object> pagesList = new List<Object>();
        try {
            pagesList = facebookService.getOwnedPagesByBusinessId(userId);
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in start method: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
            // Return empty list to prevent batch from failing
            return new List<Object>();
        }
        return pagesList;
    }
    
    public void execute(Database.BatchableContext bc, List<Object> scope) {
        try {            
            for (Object item : scope) {
                Map<String,Object> itemMap = (Map<String,Object>) item;
                String pageId = (String) itemMap.get('id');
                String pageAccessToken = (String)itemMap.get('access_token');
                Map<String,Object> postAndCommentMap = facebookService.getPostsAndComments(this.socialMediaAccountId, pageAccessToken, pageId);
                postList.addAll((List<Object>) postAndCommentMap.get('posts'));
                commentList.addAll((List<Object>) postAndCommentMap.get('comments'));
                // get instagram account connect to facebook page.
                List<Map<String, String>> instagramAccounts = facebookService.getInstagramAccountsByPage(pageId,pageAccessToken);
                connectInstagramAccountList.addAll(instagramAccounts);
            }
            // System.debug('Total comments collected so far: ' + postList.size());
            
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in batch execution: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext bc) {
        
        try {
            // Store post data
            if (!postList.isEmpty()) {
                SocialMediaContentService contnetService = new SocialMediaContentService('Social_Media_Manager','');
                contnetService.createContentRecords(postList);
            }
            // Store comment data
            if (!commentList.isEmpty()) {
                SocialMediaInteractionService interactionService = new SocialMediaInteractionService('Social_Media_Manager','');
                interactionService.createInteractionRecords(commentList);
            }
            // // run posts batch
            InstagramPagesBatch pageBatch = new InstagramPagesBatch(instagramService, this.userId, connectInstagramAccountList);
            Database.executeBatch(pageBatch, 1);
            
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in finish method: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
        }
    }
}