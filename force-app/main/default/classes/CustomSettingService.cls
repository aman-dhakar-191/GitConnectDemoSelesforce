/**
 * @description Service class to manage and retrieve provider configurations from Custom Settings
 * @author Social Media Manager Team
 * @date 2025-09-01
 */
public with sharing class CustomSettingService {
    
    /**
     * @description Cache for custom setting instance to avoid repeated SOQL queries
     */
    private static Production_Configuration__c cachedConfig;
    
    /**
     * @description Retrieves the Production Configuration custom setting instance
     * @return Production_Configuration__c instance or null if not found
     */
    public static Production_Configuration__c getProductionConfiguration() {
        if (cachedConfig == null) {
            try {
                cachedConfig = Production_Configuration__c.getOrgDefaults();
                if (cachedConfig == null) {
                    // Log that no configuration was found
                    System.debug(LoggingLevel.WARN, 'No Production Configuration custom setting found. Please create the default configuration.');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error retrieving Production Configuration: ' + e.getMessage());
                return null;
            }
        }
        return cachedConfig;
    }
    
    /**
     * @description Retrieves the Facebook Authentication Provider ID from custom setting
     * @return String Facebook provider ID or null if not configured
     */
    public static String getFacebookProviderId() {
        Production_Configuration__c config = getProductionConfiguration();
        if (config != null && String.isNotBlank(config.Facebook_Auth_Provider__c)) {
            return config.Facebook_Auth_Provider__c;
        }
        System.debug(LoggingLevel.WARN, 'Facebook Auth Provider not configured in Production Configuration custom setting');
        return null;
    }
    
    /**
     * @description Retrieves the Google Authentication Provider ID from custom setting
     * @return String Google provider ID or null if not configured
     */
    public static String getGoogleProviderId() {
        Production_Configuration__c config = getProductionConfiguration();
        if (config != null && String.isNotBlank(config.Google_Auth_Provider__c)) {
            return config.Google_Auth_Provider__c;
        }
        System.debug(LoggingLevel.WARN, 'Google Auth Provider not configured in Production Configuration custom setting');
        return null;
    }
    
    /**
     * @description Retrieves all configured provider IDs as a map
     * @return Map<String, String> Provider name to provider ID mapping
     */
    public static Map<String, String> getAllProviderIds() {
        Map<String, String> providerMap = new Map<String, String>();
        
        String facebookProviderId = getFacebookProviderId();
        String googleProviderId = getGoogleProviderId();
        
        if (String.isNotBlank(facebookProviderId)) {
            providerMap.put('Facebook', facebookProviderId);
        }
        
        if (String.isNotBlank(googleProviderId)) {
            providerMap.put('Google', googleProviderId);
        }
        
        return providerMap;
    }
    
    /**
     * @description Checks if a specific provider is configured
     * @param providerName Name of the provider (Facebook, Google)
     * @return Boolean true if provider is configured, false otherwise
     */
    public static Boolean isProviderConfigured(String providerName) {
        if (String.isBlank(providerName)) {
            return false;
        }
        
        switch on providerName.toLowerCase() {
            when 'facebook' {
                return String.isNotBlank(getFacebookProviderId());
            }
            when 'google' {
                return String.isNotBlank(getGoogleProviderId());
            }
            when else {
                System.debug(LoggingLevel.WARN, 'Unknown provider name: ' + providerName);
                return false;
            }
        }
    }
    
    /**
     * @description Clears the cached configuration (useful for testing or when settings change)
     */
    public static void clearCache() {
        cachedConfig = null;
    }
    
    /**
     * @description Validates that all required providers are configured
     * @return List<String> List of missing provider configurations
     */
    public static List<String> validateProviderConfiguration() {
        List<String> missingProviders = new List<String>();
        
        if (String.isBlank(getFacebookProviderId())) {
            missingProviders.add('Facebook');
        }
        
        if (String.isBlank(getGoogleProviderId())) {
            missingProviders.add('Google');
        }
        
        return missingProviders;
    }
    
    /**
     * @description Gets provider ID by provider name (case-insensitive)
     * @param providerName Name of the provider
     * @return String Provider ID or null if not found
     */
    public static String getProviderIdByName(String providerName) {
        if (String.isBlank(providerName)) {
            return null;
        }
        
        switch on providerName.toLowerCase() {
            when 'facebook' {
                return getFacebookProviderId();
            }
            when 'google' {
                return getGoogleProviderId();
            }
            when else {
                System.debug(LoggingLevel.WARN, 'Unknown provider name: ' + providerName);
                return null;
            }
        }
    }
}