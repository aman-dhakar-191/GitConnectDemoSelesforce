public with sharing class SocialMediaUtility {
    
    public static DateTime convertISO8601(String iso8601_ts) {
        DateTime dt = (DateTime) JSON.deserialize('"' + iso8601_ts + '"', DateTime.class);
        return DateTime.newInstance(dt.getTime());
    }
    
    public static String convertToSalesforceFormat(String iso8601_ts) {
        DateTime dt = convertISO8601(iso8601_ts);
        return dt.format('yyyy-MM-dd HH:mm:ss');
    }
    
    // Method to convert ISO8601 to Salesforce DateTime field compatible format
    public static String convertToSalesforceFieldFormat(String iso8601_ts) {
        DateTime dt = convertISO8601(iso8601_ts);
        return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }
    
    // Method to parse Salesforce formatted string back to DateTime
    public static DateTime parseSalesforceFormat(String salesforceFormat) {
        try {
            // Handle different possible formats
            if (salesforceFormat.contains('T')) {
                // ISO format with T separator
                return (DateTime) JSON.deserialize('"' + salesforceFormat + '"', DateTime.class);
            } else {
                // Space-separated format - need to parse manually
                String[] parts = salesforceFormat.split(' ');
                if (parts.size() == 2) {
                    String datePart = parts[0];
                    String timePart = parts[1];
                    
                    String[] dateParts = datePart.split('-');
                    String[] timeParts = timePart.split(':');
                    
                    Integer year = Integer.valueOf(dateParts[0]);
                    Integer month = Integer.valueOf(dateParts[1]);
                    Integer day = Integer.valueOf(dateParts[2]);
                    Integer hour = Integer.valueOf(timeParts[0]);
                    Integer minute = Integer.valueOf(timeParts[1]);
                    Integer second = Integer.valueOf(timeParts[2]);
                    
                    return DateTime.newInstance(year, month, day, hour, minute, second);
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing datetime: ' + e.getMessage());
        }
        return null;
    }
    
    // Alternative method that returns different Salesforce-friendly formats
    public static String convertToSalesforceFormat(String iso8601_ts, String formatType) {
        DateTime dt = convertISO8601(iso8601_ts);
        
        switch on formatType.toLowerCase() {
            when 'standard' {
                return dt.format('yyyy-MM-dd HH:mm:ss');
            }
            when 'short' {
                return dt.format('MM/dd/yyyy HH:mm');
            }
            when 'long' {
                return dt.format('EEEE, MMMM dd, yyyy HH:mm:ss');
            }
            when 'iso' {
                return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
            when else {
                return dt.format('yyyy-MM-dd HH:mm:ss');
            }
        }
    }
}