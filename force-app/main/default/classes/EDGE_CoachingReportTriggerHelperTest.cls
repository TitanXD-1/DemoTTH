/*
 *   @Name: EDGE_CoachingReportTriggerHelperTest

 *   @History                                                            
                                                           
 *  VERSION     AUTHOR           DATE            DETAIL
    1.0         Dipanjan D     18/09/2019      Test Class for EDGE_CoachingReportTriggerHelper
*/
@isTest
public class EDGE_CoachingReportTriggerHelperTest{
    
    public static User salesRep;
    public static User salesManager;
    
    @isTest
    public static void testCreateCustomShare(){
        createData();
        List<Coaching_Report__Share> coachingShareRep = [SELECT Id, UserOrGroupId, AccessLevel,RowCause FROM Coaching_Report__Share WHERE UserOrGroupId= :salesRep.Id];
        System.assertEquals(coachingShareRep[0].AccessLevel, 'Read','coachingShareRep[0] should match');
        
        Coaching_Report__c coachingReport = [SELECT Id FROM Coaching_Report__c LIMIT 1];
        update coachingReport;
        delete coachingReport;
        undelete coachingReport;
    }   
    
    public static void createData(){
        
        EDGE_UtilityTestClass.createOrgSettings(); 
        salesRep = EDGE_UtilityTestClass.runAsUser('EDGErep05', 'Sales Representative');
        insert salesRep;
        salesManager = EDGE_UtilityTestClass.runAsUser('EDGEManager10', 'Sales Manager');
        insert salesManager;
        
        Coaching_Report__c coachingReport = new Coaching_Report__c();
        coachingReport.Current_Sales_Manager__c = salesManager.Id;
        coachingReport.Sales_Representative__c = salesRep.Id;
        coachingReport.Status__c = 'Draft';
        coachingReport.Report_Date__c = system.today();
        
        insert coachingReport;
    }
}