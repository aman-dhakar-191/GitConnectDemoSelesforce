global class SocialMediaContentSchedule Implements Schedulable {

    global void execute(SchedulableContext sc) {
        FacebookService facebookService = new FacebookService();
        YoutubeService youtubeService = new YoutubeService();
        MapService mapService = new MapService();

        List<Social_Media_Account__c> socialMediaAccounts = [SELECT Id, Platform_Account_ID__c, Name FROM Social_Media_Account__c WHERE Name IN ('Conscendo Hyderabad Facebook', 'Conscendo Hyderabad Youtube', 'Conscendo Hyderabad Map')];

        for( Social_Media_Account__c account : socialMediaAccounts ) {
            if (account.Name == 'Conscendo Hyderabad Facebook') {
                facebookService.syncComments(account.Id, account.Platform_Account_ID__c);
            }
            else if (account.Name == 'Conscendo Hyderabad Youtube') {
                youtubeService.syncComments(account.Id, account.Platform_Account_ID__c);
            }
            else if (account.Name == 'Conscendo Hyderabad Map') {
                mapService.syncMapReviews(account.Id, account.Platform_Account_ID__c);
            }
        }
    }
}