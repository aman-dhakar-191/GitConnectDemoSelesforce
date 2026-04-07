global class FacebookRegistrationHandler implements Auth.RegistrationHandler {

    global User createUser(Id portalId, Auth.UserData data) {
        User u = new User();
        u.Username = data.username + '@facebookuser.com'; // ensure uniqueness
        u.Email = data.email;
        u.LastName = data.lastName != null ? data.lastName : 'FacebookUser';
        u.Alias = data.username.length() > 4 ? data.username.substring(0, 4) : 'fbU';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';

        // Use a valid profile (update if needed)
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;

        return u;
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        User u = [SELECT Id, Email FROM User WHERE Id = :userId];
        if (data.email != null) {
            u.Email = data.email;
        }
        update u;
    }
}