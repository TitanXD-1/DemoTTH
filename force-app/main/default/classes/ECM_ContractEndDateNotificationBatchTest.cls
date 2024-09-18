/*
@Name: ECM_ContractEndDateNotificationBatchTest
@Purpose: This test class is for ECM_ContractEndDateNotificationBatch and ECM_ContractNotifcationMailHelper

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Subhodeep Sarkar     27/06/2022        Initial Development (ECM-5539)

*/


@isTest
public class ECM_ContractEndDateNotificationBatchTest {
    @isTest
    public static void sendNotificationTest(){
        Test.startTest();
        createData();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'ECM_ContractEndDateNotificationBatch'
                                                  AND Country_Code__c ='ES' ];
        String className = batchSetting.Batch_Class__c;
        system.assert(className != null,'className should not be null');
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));		
        Test.stopTest();
    }
    
    public static void createData(){
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String type='Local-Segment1';
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        //string recordTypeName = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Market').getRecordTypeId();
       
        //user rec
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','Sales Representative');
        insert newuser;
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
		acc.country__c = geographyId;
		acc.Sales_Org__c='sale';
		acc.SAP_Sold_to__c='sapsold';
		acc.Independent_of_Operator__c=true;
		acc.Independent_of_Owner__c=true;
		insert acc;
        
        //contract type rec
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        
        contractType.ECM_Expiration_Start_Date_Rule_in_Months__c = 3;
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        insert contractType;
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contractRecordTypeId);  
        contr.Status = 'Draft';
        contr.ECM_Duration__c = 10;
        contr.ECM_Agreement_Type__c = contractType.Id;
        integer months = Integer.valueOF(contractType.ECM_Expiration_Start_Date_Rule_in_Months__c);
        contr.Contract_End_Date__c = System.today().addMonths(months);
        contr.ECM_Expiration_Notification_sent__c = false;
        contr.ownerId = newuser.Id;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        
        
            
            }
    
    
    
}