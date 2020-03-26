public class AccountUpdateLoggingFinalizer implements Finalizer {
    // Maintain progress
    List<String> accountNames;
    
    public AccountUpdateLoggingFinalizer() {
        accountNames = new List<String>();
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
        
            // Show accounts processed before error occured
            System.debug('Queueable processed the following accounts before failing: ');
            for(String accountName: accountNames) {
                System.debug(accountName);
            }
        }
    }

    public void reportProgress(Account account) {
        accountNames.add(account.Name);
    }
}
