public without sharing class DataEncryptionQueueable implements queueable{  
    
    private static DataEncryptionQueueSettings__c settings = DataEncryptionQueueSettings__c.getOrgDefaults();
    
    public void execute(QueueableContext context){
        // Abort process if disabled in custom settings - provides an out in cases of infinite queuable loop
        if(!settings.Enabled__c) return;
        
        Integer batchSize = Integer.valueOf(settings.BatchSize__c);
        
        // Needed for later to determine if another Queue needs to be chained
        Integer numberContactsNeedProcessed = (Integer)[SELECT Count(Id) FROM Contact WHERE Account.DataContract__r.Encrypt__c = true
        AND Id NOT IN (SELECT Contact__c FROM EncryptedDocument__c)][0].get('expr0');
        
        List<Contact> contactsToProcess = [SELECT Id FROM Contact WHERE Account.DataContract__r.Encrypt__c = true
            AND Id NOT IN (SELECT Contact__c FROM EncryptedDocument__c) LIMIT :batchSize];
        
        Set<Id> contactIdsToProcess = new Set<Id>();
        for(Contact c: contactsToProcess){
            contactIdsToProcess.add(c.Id);
        }

        try {
            //Downloads documents from an API, encrypts them, and stores them under the contact as EncryptedDocument__c records
            DataEncrypter dataEncrypter = new DataEncrypter(contactIdsToProcess);
            dataEncrypter.start();
        } catch(Exception error) {
            System.debug('DataEncryptionQueueable.execute() failed for contacts with id: ' + contactIdsToProcess 
                + '\nJob Id: ' + context.getJobId());
        }

        if(numberContactsNeedProcessed > batchSize && (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)){
            try {
                enqueueNewJob(context.getJobId());
            } catch(Exception error) {
                retryQueueInFuture(context.getJobId(), batchSize, numberContactsNeedProcessed);
            }
        }
    }

    public static void enqueueNewJob(Id currentJobId){
        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE JobType = 'Queueable' 
            AND (Status = 'Queued' OR Status = 'Holding')
            AND ApexClass.Name = 'DataEncryptionQueueable' AND Id != :currentJobId LIMIT 1];

        if(jobs.size() == 0){
            System.enqueueJob(new DataEncryptionQueueable());
        }
    }

    @future
    private static void retryQueueInFuture(Id currentJobId, Integer batchSize, Integer numberContactsNeedProcessed){
        if(!settings.Enabled__c) return;
        try {
            if(Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0){
                enqueueNewJob(currentJobId);
            }
        } catch(Exception error) {
            System.debug('DataEncryptionQueueable.retryQueueInFuture() failed to queue'
                + '\nJob Id: ' + currentJobId 
                + '\nBatch size ' + batchSize 
                + '\nNumber of contacts that need processed: ' + numberContactsNeedProcessed);
        }
    }
}
