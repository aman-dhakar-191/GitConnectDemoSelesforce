public with sharing class AccountContactsController {
    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getAccountsWithContacts() {
        List<Account> accounts = [SELECT Id, Name FROM Account ORDER BY Name];
        Map<Id, List<Contact>> accountContactsMap = new Map<Id, List<Contact>>();
        for (Contact c : [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact WHERE AccountId IN :accounts]) {
            if (!accountContactsMap.containsKey(c.AccountId)) {
                accountContactsMap.put(c.AccountId, new List<Contact>());
            }
            accountContactsMap.get(c.AccountId).add(c);
        }
        List<AccountWrapper> result = new List<AccountWrapper>();
        for (Account acc : accounts) {
            result.add(new AccountWrapper(acc, accountContactsMap.get(acc.Id)));
        }
        return result;
    }
    public class AccountWrapper {
        @AuraEnabled public Account account;
        @AuraEnabled public List<Contact> contacts;
        public AccountWrapper(Account account, List<Contact> contacts) {
            this.account = account;
            this.contacts = contacts == null ? new List<Contact>() : contacts;
        }
    }
}