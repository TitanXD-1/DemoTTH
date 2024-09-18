/**********************************************************************
Name: EDGE_CreatePromotionControllerTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Kapil Baliyan     05/06/2019     Test Class for EDGE_CreatePromotionController

***********************************************************************/
@isTest
public class EDGE_CreatePromotionControllerTest {
    
    @isTest
    public static void insertAccPromotionTest()
    {
        List<Account_Promotion__c> accPromotionList= new List<Account_Promotion__c>();
        List<Account> lstAcc = new List<Account>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId=EDGE_UtilityTestClass.setupCountry('PL');
        Promotion__c promo=EDGE_UtilityTestClass.getPromotionRecord(countryId);        
        insert promo;

        Account account=EDGE_UtilityTestClass.getDistriAccRec();
        account.BillingCountry='Poland';
        account.BillingState='LUBUSKIE';    
        lstAcc.add(account);
        
        /*User distManager1 = EDGE_UtilityTestClass.runAsUser('distMngr','Distributor Data Manager');
        distManager1.Available_Countries__c = 'AU';
        insert distManager1; 
        system.assert(distManager1.id != null);*/
        
        Account owner=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        //owner.Person_Responsible__c =distManager1.id; 
        owner.BillingCountry='Poland';
        owner.BillingState='LUBUSKIE';
        //owner.Person_Responsible__c = distManager1.id;
        owner.IsOperator__c = TRUE;
        lstAcc.add(owner);
        insert lstAcc;
        system.assert(lstAcc != null,'Account List is empty');
        
        Test.startTest();
        Account_Promotion__c accPromo=EDGE_UtilityTestClass.getAccountPromotion(account.Id,promo.Id);
        
        Account_Promotion__c accPromo1=EDGE_UtilityTestClass.getAccountPromotion(owner.Id,promo.Id); 
        accPromotionList.add(accPromo);
        accPromotionList.add(accPromo1);
        
        EDGE_CreatePromotionController.insertAccPromotion(accPromotionList);
        EDGE_CreatePromotionController.getAccounts();
        Test.stopTest();
    }    
    @isTest
    public static void accPromotionTestException()
    {
        List<Account_Promotion__c> accPromotionList= new List<Account_Promotion__c>();
        List<Account> lstAcc = new List<Account>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId=EDGE_UtilityTestClass.setupCountry('PL');
        Promotion__c promoObj = EDGE_UtilityTestClass.getPromotionRecord(countryId);        
        insert promoObj;
        
        Account account=EDGE_UtilityTestClass.getDistriAccRec();
        account.BillingCountry='Poland';
        account.BillingState='LUBUSKIE';
        lstAcc.add(account);
        
        /*User distManager = EDGE_UtilityTestClass.runAsUser('distMngr','Distributor Data Manager');
        distManager.Available_Countries__c = 'AU';
        insert distManager; 
        system.assert(distManager.id != null);*/
        
        Account owner=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        //owner.Person_Responsible__c = distManager.Id;
        owner.BillingCountry='Poland';
        owner.BillingState='LUBUSKIE';
        //owner.Person_Responsible__c = distManager.Id;
        owner.IsOperator__c = TRUE;
        lstAcc.add(owner);
        insert lstAcc;
        
        system.assert(lstAcc != null,'Account List is empty');
        
        Account_Promotion__c accPromo=EDGE_UtilityTestClass.getAccountPromotion(account.Id,promoObj.Id);
        
        Account_Promotion__c accPromo1=EDGE_UtilityTestClass.getAccountPromotion(promoObj.Id,owner.Id);// to throw exception
        
        accPromotionList.add(accPromo);
        accPromotionList.add(accPromo1);
        Test.startTest();
        try{
            EDGE_CreatePromotionController.insertAccPromotion(accPromotionList);
            //EDGE_CreatePromotionController.getAccounts();
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());    
        }
        
        Test.stopTest();
    }
}