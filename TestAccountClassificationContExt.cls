@isTest
private class TestAccountClassificationContExt
{
	static final String HBS_PROFILE_NAME = 'AMCOL HBS Sales User';
	static final String TYPE = 'Test Type';
	static final String SUB_TYPE = 'Test SubType';
	static final String SUB_TYPE_DETAIL = 'Test SubType Detail';
	static final String TERRITORY = 'Test Territory';
	static final String INDUSTRY_MARKET = 'Test Industry Market';
	static final String REGION = 'Test Region';
	static final String PRODUCT_INTEREST = 'Test Product Interest';

	static Id acctRTId;
	static Id acctClassificationRTId;

	static Account testAccount;
	static AccountClassification__c testAccountClassification;

	static
	{
		acctRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'HBSAccount' ].Id;
		acctClassificationRTId = [ SELECT Name FROM RecordType WHERE SObjectType = 'AccountClassification__c' AND DeveloperName = 'HBSAccountClassification' ].Id;
		
		ProfileToAcctRecType__c csOne = TestingUtils.createProfileToAcctRecTypeCS( HBS_PROFILE_NAME, acctRTId, acctClassificationRTId, true );
	}

	static void setup()
	{
		testAccount = TestingUtils.createTestAccount( 'Test Account', false );
		testAccountClassification = TestingUtils.createAccountClassification( 1, TYPE, SUB_TYPE, SUB_TYPE_DETAIL, TERRITORY, INDUSTRY_MARKET, REGION, PRODUCT_INTEREST, false )[0];
	}

	static testMethod void testProfileNameToAccountAndClassificationRT()
	{
		setup();

		AccountClassificationContExt controller = new AccountClassificationContExt( new ApexPages.Standardcontroller( testAccount ) );
		
		Test.startTest();

			System.assertEquals( acctRTId, controller.profileNameToAccountRT.get( HBS_PROFILE_NAME ), 'With HBS Profile Name, HBS record type shoul be returned for Account' );
			System.assertEquals( acctClassificationRTId, controller.profileNameToClassificationRT.get( HBS_PROFILE_NAME ), 'With HBS Profile Name, HBS record type shoul be returned for Account Classification' );

		Test.stopTest();
	}

	static testMethod void testSave()
	{
		setup();

		List<Account> accountsBeforeSave = [ SELECT Id FROM Account ];
		System.assert( accountsBeforeSave.isEmpty(), 'Before Save, there should not be any existing Accounts' );
		
		List<AccountClassification__c> accountClassificationBeforeSave = [ SELECT Id FROM AccountClassification__c ];
		System.assert( accountClassificationBeforeSave.isEmpty(), 'Before Save, there should not be any existing Account Classifications' );

		AccountClassificationContExt controller = new AccountClassificationContExt( new ApexPages.Standardcontroller( testAccount ) );
		controller.account = testAccount;
		controller.acctClassification = testAccountClassification;

		Test.startTest();

			PageReference pgReference = controller.save();

		Test.stopTest();

		System.assert( pgReference.getUrl().endsWith( ''+testAccount.Id ), 'After DML, User should be redirected to newly created Account\'s page' );

		List<Account> accountsAfterSave = [ SELECT Id FROM Account ];
		System.assertEquals( 1, accountsAfterSave.size(), 'After Save, there should be Account inserted' );

		List<AccountClassification__c> accountClassificationAfterSave = [ SELECT Id, Account__c, Type__c, SubType__c, SubtypeDetail__c, Territory__c, IndustryMarketSegment__c, Region__c FROM AccountClassification__c ];
		System.assertEquals( 1, accountClassificationAfterSave.size(), 'After Save, Account Classification record should have been created' );
		System.assertEquals( testAccount.Id, accountClassificationAfterSave[0].Account__c, 'The relationship between Account and Classifcation should be created' );
		System.assertEquals( TYPE, accountClassificationAfterSave[0].Type__c, 'The Type should be populated' );
		System.assertEquals( SUB_TYPE, accountClassificationAfterSave[0].SubType__c, 'The Subtype should be populated' );
		System.assertEquals( SUB_TYPE_DETAIL, accountClassificationAfterSave[0].SubtypeDetail__c, 'The Subtype Details should be populated' );
		System.assertEquals( TERRITORY, accountClassificationAfterSave[0].Territory__c, 'The Territory should be populated' );
		System.assertEquals( INDUSTRY_MARKET, accountClassificationAfterSave[0].IndustryMarketSegment__c, 'The Industry Market Segment should be populated' );
		System.assertEquals( REGION, accountClassificationAfterSave[0].Region__c, 'The Region should be populated' );
	}

	static testMethod void testSaveAndNew()
	{
		setup();
		
		List<Account> accountsBeforeSaveAndNew = [ SELECT Id FROM Account ];
		System.assert( accountsBeforeSaveAndNew.isEmpty(), 'Before Save & New, there should not be any existing Accounts' );
		
		List<AccountClassification__c> accountClassificationsBeforeSaveAndNew = [ SELECT Id FROM AccountClassification__c ];
		System.assert( accountClassificationsBeforeSaveAndNew.isEmpty(), 'Before Save & New, there should not be any existing Account Classifications' );
		
		AccountClassificationContExt controller = new AccountClassificationContExt( new ApexPages.Standardcontroller( testAccount ) );
		controller.account = testAccount;
		controller.acctClassification = testAccountClassification;

		Test.startTest();

			PageReference pgReference = controller.saveAndNew();

		Test.stopTest();

		System.assert( pgReference.getUrl().endsWith( controller.SAVE_AND_NEW_URL ), 'Upon Save&New, User should be redirected to Account Classification Page again' );

		List<Account> accountsAfterSaveAndNew = [ SELECT Id FROM Account ];
		System.assertEquals( 1, accountsAfterSaveAndNew.size(), 'After Save, there should be Account inserted' );

		List<AccountClassification__c> accountClassificationAfterSaveAndNew = [ SELECT Id, Account__c, Type__c, SubType__c, SubtypeDetail__c, Territory__c, IndustryMarketSegment__c, Region__c FROM AccountClassification__c ];
		System.assertEquals( TYPE, accountClassificationAfterSaveAndNew[0].Type__c, 'The Type should be populated' );
		System.assertEquals( SUB_TYPE, accountClassificationAfterSaveAndNew[0].SubType__c, 'The Subtype should be populated' );
		System.assertEquals( SUB_TYPE_DETAIL, accountClassificationAfterSaveAndNew[0].SubtypeDetail__c, 'The Subtype Details should be populated' );
		System.assertEquals( TERRITORY, accountClassificationAfterSaveAndNew[0].Territory__c, 'The Territory should be populated' );
		System.assertEquals( INDUSTRY_MARKET, accountClassificationAfterSaveAndNew[0].IndustryMarketSegment__c, 'The Industry Market Segment should be populated' );
		System.assertEquals( REGION, accountClassificationAfterSaveAndNew[0].Region__c, 'The Region should be populated' );
	}
	
	static testMethod void testCancel()
	{
		setup();

		AccountClassificationContExt controller = new AccountClassificationContExt( new ApexPages.Standardcontroller( testAccount ) );
		
		Test.startTest();

			PageReference pgReference = controller.cancel();

		Test.stopTest();

		System.assert( pgReference.getUrl().endsWith( controller.ACCOUNT_HOME_URL ), 'Upon Cancel, User should be redirected to Account home page' );
	}

	static testMethod void testProperty()
	{
		setup();

		AccountClassificationContExt controller = new AccountClassificationContExt( new ApexPages.Standardcontroller( testAccount ) );
		controller.refresh();
		system.assertEquals(true, controller.isProfilesToEditRT);
		system.assertNotEquals(null, controller.showFieldsMap);
		system.assertNotEquals(null, controller.MPGAsiaRTId);
	}
}