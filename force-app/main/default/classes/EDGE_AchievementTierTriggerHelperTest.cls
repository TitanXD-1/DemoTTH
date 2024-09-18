/*
Name: EDGE_AchievementTierTriggerHelperTest
Req: 
ES20-4584 
History                                                            
VERSION   AUTHOR            DATE           DETAIL
1.0     Shahbaz Khan     07/01/2020        ES20-4584(method - preventOverlappingRangeTest)
*/
@isTest
public class EDGE_AchievementTierTriggerHelperTest {
	@isTest
    public static void preventOverlappingRangeTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId != null,'CountryId Inserted');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Bonus_Header__c bonusHeader = new Bonus_Header__c();
        bonusHeader.Country__c = countryId;
        insert bonusHeader;
        
        Bonus_Detail__c bonusDetail = new Bonus_Detail__c();
        bonusDetail.RecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('KPI').getRecordTypeId();
        bonusDetail.KPI_Type__c = 'OES';
        bonusDetail.Bonus_Header__c = bonusHeader.Id;
        bonusDetail.Weight__c = 100;
        insert bonusDetail;
        
        Achievement_Tier__c achTier = new Achievement_Tier__c();
        achTier.Bonus_Detail__c = bonusDetail.Id;
        achTier.Range_Start__c = 10;
        achTier.Range_End__c = 20;
        insert achTier;
        Achievement_Tier__c achTier1 = new Achievement_Tier__c();
        achTier1.Bonus_Detail__c = bonusDetail.Id;
        achTier1.Range_Start__c =25;
        achTier1.Range_End__c = 30;
        insert achTier1;
        try{
           achTier1.Range_Start__c = 15;
           update achTier1;
        }
        catch(Exception e){
            System.debug(logginglevel.Debug,'Error Faced '+e.getCause());
        }
        
       delete achTier1;
        undelete achTier1;
        
    }
}