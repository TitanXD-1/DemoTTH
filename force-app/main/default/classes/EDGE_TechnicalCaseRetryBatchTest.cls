/**
* @description :  EDGE_TechnicalCaseRetryBatchTest
* @purpose : Test class for EDGE_TechnicalCaseRetryBatch
* @history :
* Version    Developer                Date             User Story/Purpose
* 1.1		Monalisa Halder			10/09/2021		   ES20-10567
*/

@isTest
public class EDGE_TechnicalCaseRetryBatchTest {
    final static String technicalIssueRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();

    @isTest
    public static void createTestData(){
        List<Case> casetoUpdateList = new List<Case>();
        List<Case> casetoInsertList = new List<Case>();
		User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Available_Countries__c = 'CO';
        insert adminUser;
        Case ccException;
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountryCO('CO');
        System.assert(countryId!=null);
       
             system.runAs(adminUser){
            test.startTest();
            
            Case cc = new Case();
            cc.Status = 'New';
            cc.Origin = 'EDGE 365 Global';
            cc.RecordTypeId = technicalIssueRecordTypeId;
            casetoInsertList.add(cc);
            
            Case cc1 = new Case();
            cc1.Status = 'New';
            cc1.Origin = 'EDGE 365 Global';
            cc1.Retry_Count__c = 1 ;
            cc1.RecordTypeId = technicalIssueRecordTypeId;
            casetoInsertList.add(cc1);
            insert casetoInsertList;
               
        	List<Case> caseList = [Select Id, sys_id__c, Inc_Req_Number__c from Case];
            for(Case ctoUpdate :caseList){
                if(ctoUpdate.Inc_Req_Number__c != null ){
                    ctoUpdate.Inc_Req_Number__c = '';
                    ctoUpdate.sys_id__c = '';
                    casetoUpdateList.add(ctoUpdate);
                }
            }
            
        update casetoUpdateList;
        
       
        testTechnicalCaseRetryBatch();    
        test.stopTest();
        }
            
        
        
    }
    
    public static void testTechnicalCaseRetryBatch(){
       
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_TechnicalCaseRetryBatch'
                                                  and Country_Code__c ='CO'];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        
    }
}