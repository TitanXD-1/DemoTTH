@isTest
public class ECM_ContractItemTriggerHelper_Test {
    @isTest
    public static void testMethod1(){
        List<ECM_Contract_Item__c> lstConItem1 = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> lstConItem2 = new List<ECM_Contract_Item__c>();
        Map<Id, SObject> items = new Map<Id, SObject>();
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='LI[ES]';
        insert pOption;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;  
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');
        
        Test.startTest();
        
        Contract con1 = new Contract();
        con1.Name = 'Test Contract 1';
        con1.AccountId = acc.Id;
        con1.Contract_End_Date__c = System.today();
        insert con1;
        
        ECM_Contract_Item__c conit1 = new ECM_Contract_Item__c();
        conit1.ECM_Contract__c = con1.Id;
        //conit1.ECM_NSV_After_TI__c=10;
        lstConItem1.add(conit1);
        
        ECM_Contract_Item__c conit3 = new ECM_Contract_Item__c();
        conit3.ECM_Contract__c = con1.Id;
        conit3.ECM_CTD_Total_NSV__c=10;
        //conit3.ECM_CTD_Overall_Investment__c = 100 ;
        lstConItem1.add(conit3);
        
        Contract con3 = new Contract();
        con3.Name = 'Test Contract 1';
        con3.AccountId = acc.Id;
        con3.Contract_End_Date__c = System.today();
        insert con3;
        
        ECM_Contract_Item__c conit5 = new ECM_Contract_Item__c();
        conit5.ECM_Contract__c = con3.Id;
        conit5.ECM_Net_Net_List_Price__c = 2;
        conit5.ECM_UoM__c = '1';
        conit5.ECM_CTD_Trade_Lump_Sum__c = 5;
        conit5.ECM_CTD_Overall_Investment__c = 100 ;
        //conit4.ECM_CTD_GP__c=100;
        lstConItem1.add(conit5);
        
        
        Contract con2 = new Contract();
        con2.Name = 'Test Contract 2';
        con2.AccountId = acc.Id;
        con2.Contract_End_Date__c = System.today();
        con2.ECM_Parent_Contract__c = con3.id;
        con2.ECM_Amended__c = true;
        insert con2;
        
       
        
        ECM_Contract_Item__c conit4 = new ECM_Contract_Item__c();
        conit4.ECM_Contract__c = con2.Id;
        conit4.ECM_Net_Net_List_Price__c = 2;
        conit4.ECM_UoM__c = '1';
        conit4.ECM_CTD_Trade_Lump_Sum__c = 5;
        conit4.ECM_CTD_Overall_Investment__c = 100 ;
        //conit4.ECM_CTD_GP__c=100;
        lstConItem1.add(conit4);
        
        ECM_Contract_Item__c conit2 = new ECM_Contract_Item__c();
        conit2.ECM_Contract__c = con1.Id;
        conit2.ECM_CTD_A_P_Investment__c=20;
        conit2.ECM_CTD_Overall_Investment__c = 0 ;
        
        lstConItem1.add(conit2);
        insert lstConItem1;
        
        conit3.ECM_CTD_Total_NSV__c=null;
        conit2.ECM_CTD_A_P_Investment__c=33;
        conit4.ECM_Actual_Volume_YTD__c = 10;
        conit5.ECM_Actual_Volume_YTD__c = 10;
        
        update lstConItem1;
        
        conit2.ECM_CTD_A_P_Investment__c=null;
        conit3.ECM_CTD_Total_NSV__c=32;
        update lstConItem1;
        
        delete conit3;
        delete conit2;
        
        ECM_ContractItemTriggerHelper.disableConItem(Null, items);
        ECM_ContractItemTriggerHelper.disableConItemEdit(lstConItem1);
        
        lstConItem2.addAll(lstConItem1);
        ECM_ContractItemTriggerHelper.disableConItemDelete(lstConItem2);
        Test.stopTest();
    }
    @isTest
    static void testMethod2(){
        List<ECM_Contract_Item__c> lstConItem1 = new List<ECM_Contract_Item__c>();
        Map<Id, SObject> items = new Map<Id, SObject>();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');
        
        Contract con1 = new Contract();
        con1.Name = 'Test Contract 1';
        con1.AccountId = acc.Id;
        con1.Contract_End_Date__c = System.today();
        insert con1;
        System.assert(con1.id!=null,'con1 id should not be null');
        
        ECM_Contract_Item__c conit1 = new ECM_Contract_Item__c();
        conit1.ECM_Contract__c = con1.Id;
        insert conit1;
        lstConItem1.add(conit1);
        
        ECM_Contract_Item__c conit3 = new ECM_Contract_Item__c();
        conit3.ECM_Contract__c = con1.Id;
        insert conit3;
        lstConItem1.add(conit3);
        
        ECM_Contract_Item__c conit4 = new ECM_Contract_Item__c();
        conit4.ECM_Contract__c = con1.Id;
        insert conit4;
        lstConItem1.add(conit4);
        
        for(ECM_Contract_Item__c ci : lstConItem1){
            items.put(ci.Id, ci);
        }
        
        System.debug(LoggingLevel.debug,'lstConItem1 : '+lstConItem1);
        System.debug(LoggingLevel.debug,'Items : '+items);
        try{
            ECM_ContractItemTriggerHelper.rollUpsCalalter(lstConItem1, items);
        }
        catch(TypeException te){
            system.debug(LoggingLevel.debug,'Error ');
        }
        
    }
}