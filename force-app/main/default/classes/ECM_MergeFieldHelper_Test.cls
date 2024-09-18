/*
* @Name: ECM_MergeFieldHelper_Test
* @description: This is Class for testing apex ECM_MergeFieldHelper
* @History   

VERSION    AUTHOR                   DATE              DETAIL
1.0     Veerendra Billakurthi     28/04/2020        Intial development
2.0     Pratik Somani    		  24/04/2022        Changes related to ECM-5386
3.0		Saurav Prasad			  10/11/2022		ECM-6306 : PF translation in Contract PDF
*/ 

@isTest
public class ECM_MergeFieldHelper_Test {
    @isTest
    public static void testECMMergeFieldHelper(){
        String outletId = contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String standate= String.valueOf(system.today());
        String dateStr = Date.today().format();
        
        
        //Added as part of ECM-5386->Start
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.MamagerSfdc4@test.com';
        usrmngr.Username ='test.MamagerSfdc4@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='AU';
        insert usrmngr;
        System.assert(usrmngr!=null,'usrmngr should not be null');
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc2@test.com';
        usr.Username ='test.MamagerSfdc2@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        
        Account testAccount = EDGE_UtilityTestClass.getOutletRecord();
        testAccount.OwnerId = usr.Id;
        insert testAccount;
        
        system.runAs(usr)
        {
            Test.startTest();
            
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
            Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
            mktSetting.ECM_Contract_Header_Details__c='ECM_Contract_Owner__c;ECM_Territory__r.Name;Account.ECM_Legal_Name__c;Account.Name;ECM_Agreement_Type__r.Name;StartDate;Contract_End_Date__c;ContractNumber;Name';
            mktSetting.ECM_Investment_Summary_KPIS__c='ECM_Total_Volume_Target_Spirits__c;ECM_Total_Volume_Target_Beers__c;ECM_Incremental_Volume_Spirits__c;ECM_Incremental_Volume_Beers__c;ECM_Total_trade_investment_Beers__c;ECM_Total_A_P_Investment_Spirits__c;ECM_Incremental_GP__c;ECM_Incremental_GP_Beers__c';
            mktSetting.ECM_Category_Split_KPIS__c='ECM_NSV_reserve_share__c;ECM_NSV_premium_core_share__c;ECM_GP_reserve_share__c;ECM_GP_innovation_share__c;ECM_GM_reserve_share__c;ECM_GM_innovation_share__c;ECM_GM_premium_core_share__c;ECM_TV_reserve_share__c;ECM_TV_premium_core_share__c;ECM_IV_reserve_share__c;ECM_IV_innovation_share__c;ECM_IV_premium_core_share__c';
            mktSetting.ECM_Product_Investment_Details__c='ECM_Retro_investment__c;ECM_Trade_Investments__c;ECM_AnP_investment__c;ECM_Gross_margin__c;ECM_Total_GP_EU__c;ECM_Generated_NSV_EU__c;ECM_NSV_After_Investment__c;ECM_Incremental_GP_after_Investment__c;Tiers;ECM_UoM__c;ECM_Baseline_volume__c;ECM_Volume__c;ECM_Incremental_Volume__c;ECM_CAAP_Total__c;ECM_Product_growth_driver__c';
            mktSetting.ECM_Sales_Drivers_Details__c='ECM_Investement_Description__c;ECM_Budget_Type__c;ECM_Payment_Frequency__r.ECM_Type__c;Payment dates;ECM_Total_Investment_Amount__c;ECM_Prepayment__c;ECM_Sales_Driver_Name__c';
            mktSetting.ECM_Attribute_Visibility_Screen1__c='Direct_Customer__c;Outlet_Visit_Prioritisation_Grade__c;Global_Segment__c';
            mktSetting.ECM_Contract_Creation_Page__c='Global';
            //mktSetting.ECM_Mandatory_field_for_Contract__c='SAP Ship To;';
            mktSetting.ECM_Contract_Management_Market__c=true;
            mktSetting.ECM_SAP_Order_Type__c='YPCR';
            mktSetting.ECM_Payment_Management_Email__c='test@test2.com';
            mktSetting.ECM_Email_to_Send_Payment_CSV__c='test@test3.com';
            mktSetting.ECM_Rounding_Off_Decimals_in_PDF__c = true;
            insert mktSetting;
            //Added as part of ECM-5386->End
            //Test.startTest();
            ECM_Payment_Frequency__c pfRec = ECM_UtilityTestClass.getPayFre(geographyId);
            pfRec.ECM_Type__c = 'Single Yearly Payments';
            pfRec.ECM_End_Date__c = true;
            insert pfRec;
            contract testContract = EDGE_UtilityTestClass.getContract(testAccount.id,outletId );
            testContract.ECM_Payment_Frequency_type__c =  pfRec.Id;
            System.debug(LoggingLevel.Debug,'testContract @'+testContract.ECM_Payment_Frequency__c);
            Insert testContract;
            Map<String,List<Sobject>> objMap = new Map<String,List<Sobject>>();
            objMap.put('Account',new List<Account>{testAccount});
            Contract con = [SELECT ECM_Total_GP__c,ECM_Overall_Investment_Figure__c,Contract_End_Date__c,ECM_Payment_Frequency__c FROM Contract WHERE Id=:testContract.Id];
            objMap.put('Contract',new List<Contract>{con});
            //ECM-6306
            Product__c prodRec = ECM_UtilityTestClass.createProduct(geographyId,'Johnny Walker');
            prodRec.Name='Johnny Walker Black Label';
            prodRec.UPIID__c='12345';
            prodRec.Product_Full_Name__c = 'Johnny Walker Black Label 7L';
            insert prodRec;
            Market_Assortment_Product__c mapRec = new Market_Assortment_Product__c(Product__c = prodRec.Id, Market_Assortment__c = geographyId);
            insert mapRec;
            ECM_Contract_Item__c ciRec = new ECM_Contract_Item__c(ECM_Contract__c = testContract.Id, ECM_Product__c = mapRec.Id);
            ciRec.ECM_Product_Growth_Driver__c = 'Gold/Silver';
            ciRec.ECM_A_P_Payment_Frequencies__c ='Monthly';
            ciRec.ECM_TI_Payment_Frequencies__c ='Yearly';
            insert ciRec;
            
            objMap.put('ECM_Contract_Item__c',new List<ECM_Contract_Item__c>{ciRec});
            
            map<String,ECM_GAS_Market_Translation__mdt> metaDataRecords = new map<String,ECM_GAS_Market_Translation__mdt>();
            map<String,String> objFieldMap = new map<String,String>();
            map<String,List<String>> fieldSetMap = new map<String,List<String>>();
            String languageForGAS='DE';
            
            for(ECM_GAS_Market_Translation__mdt metaData : 
                [SELECT MasterLabel, DeveloperName, ECM_Language_Code__c, 
                 ECM_Translation__c,ECM_Field_API_Name__c, ECM_Object_Name__c
                 FROM ECM_GAS_Market_Translation__mdt] ){
                     metaDataRecords.put(metaData.MasterLabel,metaData);
                     System.debug(LoggingLevel.Debug,'Outside loop @ ' + objFieldMap.keySet());
                     List<String> tempList = new List<String>();
                     tempList.addAll(objFieldMap.keySet());
                     System.debug(LoggingLevel.Debug,'Condition 1 @ '+metaData.ECM_Object_Name__c.split(';').equals(tempList));
                     System.debug(LoggingLevel.Debug,'Condition 2 @ '+metaData.ECM_Field_API_Name__c.split(';').equals(objFieldMap.values()));
                     if(!metaData.ECM_Object_Name__c.split(';').equals(tempList) &&
                        !metaData.ECM_Field_API_Name__c.split(';').equals(objFieldMap.values())){
                            System.debug(LoggingLevel.Debug,'Inside loop @');
                            for(Integer i=0;i<metaData.ECM_Object_Name__c.split(';').size();i++){
                                objFieldMap.put(metaData.ECM_Object_Name__c.split(';')[i],metaData.ECM_Field_API_Name__c.split(';')[i]);
                            }
                        }
                 }
            ECM_MergeFieldHelper.getMergeText('{!Account.Last_Modify_Data_Master__c} Test Message {!Account.Name}',objMap,standate,'AU',metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
            ECM_MergeFieldHelper.getMergeText('{!Contract.ECM_Total_GP__c} Test Message {!Contract.ECM_Overall_Investment_Figure__c}',objMap,dateStr,'AU',metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
            ECM_MergeFieldHelper.getMergeText('{!Contract.Contract_End_Date__c} Test Message {!Contract.Contract_End_Date__c}',objMap,dateStr,'AU',metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
            ECM_MergeFieldHelper.getMergeText('{!Contract.ECM_Payment_Frequency__c} Test Message {!Contract.Contract_End_Date__c}',objMap,dateStr,'DE',metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
            ECM_MergeFieldHelper.getMergeText('{!ECM_Contract_Item__c.ECM_A_P_Payment_Frequencies__c} Test Message {!ECM_Contract_Item__c.ECM_TI_Payment_Frequencies__c}',objMap,dateStr,'DE',metaDataRecords,objFieldMap,languageForGAS,fieldSetMap);
            ECM_MergeFieldHelper.getDateFormat('Account','Conversion_Date__c');
            ECM_MergeFieldHelper.getDateFormat('contract','ECM_Total_GP__c');
            ECM_MergeFieldHelper.getDateFormat('contract','ECM_EU_Total_Trade_Investment__c');
            
            Test.stopTest();
        }
    }
    
}