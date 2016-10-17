public with sharing class ContactClassificationServices
{
    private static Map<String, String> contactClassificationRTToProfileName
    {
        get
        {
            if( contactClassificationRTToProfileName == null )
            {
                contactClassificationRTToProfileName = new Map<String, String>();
                for( ProfileToContactRecType__c aCS : ProfileToContactRecType__c.getAll().values() )
                {
                    contactClassificationRTToProfileName.put( aCS.Classification_Record_Type_Id__c, aCS.Profile_Name__c );
                }
            }
            return contactClassificationRTToProfileName;
        }
        private set;
    }

    private static Map<String, String> profileNameToAccountClassificationRT
    {
        get
        {
            if( profileNameToAccountClassificationRT == null )
            {
                profileNameToAccountClassificationRT = new Map<String, String>();
                for( ProfileToAcctRecType__c aCS : ProfileToAcctRecType__c.getAll().values() )
                {
                    profileNameToAccountClassificationRT.put( aCS.Profile_Name__c, aCS.Classification_Record_Type_Id__c );
                }
            }
            return profileNameToAccountClassificationRT;
        }
        private set;
    }

    private static Map<String, String> accountClassificationRTToProfileName
    {
        get
        {
            if( accountClassificationRTToProfileName == null )
            {
                accountClassificationRTToProfileName = new Map<String, String>();
                for( ProfileToAcctRecType__c aCS : ProfileToAcctRecType__c.getAll().values() )
                {
                    accountClassificationRTToProfileName.put( aCS.Classification_Record_Type_Id__c, aCS.Profile_Name__c );
                }
            }
            return accountClassificationRTToProfileName;
        }
        private set;
    }

    public static List<AccountClassification__c> getRelatedAccountClassifications( List<ContactClassification__c> contactClassifications )
    {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactClassificationRTIds = new Set<Id>();
        for( ContactClassification__c cc : contactClassifications )
        {
            accountIds.add( (Id)cc.Account_ID__c );
            contactClassificationRTIds.add( cc.RecordTypeId );
        }

        List<String> profileNames = new List<String>();
        for( Id ccRTId : contactClassificationRTIds )
        {
            String profileName = contactClassificationRTToProfileName.get( ccRTId );
            if( profileName != null )
            {
                profileNames.add( profileName );
            }
        }

        Set<Id> accountClassificationIds = new Set<Id>();
        for( String profileName : profileNames )
        {
            accountClassificationIds.add( profileNameToAccountClassificationRT.get( profileName ) );
        }

        return [ SELECT Id, Account__c, RecordTypeId
                    FROM AccountClassification__c
                    WHERE Account__c IN :accountIds
                        AND RecordTypeId IN :accountClassificationIds ];
    }

    public static void setAccountClassificationOnCC( List<AccountClassification__c> accountClassifications, List<ContactClassification__c> contactClassifications )
    {
        for( AccountClassification__c anAC : accountClassifications )
        {
            String accountProfileName = accountClassificationRTToProfileName.get( anAC.RecordTypeId );
            for( ContactClassification__c aCC : contactClassifications )
            {
                String contactProfileName = contactClassificationRTToProfileName.get( aCC.RecordTypeId );
                if( accountProfileName == contactProfileName && anAC.Account__c == aCC.Account_ID__c )
                {
                    aCC.Account_Classification__c = anAC.Id;
                }
            }
        }
    }

    public static List<SelectOption> generateAccountClassificationSelectOptions( Id accountIdIn )
    {
        List<SelectOption> accountClassificationSOs = new List<SelectOption>();
        List<AccountClassification__c> relatedAccountClassifications = [ SELECT Id, Type__c, RecordType.Name FROM AccountClassification__c WHERE Account__c = :accountIdIn ];
        if( !relatedAccountClassifications.isEmpty() )
        {
            for( AccountClassification__c acctClassification : relatedAccountClassifications )
            {
                accountClassificationSOs.add( new SelectOption( acctClassification.Id, acctClassification.RecordType.Name + ' - ' + acctClassification.Type__c ) );
            }
        }
        return accountClassificationSOs;
    }
}