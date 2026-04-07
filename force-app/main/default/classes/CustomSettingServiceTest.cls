/**
 * @description Test class for CustomSettingService
 * @author Social Media Manager Team
 * @date 2025-09-01
 */
@isTest
private class CustomSettingServiceTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test custom setting data
        Production_Configuration__c config = new Production_Configuration__c(
            Name = 'Default',
            Facebook_Auth_Provider__c = 'test_facebook_provider_123',
            Google_Auth_Provider__c = 'test_google_provider_456'
        );
        insert config;
    }
    
    /**
     * @description Test retrieving Production Configuration custom setting
     */
    @isTest
    static void testGetProductionConfiguration() {
        Test.startTest();
        Production_Configuration__c config = CustomSettingService.getProductionConfiguration();
        Test.stopTest();
        
        System.assertNotEquals(null, config, 'Production Configuration should not be null');
        System.assertEquals('test_facebook_provider_123', config.Facebook_Auth_Provider__c, 'Facebook provider ID should match');
        System.assertEquals('test_google_provider_456', config.Google_Auth_Provider__c, 'Google provider ID should match');
    }
    
    /**
     * @description Test retrieving Facebook provider ID
     */
    @isTest
    static void testGetFacebookProviderId() {
        Test.startTest();
        String facebookProviderId = CustomSettingService.getFacebookProviderId();
        Test.stopTest();
        
        System.assertEquals('test_facebook_provider_123', facebookProviderId, 'Facebook provider ID should match expected value');
    }
    
    /**
     * @description Test retrieving Google provider ID
     */
    @isTest
    static void testGetGoogleProviderId() {
        Test.startTest();
        String googleProviderId = CustomSettingService.getGoogleProviderId();
        Test.stopTest();
        
        System.assertEquals('test_google_provider_456', googleProviderId, 'Google provider ID should match expected value');
    }
    
    /**
     * @description Test retrieving all provider IDs
     */
    @isTest
    static void testGetAllProviderIds() {
        Test.startTest();
        Map<String, String> providerMap = CustomSettingService.getAllProviderIds();
        Test.stopTest();
        
        System.assertEquals(2, providerMap.size(), 'Should return 2 providers');
        System.assertEquals('test_facebook_provider_123', providerMap.get('Facebook'), 'Facebook provider should be in map');
        System.assertEquals('test_google_provider_456', providerMap.get('Google'), 'Google provider should be in map');
    }
    
    /**
     * @description Test checking if providers are configured
     */
    @isTest
    static void testIsProviderConfigured() {
        Test.startTest();
        Boolean facebookConfigured = CustomSettingService.isProviderConfigured('Facebook');
        Boolean googleConfigured = CustomSettingService.isProviderConfigured('Google');
        Boolean unknownConfigured = CustomSettingService.isProviderConfigured('Twitter');
        Boolean nullConfigured = CustomSettingService.isProviderConfigured(null);
        Boolean emptyConfigured = CustomSettingService.isProviderConfigured('');
        Test.stopTest();
        
        System.assertEquals(true, facebookConfigured, 'Facebook should be configured');
        System.assertEquals(true, googleConfigured, 'Google should be configured');
        System.assertEquals(false, unknownConfigured, 'Unknown provider should not be configured');
        System.assertEquals(false, nullConfigured, 'Null provider should not be configured');
        System.assertEquals(false, emptyConfigured, 'Empty provider should not be configured');
    }
    
    /**
     * @description Test case-insensitive provider checking
     */
    @isTest
    static void testIsProviderConfiguredCaseInsensitive() {
        Test.startTest();
        Boolean facebookLower = CustomSettingService.isProviderConfigured('facebook');
        Boolean googleUpper = CustomSettingService.isProviderConfigured('GOOGLE');
        Boolean facebookMixed = CustomSettingService.isProviderConfigured('FaceBook');
        Test.stopTest();
        
        System.assertEquals(true, facebookLower, 'Facebook (lowercase) should be configured');
        System.assertEquals(true, googleUpper, 'Google (uppercase) should be configured');
        System.assertEquals(true, facebookMixed, 'Facebook (mixed case) should be configured');
    }
    
    /**
     * @description Test provider validation
     */
    @isTest
    static void testValidateProviderConfiguration() {
        Test.startTest();
        List<String> missingProviders = CustomSettingService.validateProviderConfiguration();
        Test.stopTest();
        
        System.assertEquals(0, missingProviders.size(), 'No providers should be missing when all are configured');
    }
    
    /**
     * @description Test getting provider ID by name
     */
    @isTest
    static void testGetProviderIdByName() {
        Test.startTest();
        String facebookId = CustomSettingService.getProviderIdByName('Facebook');
        String googleId = CustomSettingService.getProviderIdByName('google');
        String unknownId = CustomSettingService.getProviderIdByName('Twitter');
        String nullId = CustomSettingService.getProviderIdByName(null);
        Test.stopTest();
        
        System.assertEquals('test_facebook_provider_123', facebookId, 'Facebook provider ID should match');
        System.assertEquals('test_google_provider_456', googleId, 'Google provider ID should match');
        System.assertEquals(null, unknownId, 'Unknown provider should return null');
        System.assertEquals(null, nullId, 'Null provider name should return null');
    }
    
    /**
     * @description Test cache clearing functionality
     */
    @isTest
    static void testClearCache() {
        // First call to load cache
        Production_Configuration__c config1 = CustomSettingService.getProductionConfiguration();
        
        Test.startTest();
        CustomSettingService.clearCache();
        // Second call after clearing cache
        Production_Configuration__c config2 = CustomSettingService.getProductionConfiguration();
        Test.stopTest();
        
        System.assertNotEquals(null, config1, 'First config should not be null');
        System.assertNotEquals(null, config2, 'Second config should not be null');
        // Both should have the same values as they come from the same custom setting
        System.assertEquals(config1.Facebook_Auth_Provider__c, config2.Facebook_Auth_Provider__c, 'Facebook provider should be the same');
    }
    
    /**
     * @description Test behavior when no custom setting exists
     */
    @isTest
    static void testNoCustomSetting() {
        // Delete the custom setting
        delete [SELECT Id FROM Production_Configuration__c];
        
        // Clear cache to ensure fresh retrieval
        CustomSettingService.clearCache();
        
        Test.startTest();
        Production_Configuration__c config = CustomSettingService.getProductionConfiguration();
        String facebookId = CustomSettingService.getFacebookProviderId();
        String googleId = CustomSettingService.getGoogleProviderId();
        List<String> missingProviders = CustomSettingService.validateProviderConfiguration();
        Test.stopTest();
        
        System.assertEquals(null, config, 'Config should be null when no custom setting exists');
        System.assertEquals(null, facebookId, 'Facebook provider ID should be null');
        System.assertEquals(null, googleId, 'Google provider ID should be null');
        System.assertEquals(2, missingProviders.size(), 'Both providers should be missing');
        System.assert(missingProviders.contains('Facebook'), 'Facebook should be in missing providers');
        System.assert(missingProviders.contains('Google'), 'Google should be in missing providers');
    }
    
    /**
     * @description Test with partial configuration (only one provider configured)
     */
    @isTest
    static void testPartialConfiguration() {
        // Update custom setting to have only Facebook configured
        Production_Configuration__c config = Production_Configuration__c.getOrgDefaults();
        config.Google_Auth_Provider__c = null;
        update config;
        
        // Clear cache to ensure fresh retrieval
        CustomSettingService.clearCache();
        
        Test.startTest();
        String facebookId = CustomSettingService.getFacebookProviderId();
        String googleId = CustomSettingService.getGoogleProviderId();
        Map<String, String> providerMap = CustomSettingService.getAllProviderIds();
        List<String> missingProviders = CustomSettingService.validateProviderConfiguration();
        Test.stopTest();
        
        System.assertEquals('test_facebook_provider_123', facebookId, 'Facebook provider should be configured');
        System.assertEquals(null, googleId, 'Google provider should be null');
        System.assertEquals(1, providerMap.size(), 'Only one provider should be in map');
        System.assertEquals(1, missingProviders.size(), 'One provider should be missing');
        System.assert(missingProviders.contains('Google'), 'Google should be in missing providers');
    }
}