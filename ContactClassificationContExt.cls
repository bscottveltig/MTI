public with sharing class ContactClassificationContExt
{
    public final String CONTACT_HOME_URL = '/003/o';
    public final String SAVE_AND_NEW_URL = '/apex/ContactClassification';
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
    private final String CETCO_DP_SALES_ADMINISTRATOR = 'CETCO DP Sales Administrator';
    private final String DRILLING_PRODUCTS = 'Drilling Products';
    private final String BUILDING_MATERIALS = 'Building Materials';
    private final String ENVIRONMENTAL_PRODUCTS = 'Environmental Products';
    
    public Contact contact { get; set; }
    public ContactClassification__c contactClassification { get; set; }
    public List<SelectOption> accountClassifications { get; set; }
    public Id selectedAccountClassificationId { get; set; }

    @TestVisible Id ownerId;
    @TestVisible Id profileId;
    @TestVisible Id accountId;
    @TestVisible Id contactRTId;
    @TestVisible Id classificationRTId;
    @TestVisible String profileName;

    //holds Profile Name -> Contact Record Type Id
    public Map<String, String> profileNameToContactRT
    {
        get
        {
            if( profileNameToContactRT == null )
            {
                profileNameToContactRT = new Map<String, String>();
                for( ProfileToContactRecType__c aCS : ProfileToContactRecType__c.getAll().values() )
                {
                    profileNameToContactRT.put( aCS.Profile_Name__c, aCS.Contact_Record_Type_Id__c );
                }
            }
            return profileNameToContactRT;
        }
        private set;
    }

    //holds Profile Name -> Contact Classification Record Type Id
    public Map<String, String> profileNameToClassificationRT
    {
        get
        {
            if( profileNameToClassificationRT == null )
            {
                profileNameToClassificationRT = new Map<String, String>();
                for( ProfileToContactRecType__c aCS : ProfileToContactRecType__c.getAll().values() )
                {
                    profileNameToClassificationRT.put( aCS.Profile_Name__c, aCS.Classification_Record_Type_Id__c );
                }
            }
            return profileNameToClassificationRT;
        }
        private set;
    }

    public Boolean isProfilesToEditRT
    {
        get
        {
            return ( profileName.contains( SYSTEM_ADMIN ) || profileName.contains( AMCOL_EXEC_USER ) || profileName.contains( AMCOL_MARKETING_USER ) || profileName.contains( AMCOL_CUST_SERV_USER ) || profileName.contains( AMCOL_HPC_OPERATION_USER ) || profileName.contains( AMCOL_HPC_GROUP_MANAGER ) || profileName.contains( AMCOL_FABRIC_CARE_SALES_USER ) || profileName.contains( AMCOL_COUNTRY_MANAGERS ) || profileName.contains( AMCOL_ADDITIVES_SALES_USER ) || profileName.contains( AMCOL_REGIONAL_EXECUTIVE_USER ) || profileName.contains( CETCO_DP_SALES_ADMINISTRATOR ) || profileName.contains( DRILLING_PRODUCTS ) || profileName.contains( ENVIRONMENTAL_PRODUCTS ) || profileName.contains( BUILDING_MATERIALS ));
        }
    }

    public ContactClassificationContExt( ApexPages.StandardController stdController )
    {
        ownerId = UserInfo.getUserId();
        profileId = UserInfo.getProfileId();
        accountId = ApexPages.currentPage().getParameters().get('accId');

        profileName = [ SELECT Name FROM Profile WHERE Id = :profileId ].Name;
        contactRTId = profileNameToContactRT.get( profileName );
        classificationRTId = profileNameToClassificationRT.get( profileName );
        accountClassifications = new List<SelectOption>();

        this.contact = new Contact();
        this.contact.OwnerId = ownerId;
        this.contact.RecordTypeId = contactRTId;
        if ( accountId != null )
        {
            Account parent = [SELECT Id, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet FROM Account Where Id = :accountId];
            this.contact.AccountId = parent.Id;
            this.contact.MailingCity = parent.BillingCity;
            this.contact.MailingCountry = parent.BillingCountry;
            this.contact.MailingPostalCode = parent.BillingPostalCode;
            this.contact.MailingState = parent.BillingState;
            this.contact.MailingStreet = parent.BillingStreet;
            accountClassifications = ContactClassificationServices.generateAccountClassificationSelectOptions( accountId );
        }

        this.contactClassification = new ContactClassification__c();
        this.contactClassification.RecordTypeId = classificationRTId;
    }

    public void populateAccountClassifications()
    {
        accountClassifications = ContactClassificationServices.generateAccountClassificationSelectOptions( contact.AccountId );
    }

    /**
    * Performs DML operation to create Contact and Contact Classification records.
    * @DMLException
    * @returns URL of Contact Home page
    */
    public PageReference save()
    {
        System.SavePoint savePoint = Database.setSavepoint();
        try
        {
            insert contact;
        }
        catch( DMLException ex )
        {
            return handleException(ex); 
        }

        contactClassification.Contact__c = contact.Id;
        if( selectedAccountClassificationId == null )
        {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, Label.Required_Account_Classification_Error ) );
            Database.rollback( savePoint );
            contact.Id = null;
            return null;
        }

        try
        {
            contactClassification.Account_Classification__c = selectedAccountClassificationId;
            insert contactClassification;
        }
        catch( DMLException ex )
        {
            Database.rollback( savePoint );
            contact.Id = null;
            return handleException(ex); 
        }
        return new PageReference( '/' + contact.Id );
    }

    /**
    * Creates Contact and Contact Classification records and redirects the page to ContactClassification page again.
    */
    public PageReference saveAndNew()
    {
        System.SavePoint savePoint = Database.setSavepoint();
        try
        {
            insert contact;
            try
            {
                contactClassification.Contact__c = contact.Id;
                insert contactClassification;
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
    * Redirects user to Contact's home page.
    */
    public PageReference cancel()
    {
        return new PageReference( CONTACT_HOME_URL );
    }

    public void refresh() { }

    private PageReference handleException(DMLException ex)
    {
        for( Integer i = 0; i < ex.getNumDml(); i++ )
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, ex.getDmlMessage( i ) ) );
        return null;
    }
}