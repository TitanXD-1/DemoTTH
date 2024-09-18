/**********************************************************************
Name: EDGE_AccountPromotionTriggerHelperTest
=======================================================================
Req: 
ES20-198 - 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Monalisa Halder    14/05/2019      Initial Development
2.0    Swaraj Samanta     05/09/2022      Test Class Correction due to Failure(ES20-13284)

***********************************************************************/
@isTest
public class EDGE_AccountPromotionTriggerHelperTest {
    @isTest
    public static void validateAccountPromotionCycle(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        
        Account distAccount = EDGE_UtilityTestClass.getDistriAccRec();
        insert distAccount;
        system.assert(distAccount.Id != null,'DistAccount Inserted');
        List<Promotion__c> promotions=new List<Promotion__c>();
        Promotion__c promo = EDGE_UtilityTestClass.getPromotionRecord(countryId );
        promotions.add(promo);
        //system.assert(promo.Id != null);
        
        Promotion__c promo1 = EDGE_UtilityTestClass.getPromotionRecord(countryId );
        promotions.add(promo1);
        
        Promotion__c promotion2 = EDGE_UtilityTestClass.getPromotionRecord(countryId );
        promotion2.Start_Date__c = System.today().addDays(7);
        promotion2.Expiration_Date__c = System.today().addDays(10);
        promotions.add(promotion2);
        insert promotions;
        Test.startTest();
        List<Account_Promotion__c> accountPromotions=new List<Account_Promotion__c>();
        Account_Promotion__c accPromo = EDGE_UtilityTestClass.getAccountPromotion(distAccount.Id, promo.Id);
        accountPromotions.add(accPromo);
        
        
        Account_Promotion__c accPromo1 = EDGE_UtilityTestClass.getAccountPromotion(distAccount.Id, promo1.Id);
        
        Account_Promotion__c accPromo2 = EDGE_UtilityTestClass.getAccountPromotion(distAccount.Id, promotion2.Id);
        accountPromotions.add(accPromo2);
        insert accountPromotions;
        update accPromo;
        delete accPromo2;
        
        try{
            insert accPromo1;
            
        }catch(Exception ex){
            //Checking one Promotion time frame Validation Rule
            System.debug(logginglevel.Debug,'Get Message '+ex.getMessage().contains(Label.PromotionTimeFrame));
        }
        Test.stopTest();        
    }
}