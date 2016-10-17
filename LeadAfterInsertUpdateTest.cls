@isTest
private class LeadAfterInsertUpdateTest {

    static testMethod void testRecordTypes() {
        
        Lead l = new Lead();
        l.Company = 'test';
        l.LastName = 'last';
        l.LeadSource = 'source';
        insert l; 
        
        Database.Leadconvert lcon = new Database.Leadconvert();
        lcon.setLeadId(l.Id);
        
        LeadStatus convertStatus = [select Id, MasterLabel from LeadStatus where IsConverted = true limit 1];
        lcon.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.Leadconvertresult lcr = Database.convertLead(lcon);
        
    }
}