@isTest
private class ContactFormTaskTest {
    static testMethod void myUnitTest() {

     Lead l = new Lead (LastName = 'Test', Company = 'Test');
     insert l;
     
     Account a = new Account (Name='Test Account');
     Insert a;
     
     Contact c = new Contact (LastName = 'Test', Accountid = a.id);
     Insert c;
     
     WebActivity__c wa = new WebActivity__c(contact__c = c.id, lead__c = l.id, recordtypeid = '0126000000016NG');
     Insert wa;
     Update wa;
     
     Task tl = new Task (whoid = l.id);
     
     Task tc = new Task (whatid = wa.id, whoid = c.id);
     
     test.startTest();
    
     Insert tl;
     Insert tc;
       
     test.stopTest();
       
    }
}

// written by Laura J. McKevitt 8.25.11