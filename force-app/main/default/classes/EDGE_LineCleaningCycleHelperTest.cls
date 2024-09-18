/**

* @Description : EDGE_LineCleaningCycleHelperTest

* @Purpose : Test EDGE_LineCleaningCycleHelper

* @History:

* @Version   Developer         Date            User Story	        

*   1.1		  Aparajita      09/12/2021		 ES20-10779(Method:checkLCCSharingTest)
*   1.2		  Joshraj Sen    04/12/2021		 ES20-10430(Method:calculateLineCleaningCycleEndDate,validateDuplicateStartdate,updateLineCleaningCycleHolidays)

*/

@isTest
public class EDGE_LineCleaningCycleHelperTest{
    
    /**
* @description checkSharingTest : To check the sharing of object
* @return void
* @param 
*/
    @isTest
    public static void checkLCCSharingTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting;   
        Line_Cleaning_Cycle__c lcc = new Line_Cleaning_Cycle__c();
        lcc.Name = 'Test LCC';
        lcc.Active__c=true;
        lcc.Start_Date__c = Date.today();
        lcc.End_Date__c = Date.today().addYears(1);
        lcc.Country__c = countryId;
        insert lcc;  
        List<Line_Cleaning_Cycle__c> lccList1 = new List<Line_Cleaning_Cycle__c>();
        lccList1.add(lcc);
        Map<Id, SObject> oldItems = new Map<Id, SObject>();
        Map<Id, Line_Cleaning_Cycle__c> lccMap = new Map<Id, Line_Cleaning_Cycle__c>();
        lccMap.put(lcc.Id,lcc);
        oldItems = (Map<Id, SObject>)lccMap;   
        EDGE_LineCleaningCycleHelper.checkAndGenerateSharing(lccList1);  
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'GB Country1';
        secCountry.Code__c = 'GB1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry; 
        Test.startTest();
        Market_Setting__c marketSetting1=EDGE_UtilityTestClass.getMarketSetting(secCountry.Id);
        marketSetting1.Threshold_Format__c = 'Percent';
        marketSetting1.A_P_Threshold__c = 10;
        marketSetting1.Manager_Threshold__c = null;
        marketSetting1.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting1;        
        lcc.Country__c = secCountry.Id;    
        update lcc;   
        List<Line_Cleaning_Cycle__c> lccList2 = new List<Line_Cleaning_Cycle__c>();
        lccList2.add(lcc);
        EDGE_LineCleaningCycleHelper.validateAndReGenerateSharing(lccList2,oldItems); 
        System.assert(lcc.Id != null,'lcc Id should not be null');  
        delete lcc;
        undelete lcc;
        Test.stopTest();
    }
     /**
* @description checkEndDateCalculation1 : To check the End Date Calculation on Insert
* @return void
* @param 
*/
    @isTest
    public static void checkEndDateCalculation1()
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
        Line_Cleaning_Cycle__c lc2=new Line_Cleaning_Cycle__c();
        lc2.Name='GB Line Cycle 2';
        lc2.Active__c=true;
        lc2.Start_Date__c =weekStart.addDays(46);
        //lc2.End_Date__c =null;
        lc2.Country__c=secCountry.Id;
        insert lc2; 
        Line_Cleaning_Cycle__c lc1=new Line_Cleaning_Cycle__c();
        lc1.Name='GB Line Cycle 1';
        lc1.Active__c=true;
        lc1.Start_Date__c =weekStart;
        //lc1.End_Date__c =null;
        lc1.Country__c=secCountry.Id;
        insert lc1; 
        Test.stopTest();
    }
      /**
* @description checkEndDateCalculation2 : To check the End Date Calculation on Update
* @return void
* @param 
*/
    @isTest
    public static void checkEndDateCalculation2()
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
        system.assert(secCountry.Id != null,'sec Country Id should not be null'); 
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(secCountry.Id);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting;
        date myDate = date.today();
        date weekStart = myDate.toStartofWeek();
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
        Line_Cleaning_Cycle__c lc2=new Line_Cleaning_Cycle__c();
        lc2.Name='GB Line Cycle 2';
        lc2.Active__c=true;
        lc2.Start_Date__c =weekStart.addDays(46);
        //lc2.End_Date__c =null;
        lc2.Country__c=secCountry.Id;
        insert lc2; 
        Line_Cleaning_Cycle__c lc1=new Line_Cleaning_Cycle__c();
        lc1.Name='GB Line Cycle 1';
        lc1.Active__c=true;
        lc1.Start_Date__c =weekStart;
        //lc1.End_Date__c =null;
        lc1.Country__c=secCountry.Id;
        insert lc1; 
        lc1.End_Date__c=weekStart.addDays(28);
        update lc1; 
        Test.stopTest();
    }
    
    
     /**
* @description checkDuplicateDate1 : To check the Duplicate Date on Insert
* @return void
* @param 
*/
    
    @isTest
    public static void checkDuplicateDate1()
    {
        try
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
            Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(secCountry.Id);
            marketSetting.Threshold_Format__c = 'Percent';
            marketSetting.A_P_Threshold__c = 10;
            marketSetting.Manager_Threshold__c = null;
            marketSetting.Line_Cleaning_Duration__c = 25.0;
            insert marketSetting;
            date myDate = date.today();
            date weekStart = myDate.toStartofWeek();
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
            Line_Cleaning_Cycle__c lc1=new Line_Cleaning_Cycle__c();
            lc1.Name='GB Line Cycle 1';
            lc1.Active__c=true;
            lc1.Start_Date__c =weekStart;
            //lc1.End_Date__c =null;
            lc1.Country__c=secCountry.Id;
            insert lc1; 
            Line_Cleaning_Cycle__c lc2=new Line_Cleaning_Cycle__c();
            lc2.Name='GB Line Cycle 2';
            lc2.Active__c=true;
            lc2.Start_Date__c =weekStart.addDays(8);
            //lc2.End_Date__c =null;
            lc2.Country__c=secCountry.Id;
            insert lc2;
            Test.stopTest();
        }
        catch(Exception e)
        {
            String message=e.getMessage();
            System.assert(message.contains(System.label.EDGE_LineCleaningCycle_Already_Part_Of_Active_Cycle),'null');
        }
    }
    
     /**
* @description checkDuplicateDate2 : To check the Duplicate Date on Update
* @return void
* @param 
*/
    @isTest
    public static void checkDuplicateDate2()
    {
        try
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
            Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(secCountry.Id);
            marketSetting.Threshold_Format__c = 'Percent';
            marketSetting.A_P_Threshold__c = 10;
            marketSetting.Manager_Threshold__c = null;
            marketSetting.Line_Cleaning_Duration__c = 25.0;
            insert marketSetting;
            date myDate = date.today();
            date weekStart = myDate.toStartofWeek();
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
            Line_Cleaning_Cycle__c lc1=new Line_Cleaning_Cycle__c();
            lc1.Name='GB Line Cycle 1';
            lc1.Active__c=true;
            lc1.Start_Date__c =weekStart;
            //lc1.End_Date__c =null;
            lc1.Country__c=secCountry.Id;
            insert lc1; 
            
            Line_Cleaning_Cycle__c lc2=new Line_Cleaning_Cycle__c();
            lc2.Name='GB Line Cycle 2';
            lc2.Active__c=true;
            lc2.Start_Date__c =weekStart.addDays(46);
            //lc2.End_Date__c =null;
            lc2.Country__c=secCountry.Id;
            insert lc2;
            lc2.Start_Date__c=weekStart.addDays(7);
            update lc2;
            Test.stopTest();
            
        }
        catch(Exception e)
        {
            String message=e.getMessage();
            System.assert(message.contains(System.label.EDGE_LineCleaningCycle_Already_Part_Of_Active_Cycle),'null');
        }
    }
}