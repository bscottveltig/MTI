@isTest
private class TestContactClassificationTrigger
{
	static final String HBS_PROFILE_NAME = 'AMCOL HBS Sales User';
	static final String BMG_PROFILE_NAME = 'CETCO BMG Regional Sales User';

	static final String TYPE = 'Test Type';
	static final String SUB_TYPE = 'Test SubType';
	static final String SUB_TYPE_DETAIL = 'Test SubType Detail';
	static final String TERRITORY = 'Test Territory';
	static final String INDUSTRY_MARKET = 'Test Industry Market';
	static final String REGION = 'Test Region';
	static final String PRODUCT_INTEREST = 'Test Product Interest';

	static Id contactClassificationRTId;
	static AccountClassification__c acctClassification;
	static Contact testContact;

	static List<AccountClassification__c> testAcctClassifications;
	static List<Contact> testContacts;

	static void setup()
	{
		Id acctRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'HBSAccount' ].Id;
		Id acctClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'AccountClassification__c' AND DeveloperName = 'HBSAccountClassification' ].Id;
		ProfileToAcctRecType__c csOne = TestingUtils.createProfileToAcctRecTypeCS( HBS_PROFILE_NAME, acctRTId, acctClassificationRTId, true );

		Id contactRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'HBSContact' ].Id;
		contactClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'ContactClassification__c' AND DeveloperName = 'HBSContactClassification' ].Id;
		ProfileToContactRecType__c csTwo = TestingUtils.createProfileToContactRecTypeCS( HBS_PROFILE_NAME, contactRTId, contactClassificationRTId, true );

		Account testAccount = TestingUtils.createTestAccount( 'Test Acct', false );
		testAccount.RecordTypeId = acctRTId;
		insert testAccount;

		acctClassification = TestingUtils.createAccountClassification( 1, TYPE, SUB_TYPE, SUB_TYPE_DETAIL, TERRITORY, INDUSTRY_MARKET, REGION, PRODUCT_INTEREST, false )[0];
		acctClassification.Account__c = testAccount.Id;
		acctClassification.RecordTypeId = acctClassificationRTId;
		insert acctClassification;

		testContact = TestingUtils.createContacts( 1, testAccount.Id, false )[0];
		testContact.RecordTypeId = contactRTId;
		insert testContact;
	}

	static testMethod void testContactClassificationInsert_Single()
	{
		setup();
		ContactClassification__c testContactClassification = TestingUtils.createContactClassification( 1, TYPE, PRODUCT_INTEREST, false )[0];
		testContactClassification.Contact__c = testContact.Id;
		testContactClassification.RecordTypeId = contactClassificationRTId;

		Test.startTest();

			insert testContactClassification;

		Test.stopTest();

		List<ContactClassification__c> actualContactClassifications = [ SELECT Id, Account_Classification__c FROM ContactClassification__c ];
		System.assertEquals( 1, actualContactClassifications.size(), 'There should be one contact classification returned' );
		System.assertEquals( acctClassification.Id, actualContactClassifications[0].Account_Classification__c, 'Account Classification lookup should be tied to related Account Classification' );
	}

	static void setupBulk()
	{
		Id acctRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'HBSAccount' ].Id;
		Id acctClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'AccountClassification__c' AND DeveloperName = 'HBSAccountClassification' ].Id;
		ProfileToAcctRecType__c csOne = TestingUtils.createProfileToAcctRecTypeCS( HBS_PROFILE_NAME, acctRTId, acctClassificationRTId, true );

		Id contactRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'HBSContact' ].Id;
		contactClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'ContactClassification__c' AND DeveloperName = 'HBSContactClassification' ].Id;
		ProfileToContactRecType__c csTwo = TestingUtils.createProfileToContactRecTypeCS( HBS_PROFILE_NAME, contactRTId, contactClassificationRTId, true );

		Account testAccount1 = TestingUtils.createTestAccount( 'Test Acct 1', false );
		testAccount1.RecordTypeId = acctRTId;
		Account testAccount2 = TestingUtils.createTestAccount( 'Test Acct 2', false );
		testAccount2.RecordTypeId = acctRTId;
		insert new List<Account> { testAccount1, testAccount2 };

		testAcctClassifications = TestingUtils.createAccountClassification( 2, TYPE, SUB_TYPE, SUB_TYPE_DETAIL, TERRITORY, INDUSTRY_MARKET, REGION, PRODUCT_INTEREST, false );
		testAcctClassifications[0].Account__c = testAccount1.Id;
		testAcctClassifications[0].RecordTypeId = acctClassificationRTId;
		testAcctClassifications[1].Account__c = testAccount2.Id;
		testAcctClassifications[1].RecordTypeId = acctClassificationRTId;
		insert testAcctClassifications;

		testContacts = TestingUtils.createContacts( 2, null, false );
		testContacts[0].AccountId = testAccount1.Id;
		testContacts[0].RecordTypeId = contactRTId;
		testContacts[1].AccountId = testAccount2.Id;
		testContacts[1].RecordTypeId = contactRTId;
		insert testContacts;
	}

	static testMethod void testContactClassificationInsert_Bulk()
	{
		setupBulk();

		List<ContactClassification__c> testContactClassifications = TestingUtils.createContactClassification( 2, TYPE, PRODUCT_INTEREST, false );
		testContactClassifications[0].Contact__c = testContacts[0].Id;
		testContactClassifications[0].RecordTypeId = contactClassificationRTId;
		testContactClassifications[1].Contact__c = testContacts[1].Id;
		testContactClassifications[1].RecordTypeId = contactClassificationRTId;

		Test.startTest();

			insert testContactClassifications;

		Test.stopTest();

		Set<Id> acctClassificationIds = new Set<Id>();
		for( AccountClassification__c acctClass : testAcctClassifications )
		{
			acctClassificationIds.add( acctClass.Id );
		}

		List<ContactClassification__c> actualContactClassifications = [ SELECT Id, Account_Classification__c FROM ContactClassification__c ];
		System.assertEquals( 2, actualContactClassifications.size(), 'Every contact classifications should be returned' );
		for( ContactClassification__c aCC : actualContactClassifications )
		{
			System.assert( acctClassificationIds.contains( aCC.Account_Classification__c ), 'Account Classification lookup should be tied to related Account Classification' );
		}
	}

	static testMethod void testContactClassificationInsert_NonMatchingProfile()
	{
		Id acctRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'BMGAccount' ].Id;
		Id acctClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'AccountClassification__c' AND DeveloperName = 'BMGAccountClassification' ].Id;
		ProfileToAcctRecType__c csOne = TestingUtils.createProfileToAcctRecTypeCS( BMG_PROFILE_NAME, acctRTId, acctClassificationRTId, true );

		Id contactRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'HBSContact' ].Id;
		contactClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'ContactClassification__c' AND DeveloperName = 'HBSContactClassification' ].Id;
		ProfileToContactRecType__c csTwo = TestingUtils.createProfileToContactRecTypeCS( HBS_PROFILE_NAME, contactRTId, contactClassificationRTId, true );

		Account testAccount = TestingUtils.createTestAccount( 'Test Acct', false );
		testAccount.RecordTypeId = acctRTId;
		insert testAccount;

		acctClassification = TestingUtils.createAccountClassification( 1, TYPE, SUB_TYPE, SUB_TYPE_DETAIL, TERRITORY, INDUSTRY_MARKET, REGION, PRODUCT_INTEREST, false )[0];
		acctClassification.Account__c = testAccount.Id;
		acctClassification.RecordTypeId = acctClassificationRTId;
		insert acctClassification;

		testContact = TestingUtils.createContacts( 1, testAccount.Id, false )[0];
		testContact.RecordTypeId = contactRTId;
		insert testContact;

		ContactClassification__c testContactClassification = TestingUtils.createContactClassification( 1, TYPE, PRODUCT_INTEREST, false )[0];
		testContactClassification.Contact__c = testContact.Id;
		testContactClassification.RecordTypeId = contactClassificationRTId;

		Test.startTest();

			insert testContactClassification;

		Test.stopTest();

		List<ContactClassification__c> actualContactClassifications = [ SELECT Id, Account_Classification__c FROM ContactClassification__c ];
		System.assertEquals( 1, actualContactClassifications.size(), 'There should be one Contact Classification returned' );
		System.assertEquals( null, actualContactClassifications[0].Account_Classification__c, 'For non matching Record Type, Account Classification lookup should not be populated' );
	}

	static testMethod void testContactClassificationInsert_AccountIdNotPopulatedOnContact()
	{
		Id acctRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'HBSAccount' ].Id;
		Id acctClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'AccountClassification__c' AND DeveloperName = 'HBSAccountClassification' ].Id;
		ProfileToAcctRecType__c csOne = TestingUtils.createProfileToAcctRecTypeCS( HBS_PROFILE_NAME, acctRTId, acctClassificationRTId, true );

		Id contactRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'HBSContact' ].Id;
		contactClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'ContactClassification__c' AND DeveloperName = 'HBSContactClassification' ].Id;
		ProfileToContactRecType__c csTwo = TestingUtils.createProfileToContactRecTypeCS( HBS_PROFILE_NAME, contactRTId, contactClassificationRTId, true );

		Account testAccount = TestingUtils.createTestAccount( 'Test Acct', false );
		testAccount.RecordTypeId = acctRTId;
		insert testAccount;

		acctClassification = TestingUtils.createAccountClassification( 1, TYPE, SUB_TYPE, SUB_TYPE_DETAIL, TERRITORY, INDUSTRY_MARKET, REGION, PRODUCT_INTEREST, false )[0];
		acctClassification.Account__c = testAccount.Id;
		acctClassification.RecordTypeId = acctClassificationRTId;
		insert acctClassification;

		testContact = TestingUtils.createContacts( 1, null, false )[0];
		testContact.RecordTypeId = contactRTId;
		insert testContact;

		ContactClassification__c testContactClassification = TestingUtils.createContactClassification( 1, TYPE, PRODUCT_INTEREST, false )[0];
		testContactClassification.Contact__c = testContact.Id;
		testContactClassification.RecordTypeId = contactClassificationRTId;

		Test.startTest();

			insert testContactClassification;

		Test.stopTest();

		List<ContactClassification__c> actualContactClassifications = [ SELECT Id, Account_Classification__c FROM ContactClassification__c ];
		System.assertEquals( 1, actualContactClassifications.size(), 'There should be one Contact Classification returned' );
		System.assertEquals( null, actualContactClassifications[0].Account_Classification__c, 'Contact Classification that has parent of Contact that is not tied to any Accounts should not be tied to any Account Classifications' );
	}
}