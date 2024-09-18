/********************************************************************************************
Class Name: EDGE_CallTraxStatusUpdateBatchTest

Author          Version    Date           Detail
Sandip Ghosh    V1.0       06/07/2020     [ES20-8048]This is the test class for 
EDGE_CallTraxStatusUpdateBatch
*********************************************************************************************/
@isTest
public class EDGE_CallTraxStatusUpdateBatchTest {
    
    @isTest
    public static void testTraxStatusUpdate(){
        
        Test.startTest();
        Map<String, List<Call__c>> callUniqueIdMap = new Map<String, List<Call__c>>();
        Map<Id, Call__c> callMapToUpdate = new Map<Id, Call__c>();
        Set<String> uniqueIdSet=new Set<String>();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        System.assert(outlet.Id!= null,'Outlet Id should not be null');
        System.assert(outlet.Country__r.Code__c!= 'AU','outlet Country code should not be AU');
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesManager','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Email = 'test10072020001@diageo.com';
        insert salesRep; 
        System.assert(salesRep.Id!=null,'salesRep Id should not be null');
        
        //Create Call Rec
        Datetime endDate=Datetime.now();
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Call_Completed_in_Mobile__c = true;
        callObj.Trax_Validation__c = 'Pending';
        callObj.Call_Performed_By__c = salesRep.Id;
        callObj.End_Date__c = endDate;
        callObj.Account__c = outlet.Id;
        insert callObj;
        System.assert(callObj.Id!= null,'call object Id should not be null');
        
        //Created Call Rec for ES20-8055
        Call__c callObj1 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj1.Call_Completed_in_Mobile__c = true;
        callObj1.Trax_Validation__c = 'Pending';
        callObj1.Call_Performed_By__c = salesRep.Id;
        callObj1.End_Date__c = System.today()-20;
        callObj1.Account__c = outlet.Id;
        insert callObj1;
        System.assert(callObj1.Id!= null,'call object1 Id should not be null');
        
        //Create Visit Audit records
        String uniqueId = endDate.format('yyyy-MM-dd') + '_' + 'test10072020001@diageo.com'+ '_' + callObj.Account__c;  
        uniqueIdSet.add(uniqueId);
        callUniqueIdMap.put(uniqueId, new List<Call__c>{callObj});
        System.assert(uniqueIdSet.size()==1,'unique Id Set size should be equals to 1');
        Visit_Audit__c visitAuditRec = new Visit_Audit__c();
        visitAuditRec.Date__c = Date.today();
        visitAuditRec.Email__c = 'test10072020001@diageo.com';
        visitAuditRec.Account__c = outlet.Id;
        visitAuditRec.Unique_ID__c=uniqueId;
        insert visitAuditRec;
        System.assert(visitAuditRec.Id!= null,'visit AuditRec Id should not be null');
        System.assert(visitAuditRec.Unique_ID__c!=null,'visit AuditRec Unique ID should be null');
        System.assert(callUniqueIdMap.containsKey(visitAuditRec.Unique_ID__c),'visit AuditRec Unique ID');
        if(visitAuditRec.Unique_ID__c != null && callUniqueIdMap.containsKey(visitAuditRec.Unique_ID__c)){
                            for(Call__c callRecord : callUniqueIdMap.get(visitAuditRec.Unique_ID__c)){
                              	callRecord.Trax_Validation__c = 'Complete';
                                //after discussion on 17-July
                                callRecord.Visit_Audit__c = visitAuditRec.Id;
                                callMapToUpdate.put(callRecord.Id, callRecord);
                            }
                        }
        System.assert(callMapToUpdate.size()>0,'call Map To Update size should be greater than 0');
        EDGE_UtilityTestClass.createOrgSettings();
        
        executeBatch();
        Test.stopTest();
    }
    
    private static void executeBatch(){
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, 
                                                  Region__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_CallTraxStatusUpdateBatch'
                                                  and Country_Code__c ='AU'];
        System.assert(batchSetting.Id != null,'batch Setting Id should not be null');
        System.debug(LoggingLevel.Debug,('batchSetting = '+ batchSetting));
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);

        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));       
    }

}