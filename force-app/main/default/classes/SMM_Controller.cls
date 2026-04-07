public with sharing class SMM_Controller {
    @AuraEnabled
    public static List<Social_Media_Content__c> getSocialMediaContents(String childAccountId, String platform, String dateFilter, String item, String search) {
        List<String> socialMediaAccountIds = getSocialMediaAccountIds(childAccountId);
        System.debug('Fetching social media contents with filters: ' + 
                    'Platform: ' + platform + ', Date Filter: ' + dateFilter + 
                    ', Item: ' + item + ', Search: ' + search);
        
        // Build base query without search condition
        String query = 'SELECT Id, Platform_Content_Id__c, Name, Author_Name__c, Content_Text__c, Published_Date__c, Platform__c, Sentiment__c, Content_Type__c FROM Social_Media_Content__c';
        List<String> conditions = new List<String>();
        
        // Wrap each Id in single quotes for SOQL
        List<String> quotedIds = new List<String>();
        for (String accId : socialMediaAccountIds) {
            quotedIds.add('\'' + String.escapeSingleQuotes(accId) + '\'');
        }
        conditions.add('Social_Media_Account__c In (' + String.join(quotedIds, ',') + ')');

        if (platform != null && platform != '') {
            conditions.add('Platform__c = \'' + String.escapeSingleQuotes(platform) + '\'');
        }
        
        // Handle date filtering
        if (dateFilter != null && dateFilter != '') {
            if (dateFilter == '24') {
                conditions.add('Published_Date__c >= LAST_N_DAYS:1');
            } else if (dateFilter == '7') {
                conditions.add('Published_Date__c >= LAST_N_DAYS:7');
            } else if (dateFilter == '30') {
                conditions.add('Published_Date__c >= LAST_N_DAYS:30');
            } else if (dateFilter == 'year') {
                conditions.add('Published_Date__c = THIS_YEAR');
            }
        }
        
        // Handle item filtering
        if (item != null && item != '') {
            conditions.add('Content_Type__c = \'' + String.escapeSingleQuotes(item) + '\'');
        }
                
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        System.debug('Executing query: ' + query);
        
        // Fetch social media contents from database
        List<Social_Media_Content__c> contents = Database.query(query);
        
        // Apply search filter after getting results
        if (search != null && search != '') {
            List<Social_Media_Content__c> filteredContents = new List<Social_Media_Content__c>();
            String searchLower = search.toLowerCase();
            
            for (Social_Media_Content__c content : contents) {
                if (content.Content_Text__c != null && 
                    content.Content_Text__c.toLowerCase().contains(searchLower)) {
                    filteredContents.add(content);
                }
            }
            
            return filteredContents;
        }
        
        return contents;
    }

    @AuraEnabled
    public static List<Social_Media_Interaction__c> getSocialMediaParentInteractions(String contentId, String platform) {
        System.debug('Fetching social media parent interactions for contentId: ' + contentId);
        
        // Build base query without search condition
        String query = 'SELECT Id, Platform_Interaction_Id__c, Interaction_Text__c, Parent_Interaction_Id__c, Platform__c, Response_Date__c, Social_Media_Content_Id__c FROM Social_Media_Interaction__c';
        List<String> conditions = new List<String>();

        if (contentId != null && contentId != '' && platform != 'Google') {
            conditions.add('Social_Media_Content_Id__c = \'' + String.escapeSingleQuotes(contentId) + '\'');
        }else{
            conditions.add('Platform__c = \'' + String.escapeSingleQuotes(platform) + '\'');
        }
        // for parent interactions, we assume that the parent interaction is empty
        conditions.add('Parent_Interaction__c = null');
                
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        System.debug('Executing query: ' + query);
        
        // Fetch social media contents from database
        List<Social_Media_Interaction__c> contents = Database.query(query);
        
        return contents;
    }
    @AuraEnabled
    public static List<Social_Media_Interaction__c> getSocialMediaChildInteractions(String parentInteractionId) {
        System.debug('Fetching social media child interactions for parentInteractionId: ' + parentInteractionId);

        // Build base query without search condition
        String query = 'SELECT Id, Platform_Interaction_Id__c, Interaction_Text__c, Parent_Interaction_Id__c, Platform__c, Response_Date__c, Social_Media_Content_Id__c FROM Social_Media_Interaction__c';
        List<String> conditions = new List<String>();

        if (parentInteractionId != null && parentInteractionId != '') {
            conditions.add('Parent_Interaction_Id__c = \'' + String.escapeSingleQuotes(parentInteractionId) + '\'');
        }
        // for parent interactions, we assume that the parent interaction is empty
        conditions.add('Parent_Interaction_Id__c != null');

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        System.debug('Executing query: ' + query);
        
        // Fetch social media contents from database
        List<Social_Media_Interaction__c> contents = Database.query(query);
        
        return contents;
    }

    @AuraEnabled
    public static String runSocialMediaPlatformSync(){
        try {
            // Call the MapService to sync Google Maps reviews
            // get the placeId and socialMediaAccountId from the social media account
            List<Social_Media_Account__c> accounts = SocialMediaAccountSelector.selectAll();
            for (Social_Media_Account__c account : accounts) {
                String socialMediaAccountId = account.Id;
                switch on account.Platform__c {
                        when 'Google' {
                            String placeId = account.Platform_Account_ID__c;
                            if (!String.isBlank(placeId)) {
                                // Google-specific logic handled below
                                MapService mapService = new MapService();
                                mapService.syncMapReviews(socialMediaAccountId, placeId);
                            }
                        }
                        when 'Youtube' {
                            String channelId = account.Platform_Account_ID__c;
                            if (!String.isBlank(channelId)) {
                                // Youtube-specific logic handled below
                                YoutubeService youtubeService = new YoutubeService();
                                youtubeService.syncComments(socialMediaAccountId, channelId);
                            }
                        }
                        when 'Facebook' {
                            // Facebook and Instagram will synced together
                            String userId = account.Platform_Account_ID__c;
                            if (!String.isBlank(userId)) {
                                // Add Facebook sync logic here if needed
                                FacebookService facebookService = new FacebookService();
                                facebookService.syncComments(socialMediaAccountId, userId);
                            }
                        }
                        when else {
                            // Handle other platforms or do nothing
                        }
                    }
                
            }
            return 'Sync completed successfully';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // create comment/reply
    @AuraEnabled
    public static void sendComment(String id, String message, String platformName, String commentType) {
        System.debug('Sending comment: ' + message + ' to ' + platformName);
        System.debug('Comment Type: ' + commentType + ', ID: ' + id);
        // Input validation
        if (String.isBlank(id) || String.isBlank(message) || String.isBlank(platformName) || String.isBlank(commentType)) {
            throw new IllegalArgumentException('All parameters must be provided');
        }
        
        // Validate comment type
        if (commentType != 'comment' && commentType != 'post') {
            throw new IllegalArgumentException('Invalid comment type. Must be "comment" or "post"');
        }
        
        try {
            switch on platformName.toLowerCase() {
                when 'instagram' {
                    handleInstagramComment(id, message, commentType);
                }
                when 'facebook' {
                    handleFacebookComment(id, message, commentType);
                }
                when else {
                    throw new UnsupportedOperationException('Platform "' + platformName + '" is not supported');
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in sendComment: ' + e.getMessage());
            throw new AuraHandledException('Failed to send comment: ' + e.getMessage());
        }
    }

    private static void handleInstagramComment(String id, String message, String commentType) {
        InstagramService instaService = new InstagramService();
        
        if (commentType == 'post') {
            instaService.sentReplyToPost(id, message);
        } else {
            instaService.sentReplyToComment(id, message);
        }
    }

    private static void handleFacebookComment(String id, String message, String commentType) {
        FacebookService facebookService = new FacebookService();
        String pageId = getPageIdForFacebook(id, commentType);
        String pageAccessToken = facebookService.getPageAccessTokenByPageId(pageId);
        
        if (commentType == 'comment') {
            facebookService.sentReplyToPost(id, message, pageAccessToken);
        } else {
            facebookService.sentReplyToComment(id, message, pageAccessToken);
        }
    }

    private static String getPageIdForFacebook(String id, String commentType) {
        String pageId;
        
        if (commentType == 'comment') {
            List<Social_Media_Interaction__c> records = [
                SELECT Facebook_Page_ID__c 
                FROM Social_Media_Interaction__c 
                WHERE Platform_Interaction_Id__c = :id 
                LIMIT 1
            ];
            
            if (records.isEmpty()) {
                throw new QueryException('No Social Media Interaction found for ID: ' + id);
            }
            pageId = records[0].Facebook_Page_ID__c;
            
        } else { // reply
            List<Social_Media_Content__c> records = [
                SELECT Facebook_Page_ID__c 
                FROM Social_Media_Content__c 
                WHERE Platform_Content_ID__c = :id 
                LIMIT 1
            ];
            
            if (records.isEmpty()) {
                throw new QueryException('No Social Media Content found for ID: ' + id);
            }
            System.debug('records: '+records);
            pageId = records[0].Facebook_Page_ID__c;
        }
        
        if (String.isBlank(pageId)) {
            throw new AuraHandledException('Facebook Page ID is blank for record with ID: ' + id);
        }
        
        return pageId;
    }

    @AuraEnabled
    public static Lead createLead(Map<String, Object> lead) {
        // Null check for lead
        if (lead == null) {
            throw new AuraHandledException('Lead data is required.');
        }
        // Basic validation (example: required fields)
        String lastName = (String)lead.get('LastName');
        String company = (String)lead.get('Company');
        if (String.isBlank(lastName) || String.isBlank(company)) {
            throw new AuraHandledException('LastName and Company are required.');
        }
        Lead leadData = new Lead();
        leadData.FirstName = (String)lead.get('FirstName');
        leadData.LastName = lastName;
        leadData.Company = company;
        leadData.Title = (String)lead.get('Title');
        leadData.Email = (String)lead.get('Email');
        leadData.Phone = (String)lead.get('Phone');
        try {
            insert leadData;
            return leadData;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating Lead: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Case createCase(Map<String, Object> caseMap) {
        // Null check for caseMap
        if (caseMap == null) {
            throw new AuraHandledException('Case data is required.');
        }
        // Basic validation (example: required fields)
        String subject = (String)caseMap.get('Subject');
        String origin = (String)caseMap.get('Origin');
        if (String.isBlank(subject) || String.isBlank(origin)) {
            throw new AuraHandledException('Subject and Origin are required.');
        }
        Case caseData = new Case();
        caseData.Subject = subject;
        caseData.Origin = origin;
        caseData.Status = (String)caseMap.get('Status');
        caseData.Priority = (String)caseMap.get('Priority');
        caseData.Description = (String)caseMap.get('Description');
        caseData.ContactId = (Id)caseMap.get('ContactId');
        caseData.AccountId = (Id)caseMap.get('AccountId');
        // Add support for SuppliedEmail and SuppliedPhone
        caseData.SuppliedEmail = (String)caseMap.get('SuppliedEmail');
        caseData.SuppliedPhone = (String)caseMap.get('SuppliedPhone');
        try {
            insert caseData;
            return caseData;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating Case: ' + e.getMessage());
        }
    }

	private static List<String> getSocialMediaAccountIds(String childAccountId){
        List<Social_Media_Account__c> accounts = SocialMediaAccountSelector.selectByChildAccountId(childAccountId);
        if (accounts != null && !accounts.isEmpty()) {
            List<String> socialMediaAccountIds = new List<String>();
            for (Social_Media_Account__c account : accounts) {
                socialMediaAccountIds.add(account.Id);
            }
            return socialMediaAccountIds;
        }
        System.debug('No social media accounts found for child account ID: ' + childAccountId);
        return new List<String>();
	} 
}