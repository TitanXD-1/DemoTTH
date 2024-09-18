/**********************************************************************
Name: EDGE_OutletTempStatusUpdateBatchTest
=======================================================================
Req: Test class of EDGE_OutletTemporaryStatusUpdateBatch
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR             DATE      DETAIL
1.0      Shahbaz Khan      26/11/2019   Initial Development  
2.0      Swaraj Samanta    06/09/2022   Test Class Correction Due to Failure(ES20-13284)
***********************************************************************/
@istest
public class EDGE_OutletTempStatusUpdateBatchTest {
	@isTest
    public static void orderBatchTest(){
     
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OutletTemporaryStatusUpdateBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
       
        
    }
     public static void createData(){  
    	Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'');
        System.assert(salesManager.Id!=null,' should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'salesRep should not be null');
         
        EDGE_UtilityTestClass.createOrgSettings(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        /*Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Reason Code');
        pickupOption1.Name = 'Gold[AU]';
        insert pickupOption1;*/
        List<Account> accounts=new List<Account>();         
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        outlet.Start_Date__c = Date.today();
        accounts.add(outlet);
        Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
        accounts.add(wholesaler);
        insert accounts;
        Test.startTest();
        Delivery_Partner__c delPart = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert delPart;
         
        Product__c skuProduct = EDGE_UtilityTestClass.getProd();
        skuProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        skuProduct.Start_Date__c = system.today();
        insert skuProduct;
        
      //  List<Order__c> orderList = new List<Order__c>();
        
        
        Test.stopTest();
     }

}