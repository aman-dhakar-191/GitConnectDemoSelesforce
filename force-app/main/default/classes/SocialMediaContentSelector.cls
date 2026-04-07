public with sharing class SocialMediaContentSelector {
    public static String fields = 'Id, Name, Platform__c';
    public static List<Social_Media_Content__c> selectByPlatform(String platform) {
        String query = 'SELECT ' + fields + ' FROM Social_Media_Content__c WHERE Platform__c = :platform';
        return Database.query(query, AccessLevel.USER_MODE);
    }
}