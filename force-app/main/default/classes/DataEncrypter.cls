public with sharing class DataEncrypter {
    private Boolean THROW_ERROR = false;
    private Set<Id> contactIdsToProcess;

    public DataEncrypter(Set<Id> contactIdsToProcess) {
        this.contactIdsToProcess = contactIdsToProcess;
    }

    public void start() {
        if(!THROW_ERROR)
        {
            List<EncryptedDocument__c> newEncryptedDocuments = new List<EncryptedDocument__c>();
            for(Id contactId: contactIdsToProcess) {
                Integer randomNumber = Integer.valueof((Math.random() * 10)) + 1;
                for(Integer i = 0; i < randomNumber; i++){
                    newEncryptedDocuments.add(new EncryptedDocument__c(Contact__c = contactId));
                }
            }
            insert newEncryptedDocuments;
        } else {
            for(Integer i = 0; i < 201; i++) {
                List<Account> accounts = [SELECT Name FROM Account LIMIT 1];
            }
        }
    }
}
