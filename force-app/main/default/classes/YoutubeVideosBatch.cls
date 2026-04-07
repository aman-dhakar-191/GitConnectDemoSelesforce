public with sharing class YoutubeVideosBatch implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
    private final String batchJobId;
    private Integer batchCount = 0;
    private String channelId = '';
    private YoutubeService service;
    List<Object> videoList = new List<Object>();
    List<Object> commentList = new List<Object>();

    public YoutubeVideosBatch(YoutubeService service, String channelId) {
        this.channelId = channelId;
        this.service = service;
        this.batchJobId = String.valueOf(System.currentTimeMillis());
    }
    
    public List<Object> start(Database.BatchableContext bc) {
        System.debug('YoutubeVideosBatch start - Channel ID: ' + this.channelId);
        try {
            videoList = service.getVideos(this.channelId);
            System.debug('Retrieved ' + videoList.size() + ' videos');
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in start method: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
            // Return empty list to prevent batch from failing
            return new List<Object>();
        }
        return videoList;
    }
    
    public void execute(Database.BatchableContext bc, List<Object> scope) {
        System.debug('YoutubeVideosBatch execute - Processing ' + scope.size() + ' videos');
        
        try {
            for (Object item : scope) {
                Map<String, Object> itemMap = (Map<String,Object>) item;
                String videoId = (String)itemMap.get('contentId');
                
                if (String.isNotBlank(videoId)) {
                    List<Object> batchCommentList = service.getComments(videoId);
                    System.debug('batchCommentList: '+batchCommentList);
                    // FIX: Actually append the comments to the global commentList
                    if (batchCommentList != null && !batchCommentList.isEmpty()) {
                        commentList.addAll(batchCommentList);
                        System.debug('Added ' + batchCommentList.size() + ' comments for video: ' + videoId);
                    }
                } else {
                    System.debug(LoggingLevel.WARN, 'Video ID is blank for item: ' + itemMap);
                }
            }
            
            System.debug('Total comments collected so far: ' + commentList.size());
            
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in batch execution: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('YoutubeVideosBatch finish - Processing ' + videoList.size() + ' videos and ' + commentList.size() + ' comments');
        
        try {
            // Store video content
            if (!videoList.isEmpty()) {
                SocialMediaContentService contentService = new SocialMediaContentService('Social_Media_Manager','');
                contentService.createContentRecords(videoList);
                System.debug('Successfully processed ' + videoList.size() + ' video content records');
            }
            // Store comment data
            if (!commentList.isEmpty()) {
                SocialMediaInteractionService interactionService = new SocialMediaInteractionService('Social_Media_Manager','');
                interactionService.createInteractionRecords(commentList);
                System.debug('Successfully processed ' + commentList.size() + ' comments');
            }
            
            
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in finish method: ' + e.getMessage() + 
                         '. Stack trace: ' + e.getStackTraceString());
        }
    }
}