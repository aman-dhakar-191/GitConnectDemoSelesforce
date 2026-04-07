public with sharing class SocialMediaAccountSelector {
    public static String fields = 'Id, Name, Platform__c, Platform_Account_ID__c';
    public SocialMediaAccountSelector(){
        // validation the fields in object
        // Validate that all fields exist on the Social_Media_Account__c object
        List<String> fieldList = fields.replaceAll('\\s+', '').split(',');
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Social_Media_Account__c').getDescribe().fields.getMap();
        for (String fieldName : fieldList) {
            if (!fieldMap.containsKey(fieldName)) {
                throw new AuraHandledException('Field "' + fieldName + '" does not exist on Social_Media_Account__c.');
            }
        }

    }

    public static List<Social_Media_Account__c> selectByAccountName(String accountName) {
        String query = 'SELECT ' + fields + ' FROM Social_Media_Account__c WHERE Name = :accountName';
        return Database.query(query, AccessLevel.USER_MODE);
    }
    public static List<Social_Media_Account__c> selectAll() {
        String query = 'SELECT ' + fields + ' FROM Social_Media_Account__c';
        return Database.query(query, AccessLevel.USER_MODE);
    }

	public static List<Social_Media_Account__c> selectByChildAccountId(String childAccountId){
        String query = 'SELECT ' + fields + ' FROM Social_Media_Account__c WHERE Account__c = :childAccountId';
		return Database.query(query, AccessLevel.USER_MODE);
	} 
}