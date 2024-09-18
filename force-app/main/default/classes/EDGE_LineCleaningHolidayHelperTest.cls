/**

* @Description : EDGE_LineCleaningHolidayHelperTest

* @Purpose : Test EDGE_LineCleaningHolidayHelper

* @History:

* @Version     Developer       Date            User Story	        

*   1.1		   Aparajita     09/12/2021		  ES20-10780(Method:testLCHoliday,checkLCHSharingTest)
*   2.2        Supriya       10/12/2021		  ES20-10437(Method:calcEndDatefromHolidayTest)
*/

@isTest
public class EDGE_LineCleaningHolidayHelperTest{
    
    @isTest
    public static void testLCHoliday(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'pick up Option Id should not be null');
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert outlet;
        system.assert(outlet.Id != null,'outlet Id should not be null');
        
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting;
        
        Test.startTest();
        Line_Cleaning_Cycle__c lcc = new Line_Cleaning_Cycle__c();
        lcc.Name = 'Test LCC';
        lcc.Active__c=true;
        lcc.Start_Date__c = Date.today();
        lcc.End_Date__c = Date.today().addYears(1);
        lcc.Country__c = countryId;
        insert lcc;   
        
        Line_Cleaning_Holiday__c lch = new Line_Cleaning_Holiday__c();
        lch.Active__c=true;
        lch.Exclusion_Date__c = Date.today().addYears(1);
        lch.Line_Cleaning_Cycle__c = lcc.Id;
        lch.Country__c = countryId;
        insert lch;         
        update lch;       
        Test.stopTest();
        System.assert(lch.Id != null,'lch Id should not be null');
    }
    
    @isTest
    public static void checkLCHSharingTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
       
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting; 
        Test.startTest();        
        Line_Cleaning_Holiday__c lch = new Line_Cleaning_Holiday__c();
        lch.Active__c=true;
        lch.Exclusion_Date__c = Date.today().addYears(1);
        lch.Country__c = countryId;
        insert lch;  
        
        List<Line_Cleaning_Holiday__c> lchList1 = new List<Line_Cleaning_Holiday__c>();
        lchList1.add(lch);
        Map<Id, SObject> oldItems = new Map<Id, SObject>();
        Map<Id, Line_Cleaning_Holiday__c> lchMap = new Map<Id, Line_Cleaning_Holiday__c>();
        lchMap.put(lch.Id,lch);
        oldItems = (Map<Id, SObject>)lchMap;
        
        EDGE_LineCleaningHolidayHelper.checkAndGenerateSharing(lchList1);
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'GB Country1';
        secCountry.Code__c = 'GB1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        Market_Setting__c marketSetting1=EDGE_UtilityTestClass.getMarketSetting(secCountry.Id);
        marketSetting1.Threshold_Format__c = 'Percent';
        marketSetting1.A_P_Threshold__c = 10;
        marketSetting1.Manager_Threshold__c = null;
        marketSetting1.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting1;      
        
        lch.Country__c = secCountry.Id;    
        update lch;  
              
        List<Line_Cleaning_Holiday__c> lchList2 = new List<Line_Cleaning_Holiday__c>();
        lchList2.add(lch);
        EDGE_LineCleaningHolidayHelper.validateAndReGenerateSharing(lchList2,oldItems);
         
        System.assert(lch.Id != null,'lch Id should not be null');  
        delete lch;
        undelete lch;
        Test.stopTest();
    }
    @isTest
    public static void calcEndDatefromHolidayTest()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        test.startTest();
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'GB Country1';
        secCountry.Code__c = 'GB1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry; 
        system.assert(secCountry.Id!=null,'sec Country Id should not be null'); 
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(secCountry.Id);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting;
        date myDate = date.today();
        date weekStart = myDate.toStartofWeek();        
         Line_Cleaning_Cycle__c lc2=new Line_Cleaning_Cycle__c();
        lc2.Name='GB Line Cycle 2';
        lc2.Active__c=true;
        lc2.Start_Date__c =weekStart.addDays(46);
        lc2.End_Date__c =null;
        lc2.Country__c=secCountry.Id;
        insert lc2; 
        Line_Cleaning_Cycle__c lc1=new Line_Cleaning_Cycle__c();
        lc1.Name='GB Line Cycle 1';
        lc1.Active__c=true;
        lc1.Start_Date__c =weekStart;
        lc1.End_Date__c =null;
        lc1.Country__c=secCountry.Id;
        insert lc1; 
        
        Line_Cleaning_Holiday__c lh2=new Line_Cleaning_Holiday__c();
        lh2.Active__c=true;
        lh2.Exclusion_Date__c=weekStart.addDays(7);   
        lh2.Line_Cleaning_Cycle__c=null;
        lh2.Country__c=secCountry.Id;
        insert lh2;
        
        Line_Cleaning_Holiday__c lh1=new Line_Cleaning_Holiday__c();
        lh1.Active__c=true;
        lh1.Exclusion_Date__c=weekStart.addDays(14);
        lh1.Line_Cleaning_Cycle__c=null;
        lh1.Country__c=secCountry.Id;
        insert lh1;
         
        lh1.Exclusion_Date__c = weekStart.addDays(16);
        update lh1;
        
        delete lh2;
        
    }
}