public without sharing class DataEncryptionQueueable implements queueable{  
    
    private static DataEncryptionQueueSettings__c settings = DataEncryptionQueueSettings__c.getOrgDefaults();
    
    public void execute(QueueableContext context){
        // Abort process if disabled in custom settings - provides an out in cases of infinite queuable loop
        if(!settings.Enabled__c) return;
        Integer batchSize = Integer.valueOf(settings.BatchSize__c);

        // Create a transaction finalizer
        DataEncryptionFinalizer finalizer = new DataEncryptionFinalizer();

        // Attach the transaction finalizer to this queueable
        System.attachFinalizer(finalizer);
        
        // Needed for later to determine if another Queueable needs to be chained
        Integer numberContactsNeedProcessed = (Integer)[SELECT Count(Id) FROM Contact WHERE Account.DataContract__r.Encrypt__c = true
        AND Id NOT IN (SELECT Contact__c FROM EncryptedDocument__c)][0].get('expr0');
        
        List<Contact> contactsToProcess = [SELECT Id FROM Contact WHERE Account.DataContract__r.Encrypt__c = true
            AND Id NOT IN (SELECT Contact__c FROM EncryptedDocument__c) LIMIT :batchSize];
        
        Set<Id> contactIdsToProcess = new Set<Id>();
        for(Contact c: contactsToProcess){
            contactIdsToProcess.add(c.Id);
        }

        // Track the contact Ids in the Finalizer
        finalizer.reportProgress(contactIdsToProcess);

        //Downloads documents from an API, encrypts them, and stores them under the contacts as EncryptedDocument__c records
        DataEncrypter dataEncrypter = new DataEncrypter(contactIdsToProcess);
        dataEncrypter.start();

        if(numberContactsNeedProcessed > batchSize && (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)){
            finalizer.setNeedsEnqueued(true);
            List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE JobType = 'Queueable' 
                AND (Status = 'Queued' OR Status = 'Holding')
                AND ApexClass.Name = 'DataEncryptionQueueable' AND Id != :context.getJobId() LIMIT 1];
        
            if(jobs.size() == 0){
                System.enqueueJob(new DataEncryptionQueueable());
            }
            finalizer.setNeedsEnqueued(false);
        }
    }
}
