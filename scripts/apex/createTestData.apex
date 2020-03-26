List<DataContract__c> dataContracts = new List<DataContract__c>();
for(Integer i = 0; i < 10; i++){
    dataContracts.add(new DataContract__c(Name = 'DataContract'+i));
}
insert dataContracts;

List<Account> accounts = new List<Account>();
for(Integer i = 0; i < 10; i++){
    for(Integer j = 0; j < 10; j++){
        Integer accountNumber = (i*10)+j;
        accounts.add(new Account(Name = 'Account'+accountNumber, 
        	DataContract__c = dataContracts[i].Id));
    }
}
insert accounts;

List<Contact> contacts = new List<Contact>();
for(Account a: accounts){
    for(Integer i = 0; i < 10; i++){
        String uniqueName = a.Name + 'Contact' + i;
        contacts.add(new Contact(LastName = uniqueName, AccountId = a.Id));
    }
}
insert contacts;