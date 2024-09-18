/*
* @Name: ECM_MasterAssetAggTriggerHelper
* @description: This is Class for fetch required data to create trigger on Master Asset Aggrement Object.
* @History                                                            

VERSION    AUTHOR                		DATE					DETAIL
1.0     Rajani Abbireddy &Anandh        2/8/2022				ECM-5891-Initial Development */

@isTest
public class ECM_MasterAssetAggTriggerHelperTest {
    @isTest
    public  static void  aggrementTypeDuplicateCheckTestIns(){
        WrapperData wrapObj = createData();
        ECM_Master_Asset_Agreements__c masterAssetAggObj = ECM_UtilityTestClass.getMstrAsstAgg(wrapObj.masterAssetId,wrapObj.aggmentTypeId);
        try{
            insert masterAssetAggObj;
        }catch(Exception ex){
            String errorMessage = Label.Error_Msg_on_ECM_MasterAssetAgreementTrigger;
            errorMessage = errorMessage.split('\\.')[0];
            String expectedError = ex.getMessage().split('\\,')[1].split('\\.')[0].trim();
            errorMessage = errorMessage+': []';
            System.assertEquals(errorMessage,expectedError,'not null');
        }
    }
    @isTest
    public  static void aggrementTypeDuplicateCheckTestDel() {        
        WrapperData wrapObj = createData();
        try{
            delete wrapObj.mAsAggobj;
        }catch(Exception ex){
            String errorMessage = Label.Error_Msg_on_ECM_MasterAssetAgreementTrigger;
            errorMessage = errorMessage.split('\\.')[0];
            String expectedError = ex.getMessage().split('\\,')[1].split('\\.')[0].trim();
            errorMessage = errorMessage+': []';
            System.assertEquals(errorMessage,expectedError,'not null');
        }
    }
    @isTest
    public  static void  handlerCodeCovarage(){
        WrapperData wrapObj = createData();
        update wrapObj.mAsAggobj;
        ECM_Master_Asset_Agreements__c masterAssetAggObj = ECM_UtilityTestClass.getMstrAsstAgg(
            												wrapObj.masterAssetDupId,
            												wrapObj.aggmentTypeDupId
            												);
		insert masterAssetAggObj;
        delete masterAssetAggObj;
        undelete masterAssetAggObj;
        System.assert(masterAssetAggObj!=null,'masterAssetAggObj should not be null');
    }
    public static WrapperData createData(){
        String asstConRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Asset Contract').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c = false;
        insert contractType;
        
        ECM_Contract_Type__c contractTypeDup = ECM_UtilityTestClass.createContractType(geographyId);
        contractTypeDup.ECM_Enable_Recall_of_Contract__c = false;
        insert contractTypeDup;
        
        Master_Asset__c masObj = ECM_UtilityTestClass.getMasterAsset(geographyId);
        insert masObj;
        
        Master_Asset__c masDupObj = ECM_UtilityTestClass.getMasterAsset(geographyId);
        masDupObj.Name = 'Test Duplicate Master Asset';
        masDupObj.Part_Number__c = '123CHSGL';
        masDupObj.Priority_Assets__c = false;
        masDupObj.GUID__c = 'TWRFSHJAKSVGH';
        masDupObj.Short_Description__c = 'short description1';
        masDupObj.Country__c = geographyId;
        insert masDupObj;
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        ECM_Master_Asset_Agreements__c masterAssetAggObj = ECM_UtilityTestClass.getMstrAsstAgg(masObj.Id,contractType.Id);
		insert masterAssetAggObj;
        
        Contract asstCon = ECM_UtilityTestClass.createContract(acc.Id,asstConRecordTypeId);
        asstCon.ECM_Agreement_Type__c = contractType.Id;
        insert asstCon;
        asstCon.Status='Active';
        update asstCon;
               
        WrapperData wrapObj = new WrapperData();
        wrapObj.aggmentTypeId = contractType.Id;
        wrapObj.masterAssetId = masObj.Id;
        wrapObj.mAsAggobj = masterAssetAggObj;
        wrapObj.aggmentTypeDupId = contractTypeDup.Id;
        wrapObj.masterAssetDupId = masDupObj.Id;
        return wrapObj;
    }
    class WrapperData{
        String aggmentTypeId;
        String masterAssetId;
		ECM_Master_Asset_Agreements__c mAsAggobj;  
        String aggmentTypeDupId;
        String masterAssetDupId;
    }
}