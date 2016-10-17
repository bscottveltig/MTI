public with sharing class AccountClassificationContExt
{
	public final String ACCOUNT_HOME_URL = '/001/o';
	public final String SAVE_AND_NEW_URL = '/apex/AccountClassification';

	private Id ownerId;
	private Id profileId;
	private String userProfileName;
	private final String MPG_STR = 'MPG';
	private final String SYSTEM_ADMIN = 'System Administrator';
	private final String AMCOL_EXEC_USER = 'AMCOL Executive User';
	private final String AMCOL_MARKETING_USER = 'AMCOL Marketing User';
	private final String AMCOL_CUST_SERV_USER = 'AMCOL Customer Service User';
	private final String AMCOL_HPC_OPERATION_USER = 'AMCOL HPC Operations User';
	private final String AMCOL_HPC_GROUP_MANAGER = 'AMCOL HPC Group Manager';
	private final String AMCOL_FABRIC_CARE_SALES_USER = 'AMCOL Fabric Care Sales User';
	private final String AMCOL_COUNTRY_MANAGERS = 'AMCOL Country Managers';
	private final String AMCOL_ADDITIVES_SALES_USER = 'AMCOL Additives Sales User';
	private final String AMCOL_REGIONAL_EXECUTIVE_USER = 'AMCOL Regional Executive User';
	private final Set<String> fieldToRemoveIfMPGAsia = new Set<String>{ 'Region__c', 'IndustryMarketSegment__c', 'Territory__c' };

	public Account account { get; set; }
	public AccountClassification__c acctClassification { get; set; }
	public Id classificationRTId { get; set; }

	public Map<String, String> profileNameToAccountRT
	{
		get
		{
			if( profileNameToAccountRT == null )
			{
				profileNameToAccountRT = new Map<String, String>();
				for( ProfileToAcctRecType__c aCS : ProfileToAcctRecType__c.getAll().values() )
				{
					profileNameToAccountRT.put( aCS.Profile_Name__c, aCS.Account_Record_Type_Id__c );
				}
			}
			return profileNameToAccountRT;
		}
		private set;
	}

	public Map<String, String> profileNameToClassificationRT
	{
		get
		{
			if( profileNameToClassificationRT == null )
			{
				profileNameToClassificationRT = new Map<String, String>();
				for( ProfileToAcctRecType__c aCS : ProfileToAcctRecType__c.getAll().values() )
				{
					profileNameToClassificationRT.put( aCS.Profile_Name__c, aCS.Classification_Record_Type_Id__c );
				}
			}
			return profileNameToClassificationRT;
		}
		private set;
	}
	
	public Map<String, Boolean> showFieldsMap
	{
		get
		{
			if( showFieldsMap == null )
			{
				showFieldsMap = new Map<String, Boolean>();
				for( Schema.FieldSetMember f : SObjectType.AccountClassification__c.FieldSets.Classification.getFields() )
				{
					showFieldsMap.put( f.getFieldPath(), true );
					if( fieldToRemoveIfMPGAsia.contains( f.getFieldPath() ))
					{
						showFieldsMap.put( f.getFieldPath(), false );
					}
				}
			}
			return showFieldsMap;
		}
		private set;
	} 

	public Boolean isMPGProfile
	{
		get
		{
			return ( userProfileName.contains( MPG_STR ) );
		}
	}

	public Boolean isProfilesToEditRT
	{
		get
		{
			return ( userProfileName.contains( SYSTEM_ADMIN ) || userProfileName.contains( AMCOL_EXEC_USER ) || userProfileName.contains( AMCOL_MARKETING_USER ) || userProfileName.contains( AMCOL_CUST_SERV_USER ) || userProfileName.contains( AMCOL_HPC_OPERATION_USER ) || userProfileName.contains( AMCOL_HPC_GROUP_MANAGER ) || userProfileName.contains( AMCOL_FABRIC_CARE_SALES_USER ) || userProfileName.contains( AMCOL_COUNTRY_MANAGERS ) || userProfileName.contains( AMCOL_ADDITIVES_SALES_USER ) || userProfileName.contains( AMCOL_REGIONAL_EXECUTIVE_USER ) );
		}
	}
	
	public Id MPGAsiaRTId
	{
		get
		{
			return [ SELECT Id FROM RecordType WHERE SObjectType = 'AccountClassification__c' AND DeveloperName = 'MPG_Asia_Account_Classification' ].Id;
		}
		private set;
	}
	
	public AccountClassificationContExt( ApexPages.StandardController stdController )
	{
		ownerId = UserInfo.getUserId();
		profileId = UserInfo.getProfileId();
		userProfileName = [ SELECT Name FROM Profile WHERE Id = :profileId ].Name;
		Id accountRTId = profileNameToAccountRT.get( userProfileName );
		classificationRTId = profileNameToClassificationRT.get( userProfileName );

		this.account = new Account();
		this.account.OwnerId = ownerId;
		this.account.RecordTypeId = accountRTId;

		this.acctClassification = new AccountClassification__c();
		this.acctClassification.RecordTypeId = classificationRTId;
	}

	/**
	* Performs DML operation to create Account and Account Classification records.
	* @DMLException
	* @returns URL of Account Home page
	*/
	public PageReference save()
	{
		System.SavePoint savePoint = Database.setSavepoint();
		try
		{
			insert account;
			try
			{
				acctClassification.Account__c = account.Id;
				insert acctClassification;
			}
			catch( DMLException ex )
			{
				Database.rollback( savePoint );
				return handleException(ex);
			}
		}
		catch( DMLException ex )
		{
			return handleException(ex);
		}

		return new PageReference( '/' + account.Id );
	}

	/**
	* Creates Account and Account Classification records and redirects the page to AccountClassification page again.
	*/
	public PageReference saveAndNew()
	{
		System.SavePoint savePoint = Database.setSavepoint();
		try
		{
			insert account;
			try
			{
				acctClassification.Account__c = account.Id;
				insert acctClassification;
			}
			catch( DMLException ex )
			{
				Database.rollback( savePoint );
				return handleException(ex);
			}
		}
		catch( DMLException ex )
		{
			return handleException(ex);	
		}

		return new PageReference( SAVE_AND_NEW_URL );
	}

	/**
	* Redirects user to Account's home page.
	*/
	public PageReference cancel()
	{
		return new PageReference( ACCOUNT_HOME_URL );
	}

	public void refresh() { }

	private PageReference handleException(DMLException ex)
	{
		for( Integer i = 0; i < ex.getNumDml(); i++ )
			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, ex.getDmlMessage( i ) ) );
		return null;
	}
}