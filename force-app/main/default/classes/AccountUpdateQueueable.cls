public class AccountUpdateQueueable implements Queueable {
    public void execute(QueueableContext context) {
        // Create a transaction finalizer
        AccountUpdateLoggingFinalizer finalizer = new AccountUpdateLoggingFinalizer();

        // Attach the transaction finalizer to this queueable
        System.attachFinalizer(finalizer);

        // Do some partial work
        Account account = new Account();
        account.Name = '1st Account';
        insert account;

        // Update status in finalizer
        finalizer.reportProgress(account);

        // Do some work that results in uncatchable exception
        someWork();

        // Attempt to do some more work
        Account account2 = new Account();
        account2.Name = '1st Account';
        insert account2;

        // Report more progress
        finalizer.reportProgress(account2);
    }

    private void someWork() {
        // Force an uncatchable exception
        for(Integer i = 0; i < 100; i++){
            List<Account> accounts = [SELECT Name FROM Account LIMIT 1];
        }
    }
}
