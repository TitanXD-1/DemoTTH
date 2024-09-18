/**********************************************************************
Name: EDGE_ContractStatusUpdateBatchTest
=======================================================================
Req: This is the test class for EDGE_ContractStatusUpdateBatch
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Monalisa Halder     24/07/2019      Initial Development
2.0       Prasanth T          23/09/2022      ES20-13324(Test Class Correction Due to Failure)
***********************************************************************/
@isTest
public class EDGE_ContractStatusUpdateBatchTest{
    
    /*******************************************************************
    Method  : contractStatusUpdate
    Purpose : To cover EDGE_ContractStatusUpdateBatch class
    ********************************************************************/
    @isTest
    public static void contractStatusUpdate(){
         
        createData();
       
        try{ 
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_ContractStatusUpdateBatch'
                                                      and Country_Code__c ='AU' ];
            
            //List<Promotion__c> promList = [Select id , name from Promotion__c];
            //System.assert(promList.size()!=null);
            System.assert(batchSetting.Id !=null,'batchSetting should not be null');
            
            String className = batchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
         }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        Test.stopTest();
        
    }
    
    /*******************************************************************
    Method  : createData
    Purpose : To create test data
    ********************************************************************/   
    static void createData(){
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        Market_Setting__c marketSettingRec = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        marketSettingRec.A_P_Contract_Extension_Frequency__c = 'Weekly';
        insert marketSettingRec;
        
        EDGE_UtilityTestClass.createOrgSettings();
        list<Account> ownerAccts = new list<Account>();
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        ownerAccount.IsOwner__c=true;
        ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccts.add(ownerAccount);
        
        //insert ownerAccount;
        
        //System.assert(ownerAccount.Id != null);
        
        Account ownerAccount1 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount1.Name = 'OwnerAccount1';
        ownerAccount1.BillingCountry = 'Australia';
        ownerAccount1.BillingState = 'New South Wales';
        ownerAccount1.IsOwner__c=true;
        ownerAccount1.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount1.Country__c = geographyId;
        //insert ownerAccount1;
        ownerAccts.add(ownerAccount1);
        insert ownerAccts;
        //System.assert(ownerAccount1.Id != null);
        Test.startTest();
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract.StartDate = System.today()-10;
        objContract.Contract_End_Date__c = System.today()-1;
        insert objContract;
        
        Contract objContract1 = EDGE_UtilityTestClass.getContract(ownerAccount1.Id, contractRecordTypeId);
        objContract1.StartDate = System.today()-20;
        objContract1.Contract_End_Date__c = System.today()-11;
        objContract1.UOS_Target__c = 45;
        objContract1.UOS_Earnt__c = 46;
        insert objContract1;
        objContract1.Status = 'Active';
        update objContract1;
        
        Contract objContract2 = EDGE_UtilityTestClass.getContract(ownerAccount1.Id, contractRecordTypeId);
        objContract2.StartDate = System.today()-30;
        objContract2.Contract_End_Date__c = System.today()-21;
        objContract2.UOS_Target__c = 45;
        objContract2.UOS_Earnt__c = 40;
        insert objContract2;
        objContract2.Status = 'Active';
        update objContract2;
                
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        outletAccount.Independent_of_Operator__c = true;
        outletAccount.Independent_of_Owner__c = true;
        insert outletAccount;
        System.assert(outletAccount.Id != null,'outletAccount should not be null');
        
        Outlet_Contract__c outletContract = new Outlet_Contract__c();
        outletContract.Contract__c = objContract1.Id;
        outletContract.Status__c = 'Active';
        outletContract.Outlet__c = outletAccount.Id;
        insert outletContract;
        
        
    }
    
    
}