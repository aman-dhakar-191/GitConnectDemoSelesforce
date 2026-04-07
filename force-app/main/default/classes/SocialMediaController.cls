public with sharing class SocialMediaController {
    @AuraEnabled
    public static void runSocialMediaSync() {
        System.debug('=== runSocialMediaSync started ===');

        FacebookService facebookService = new FacebookService();
        YoutubeService youtubeService = new YoutubeService();
        MapService mapService = new MapService();

        List<Social_Media_Account__c> socialMediaAccounts = [
            SELECT Id, Platform_Account_ID__c, Name
            FROM Social_Media_Account__c
            WHERE Name IN ('Conscendo Hyderabad Facebook', 'Conscendo Hyderabad Youtube', 'Conscendo Hyderabad Map')
        ];

        System.debug('=== Fetched Social Media Accounts ===');
        for (Social_Media_Account__c account : socialMediaAccounts) {
            System.debug('Account Name: ' + account.Name + ', ID: ' + account.Id + ', Platform ID: ' + account.Platform_Account_ID__c);

            if (account.Name == 'Conscendo Hyderabad Facebook') {
                System.debug('Invoking Facebook sync...');
                facebookService.syncComments(account.Id, account.Platform_Account_ID__c);
                System.debug('Facebook sync completed');
            }
            else if (account.Name == 'Conscendo Hyderabad Youtube') {
                System.debug('Invoking YouTube sync...');
                youtubeService.syncComments(account.Id, account.Platform_Account_ID__c);
                System.debug('YouTube sync completed');
            }
            else if (account.Name == 'Conscendo Hyderabad Map') {
                System.debug('Invoking Map sync...');
                mapService.syncMapReviews(account.Id, account.Platform_Account_ID__c);
                System.debug('Map sync completed');
            } else {
                System.debug('No matching sync service for account: ' + account.Name);
            }
        }

        System.debug('=== runSocialMediaSync completed ===');
    }
}