public class DataEncryptionFinalizer implements Finalizer {
    // Maintain progress
    private List<Id> contactIds;
    private Boolean needsEnqueued = false;
    
    public DataEncryptionFinalizer() {
        contactIds = new List<Id>();
    }

    public void execute(FinalizerContext context) {
        Id queueableJobId = context.getAsyncApexJobId();
        System.debug('Executing Finalizer for Queuable Job Id: ' + queueableJobId);
        if (context.getAsyncApexJobResult() == FinalizerParentJobResult.SUCCESS) {
            // Queueable executed successfully
            System.debug('Queueable job completed successfully. Id: ' + queueableJobId);
        } else {
            // Queueable failed additional info
            System.debug('Queueable job failed. Id: ' + queueableJobId);
            System.debug('Quaueable Exception: ' + context.getAsyncApexJobException().getMessage());
        
            // Show contacts processed before error occurred
            System.debug('Queueable was processing the following contacts before failing: ');
            for(String contactId: contactIds) {
                System.debug(contactId);
            }
        }

        if(needsEnqueued) {
            enqueueNewJob(queueableJobId);
        }
    }

    public static void enqueueNewJob(Id currentJobId){
        // Query for existing jobs
        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE JobType = 'Queueable' 
            AND (Status = 'Queued' OR Status = 'Holding')
            AND ApexClass.Name = 'DataEncryptionQueueable' AND Id != :currentJobId LIMIT 1];

        // Only enqueue the next job if there isn't one
        if(jobs.size() == 0){
            System.enqueueJob(new DataEncryptionQueueable());
        }
    }

    public void reportProgress(Set<Id> contactIds) {
        contactIds.addAll(contactIds);
    }

    public void setNeedsEnqueued(Boolean needsEnqueued) {
        this.needsEnqueued = needsEnqueued;
    }
}