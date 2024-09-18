/**

*@	Purpose: Test Class EDGE_OutletKPIAchivmntUniqKeyUpdateBatch 

*@	History                                                            

*@	VERSION     AUTHOR                  DATE              DETAIL
*@	1.0         Amar Deep               22/12/2020        [ES20-9194]
*@	2.0			Shivam/Rajarshi			04/05/2023	    ES20-14005,ES20-13960 
**/
@isTest
public class EDGE_OutletKPIAchvmntUniqUpdateBatchTest {
    @isTest
    public static void testOutletKPIAchtUniqKeyUpdateBatch(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletKPIAchivmntUniqKeyUpdateBatch'
                                                  and Country_Code__c ='AU'];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    public static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        system.assert(countryId!=null,'countryId should not be null');
        
        String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        Territory_Hierarchy__c terrHirBU = new Territory_Hierarchy__c();
        terrHirBU.RecordTypeId =terrHierBURecordTypeId;
        terrHirBU.Name = 'Australia Territory Hierarchy';
        terrHirBU.Geography__c = countryId;
        insert terrHirBU;
        
        Territory_Hierarchy__c terrHirSA = new Territory_Hierarchy__c();
        terrHirSA.RecordTypeId =terrHierSARecordTypeId;
        terrHirSA.Name = 'Australia Territory Hierarchy';
        terrHirSA.Geography__c = countryId;
        terrHirSA.Parent_BU__c = terrHirBU.Id;
        insert terrHirSA;
        
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'Australia Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG;
        
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Region__c = terrHirRG.id;
        territory.Pending_For_Batch__c = false;
         insert territory;
        
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        
        Test.startTest();
        
        List<Account> listOfOutlet = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        outlet.Pending_For_Outlet_KPI_Achievement__c = true;
        outlet.Primary_Sales_Territory__c = territory.id;
        listOfOutlet.add(outlet);
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet1.Independent_of_Owner__c = true;
        outlet1.Pending_For_Outlet_KPI_Achievement__c = true;
        outlet1.Primary_Sales_Territory__c = territory.id;
        outlet1.Global_Channel__c = 'On Trade';
        outlet1.Global_Sub_Channel__c = 'On Trade';
        outlet1.Global_Segment__c = 'Café';
        outlet1.Global_Sub_Segment__c = 'Modern Café';
        listOfOutlet.add(outlet1);
        insert listOfOutlet;
        
        List<KPIs_Target__c> lstKPITarget = new List<KPIs_Target__c>();
        KPIs_Target__c kpiTarget = new KPIs_Target__c();
        kpiTarget.Territory__c = territory.id;
        kpiTarget.Segment__c = 'Hypermarket';
        kpiTarget.Sub_Segment__c = 'Modern Hypermarket';
        kpiTarget.Name = 'Sample';
        kpiTarget.Target__c = 89;
        kpiTarget.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget);
        
        KPIs_Target__c kpiTarget1 = new KPIs_Target__c();
        kpiTarget1.Territory__c = territory.id;
        kpiTarget1.Segment__c = 'Hypermarket';
        kpiTarget1.Name = 'SampleHypermarket';
        kpiTarget1.Target__c = 85;
        kpiTarget1.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget1);
        
        KPIs_Target__c kpiTarget2 = new KPIs_Target__c();
        kpiTarget2.Territory__c = territory.id;
        kpiTarget2.Segment__c = 'Café';
        kpiTarget2.Name = 'Sample';
        kpiTarget2.Target__c = 89;
        kpiTarget2.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget2);
        
        insert lstKPITarget;
        
        List<Outlet_KPI_Achievement__c> outletKPIAcivmtList = new List<Outlet_KPI_Achievement__c>();
        Outlet_KPI_Achievement__c outKPIAch = new Outlet_KPI_Achievement__c();
        outKPIAch.Target__c=90;
        outKPIAch.KPI_Type__c = 'SoS';
        outKPIAch.Category__c = 'Gin';
        outKPIAch.Outlet__c = outlet.id;
        outletKPIAcivmtList.add(outKPIAch);
        
        Outlet_KPI_Achievement__c outKPIAch1 = new Outlet_KPI_Achievement__c();
        outKPIAch1.Target__c=90;
        outKPIAch1.KPI_Type__c = 'SoS';
        outKPIAch1.Category__c = 'Liqueur';
        outKPIAch1.Outlet__c = outlet.id;
        outletKPIAcivmtList.add(outKPIAch1);
        
        Outlet_KPI_Achievement__c outKPIAch2 = new Outlet_KPI_Achievement__c();
        outKPIAch2.Target__c=90;
        outKPIAch2.KPI_Type__c = 'SoS';
        outKPIAch2.Category__c = 'Beer';
        outKPIAch2.Outlet__c = outlet1.id;
        outletKPIAcivmtList.add(outKPIAch2);
        
        Outlet_KPI_Achievement__c outKPIAch3 = new Outlet_KPI_Achievement__c();
        outKPIAch3.Target__c=90;
        outKPIAch3.KPI_Type__c = 'SoS';
        outKPIAch3.Category__c = 'Beer';
        outKPIAch3.Outlet__c = outlet1.id;
        outletKPIAcivmtList.add(outKPIAch3);
        insert outletKPIAcivmtList;
        Test.stopTest();
    }

}