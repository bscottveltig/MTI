@isTest
private class TestContactClassificationContExt
{
    static final String HBS_PROFILE_NAME = 'AMCOL HBS Sales User';
    static final String TYPE = 'Test Type';
    static final String PRODUCT_INTEREST = 'Test Product Interest';
    static final Integer NUM_OF_ACCT_CLASSIFICATIONS = 3;

    static Id contactRTId;
    static Id contactClassificationRTId;
    static Account testAccount;
    static Contact testContact;
    static ContactClassification__c testContactClassification;
    static List<AccountClassification__c> testAccountClassifications;

    static
    {
        contactRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'HBSContact' ].Id;
        contactClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'ContactClassification__c' AND DeveloperName = 'HBSContactClassification' ].Id;
        ProfileToContactRecType__c csTwo = TestingUtils.createProfileToContactRecTypeCS( HBS_PROFILE_NAME, contactRTId, contactClassificationRTId, true );
    }

    static void setup()
    {
        testAccount = TestingUtils.createTestAccount( 'Test Account', true );
        testContact = TestingUtils.createContacts( 1, null, false )[0];
        testContactClassification = TestingUtils.createContactClassification( 1, TYPE, PRODUCT_INTEREST, false )[0];
    }

    static testMethod void testProfileNameToContactAndClassificationRT()
    {
        setup();

        ContactClassificationContExt controller = new ContactClassificationContExt( new ApexPages.Standardcontroller( testContact ) );

        Test.startTest();

            System.assertEquals( contactRTId, controller.profileNameToContactRT.get( HBS_PROFILE_NAME ), 'With HBS Profile Name, HBS record type shoul be returned for Contact' );
            System.assertEquals( contactClassificationRTId, controller.profileNameToClassificationRT.get( HBS_PROFILE_NAME ), 'With HBS Profile Name, HBS record type shoul be returned for Contact Classification' );

        Test.stopTest();
    }

    static void setupWithAccountClassifications( Integer numAccountClassifications )
    {
        List<RecordType> acctRTs = [ SELECT Id, Name FROM RecordType WHERE SObjectType = 'AccountClassification__c' ];
        Set<Id> accountClassificationRTIds = new Set<Id>();
        for( RecordType rt : acctRTs )
        {
            accountClassificationRTIds.add( rt.Id );
        }
        List<Id> acRTIds = new List<Id>( accountClassificationRTIds );

        testAccount = TestingUtils.createTestAccount( 'Test Acct', false );
        testAccount.BillingStreet = '123 Test Street';
        testAccount.BillingCity = 'New York';
        testAccount.BillingState = 'NY';
        testAccount.BillingPostalCode = '10010';
        testAccount.BillingCountry = 'USA';
        insert testAccount;

        testContact = TestingUtils.createContacts( 1, null, false )[0];
        testAccountClassifications = TestingUtils.createAccountClassification( numAccountClassifications, 'Test Type', 'Test Subtype', 'Test STDetail', 'Test Territory', 'Test IM', 'Test Region', 'Test PI', false );
        Integer sizeOfAccountClassificationRTs = accountClassificationRTIds.size();
        for( Integer i = 0; i < numAccountClassifications; i++ )
        {
            testAccountClassifications[i].Account__c = testAccount.Id;
            testAccountClassifications[i].RecordTypeId = acRTIds[ Math.mod( i, sizeOfAccountClassificationRTs ) ];
        }
        insert testAccountClassifications;

        testContactClassification = TestingUtils.createContactClassification( 1, TYPE, PRODUCT_INTEREST, false )[0];
    }

    static testMethod void testController_FromAccount()
    {
        setupWithAccountClassifications( NUM_OF_ACCT_CLASSIFICATIONS );

        PageReference currentPage = Page.ContactClassification;
        Test.setCurrentPage( currentPage );
        ApexPages.currentPage().getParameters().put( 'accId', testAccount.Id );

        ApexPages.StandardController sc = new ApexPages.Standardcontroller( testContact );

        Test.startTest();

            ContactClassificationContExt controller = new ContactClassificationContExt( sc );

        Test.stopTest();

        System.assertEquals( controller.ownerId, controller.contact.OwnerId, 'Owner on the contact should be set to the running user' );
        System.assertEquals( controller.contactRTId, controller.contact.RecordTypeId, 'Record Type should be set to the running user\'s Record Type ' );

        Account parentAccount = [ SELECT Id, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet FROM Account Where Id = :testAccount.Id ];
        System.assertEquals( parentAccount.Id, controller.contact.AccountId, 'The linkage between Contact and Account should be formed' );
        System.assertEquals( parentAccount.BillingStreet, controller.contact.MailingStreet, 'The Mailing Street on Contact should be copied over from linked Account' );
        System.assertEquals( parentAccount.BillingCity, controller.contact.MailingCity, 'The Mailing City on Contact should be copied over from linked Account' );
        System.assertEquals( parentAccount.BillingState, controller.contact.MailingState, 'The Mailing State on Contact should be copied over from linked Account' );
        System.assertEquals( parentAccount.BillingPostalCode, controller.contact.MailingPostalCode, 'The Mailing Postal Code on Contact should be copied over from linked Account' );
        System.assertEquals( parentAccount.BillingCountry, controller.contact.MailingCountry, 'The Mailing Country on Contact should be copied over from linked Account' );

        Set<Id> expectedValues = new Set<Id>();
        Set<String> expectedLabels = new Set<String>();
        for( AccountClassification__c ac : [ SELECT Id, RecordType.Name, Type__c FROM AccountClassification__c WHERE Id IN :testAccountClassifications ] )
        {
            expectedValues.add( ac.Id );
            expectedLabels.add( ac.RecordType.Name + ' - ' + ac.Type__c );
        }

        System.assertEquals( NUM_OF_ACCT_CLASSIFICATIONS, controller.accountClassifications.size(), 'All the Account Classifications under Account should be returned' );
        for( SelectOption option : controller.accountClassifications )
        {
            System.assert( expectedValues.contains( option.getValue() ), 'The options should contain all the account classifications under an account' );
            System.assert( expectedLabels.contains( option.getLabel() ), 'The options should contain every account classification\'s record type name to type' );
        }
    }

    static testMethod void testController_FreshNewContact()
    {
        setupWithAccountClassifications( NUM_OF_ACCT_CLASSIFICATIONS );

        PageReference currentPage = Page.ContactClassification;
        Test.setCurrentPage( currentPage );

        ApexPages.StandardController sc = new ApexPages.Standardcontroller( testContact );

        Test.startTest();

            ContactClassificationContExt controller = new ContactClassificationContExt( sc );

        Test.stopTest();

        System.assertEquals( controller.ownerId, controller.contact.OwnerId, 'Owner on the contact should be set to the running user' );
        System.assertEquals( controller.contactRTId, controller.contact.RecordTypeId, 'Record Type should be set to the running user\'s Record Type ' );
        System.assertEquals( null, controller.contact.AccountId, 'There should not be an related Account' );
        System.assertEquals( null, controller.contact.MailingStreet, 'There should not be Mailing Street populated' );
        System.assertEquals( null, controller.contact.MailingCity, 'There should not be Mailing City populated' );
        System.assertEquals( null, controller.contact.MailingState, 'There should not be Mailing State populated' );
        System.assertEquals( null, controller.contact.MailingPostalCode, 'There should not be Mailing Postal Code populated' );
        System.assertEquals( null, controller.contact.MailingCountry, 'There should not be Mailing Country populated' );
        System.assert( controller.accountClassifications.isEmpty(), 'There should not be any Account Classification Picklist generated' );
    }

    static testMethod void testSave_WithAccount_No_SelectedAccountClassificationId()
    {
        setupWithAccountClassifications( NUM_OF_ACCT_CLASSIFICATIONS );
        Id selectedACId = testAccountClassifications[0].Id;

        PageReference currentPage = Page.ContactClassification;
        Test.setCurrentPage( currentPage );
        ApexPages.StandardController sc = new ApexPages.Standardcontroller( testContact );
        Contact aContact = (Contact)sc.getRecord();
        aContact.AccountId = testAccount.Id;

        ApexPages.currentPage().getParameters().put( 'accId', aContact.AccountId );

        ContactClassificationContExt controller = new ContactClassificationContExt( sc );
        controller.contact = aContact;
        controller.contactClassification = testContactClassification;
        controller.selectedAccountClassificationId = null;

        Test.startTest();

            PageReference pgReference = controller.save();

        Test.stopTest();

        System.assertEquals( null, pgReference, 'When no selectedAccountClassificationId is selected, we expect to stay on the page' );
        System.assertEquals( true, TestingUtils.pageMessagesContains( Label.Required_Account_Classification_Error ), 'We expect an error to be displayed on the page.  And it should state the following.');
    }

    static testMethod void testSave_WithAccount()
    {
        setupWithAccountClassifications( NUM_OF_ACCT_CLASSIFICATIONS );
        Id selectedACId = testAccountClassifications[0].Id;

        PageReference currentPage = Page.ContactClassification;
        Test.setCurrentPage( currentPage );
        ApexPages.StandardController sc = new ApexPages.Standardcontroller( testContact );
        Contact aContact = (Contact)sc.getRecord();
        aContact.AccountId = testAccount.Id;

        ApexPages.currentPage().getParameters().put( 'accId', aContact.AccountId );

        ContactClassificationContExt controller = new ContactClassificationContExt( sc );
        controller.contact = aContact;
        controller.contactClassification = testContactClassification;
        controller.selectedAccountClassificationId = selectedACId;

        Test.startTest();

            PageReference pgReference = controller.save();

        Test.stopTest();

        System.assert( pgReference.getUrl().endsWith( ''+testContact.Id ), 'After DML, User should be redirected to newly created Contact\'s page' );

        List<Contact> contactsAfterSave = [ SELECT Id, AccountId FROM Contact ];
        System.assertEquals( 1, contactsAfterSave.size(), 'After Save, there should be Contact inserted' );
        System.assertEquals( testAccount.Id, contactsAfterSave[0].AccountId, 'The relationship between Contact and Account should be created' );

        List<ContactClassification__c> contactClassificationAfterSave = [ SELECT Id, Contact__c, Type__c, ProductInterests__c, Account_Classification__c FROM ContactClassification__c ];
        System.assertEquals( 1, contactClassificationAfterSave.size(), 'After Save, Contact Classification record should have been created' );
        System.assertEquals( testContact.Id, contactClassificationAfterSave[0].Contact__c, 'The relationship between Contact and Classifcation should be created' );
        System.assertEquals( TYPE, contactClassificationAfterSave[0].Type__c, 'The type should be populated' );
        System.assertEquals( PRODUCT_INTEREST, contactClassificationAfterSave[0].ProductInterests__c, 'The product interest should be populated' );
        System.assertEquals( selectedACId, contactClassificationAfterSave[0].Account_Classification__c, 'The Account Classification lookup should be populated to selected Account Classification' );
    }

    static testMethod void testSaveAndNew()
    {
        setup();
        testContact.AccountId = testAccount.Id;

        List<Contact> contactsBeforeSaveAndNew = [ SELECT Id FROM Contact ];
        System.assert( contactsBeforeSaveAndNew.isEmpty(), 'Before Save & New, there should not be any existing Contacts' );

        List<ContactClassification__c> contactClassificationsBeforeSaveAndNew = [ SELECT Id FROM ContactClassification__c ];
        System.assert( contactClassificationsBeforeSaveAndNew.isEmpty(), 'Before Save & New, there should not be any existing Contact Classifications' );

        ContactClassificationContExt controller = new ContactClassificationContExt( new ApexPages.Standardcontroller( testContact ) );
        controller.contact = testContact;
        controller.contactClassification = testContactClassification;

        Test.startTest();

            PageReference pgReference = controller.saveAndNew();

        Test.stopTest();

        System.assert( pgReference.getUrl().endsWith( controller.SAVE_AND_NEW_URL ), 'Upon Save&New, User should be redirected to Contact Classification Page again' );

        List<Contact> contactsAfterSaveAndNew = [ SELECT Id, AccountId FROM Contact ];
        System.assertEquals( 1, contactsAfterSaveAndNew.size(), 'After Save, there should be Contact inserted' );
        System.assertEquals( testAccount.Id, contactsAfterSaveAndNew[0].AccountId, 'The relationship between Contact and Account should be created' );

        List<ContactClassification__c> contactClassificationAfterSaveAndNew = [ SELECT Id, Contact__c, Type__c, ProductInterests__c FROM ContactClassification__c ];
        System.assertEquals( 1, contactClassificationAfterSaveAndNew.size(), 'After Save & New, Contact Classification record should have been created' );
        System.assertEquals( testContact.Id, contactClassificationAfterSaveAndNew[0].Contact__c, 'The relationship between Contact and Classifcation should be created' );
        System.assertEquals( TYPE, contactClassificationAfterSaveAndNew[0].Type__c, 'The type should be populated' );
        System.assertEquals( PRODUCT_INTEREST, contactClassificationAfterSaveAndNew[0].ProductInterests__c, 'The product interest should be populated' );
    }

    static testMethod void testCancel()
    {
        setup();

        ContactClassificationContExt controller = new ContactClassificationContExt( new ApexPages.Standardcontroller( testContact ) );

        Test.startTest();

            PageReference pgReference = controller.cancel();

        Test.stopTest();

        System.assert( pgReference.getUrl().endsWith( controller.CONTACT_HOME_URL ), 'Upon Cancel, User should be redirected to Contact home page' );
    }

    static testMethod void testProperty()
    {
        setup();

        ContactClassificationContExt controller = new ContactClassificationContExt( new ApexPages.Standardcontroller( testContact ) );
        controller.refresh();
        controller.populateAccountClassifications();
        system.assertEquals(true, controller.isProfilesToEditRT);
    }
}