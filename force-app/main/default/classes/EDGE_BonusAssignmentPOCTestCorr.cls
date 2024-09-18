/**********************************************************************
Name: EDGE_BonusAssignmentTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Sandip Ghosh     08-Jan-2020      Test Class for EDGE_BonusAssignmentTriggerHelper
***********************************************************************/
@isTest
public class EDGE_BonusAssignmentPOCTestCorr {
    
    private static String bonushdrRecordTypeId = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
    private static String bonusdtlRecordTypeId = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
    private static String bonusdtlKPIRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('KPI').getRecordTypeId();
    private static String bonusdtlKPIPrdRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('KPI - Product Level').getRecordTypeId();
    private static String bonusdtlSurveyRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey').getRecordTypeId();
    private static Boolean isPrintFlagON = true;
    private static String countryCode = 'AU';
    
    @testSetup
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry(countryCode);
        EDGE_UtilityTestClass.createOrgSettings(); 
        List<Territory__c> territoryList = new List<Territory__c>();
        List<Territory_Hierarchy__c> terrHierarchies = new List<Territory_Hierarchy__c>();        
        
        //Territory Hierarchy records creation for all different recordtypes
        String buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        terrHierarchies.add(terrHierBsUnitobj);
        insert terrHierBsUnitobj;
        
        String saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        terrHierarchies.add(terrHierSalAreaobj);
        insert terrHierSalAreaobj;
        test.startTest();
        
        String reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj.Parent_BU__c= terrHierSalAreaobj.Id;
        terrHierarchies.add(terrHierRegionobj);
        insert terrHierRegionobj;
        
        //Terrory record creation to populate Sales Area and Business Unit
        for(Integer terrCount = 1; terrCount <= 3; terrCount++){
            Territory__c territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
            territoryObj.name = 'Territory'+terrCount;
            territoryObj.Territory_Type__c = 'Sales';
            territoryObj.Region__c = terrHierRegionobj.Id;
            territoryList.add(territoryObj);
        }       
        
        Database.insert(territoryList);
        printLine('territoryList', territoryList);
        system.assert(territoryList.size()>0,'TerritoryList should must have some value');
        printGovnLimits();
        
        String supplierRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliverPartner = new Delivery_Partner__c();
        deliverPartner.Name ='testPartner';
        deliverPartner.DP_Id__c = '12sdefr';
        deliverPartner.Email__c = 'abc@xyz.com';
        deliverPartner.Vendor_Number__c = 1234;
        deliverPartner.Country__c = countryId;
        deliverPartner.Street__c = 'Burns bay';
        deliverPartner.City__c = 'Sydney';
        deliverPartner.Postal_Code__c = '6003';
        deliverPartner.RecordTypeId=supplierRecordTypeId;
        insert deliverPartner;
        system.assert(deliverPartner.Id != null,'Delivery Partner should not be null');
        
        //Creating Business Role Record
        String skuRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name = 'Test Product';
        product.Supplier_Partner__c = deliverPartner.Id;
        product.Product_Code__c = 'Test1123';
        product.Diageo_Cost__c = 12;
        product.A_P_Cost__c = 14;
        product.POS_Related_Brand__c ='test';
        product.Units_per_POS__c =12;
        product.Limit_Per_Order__c = 12;
        product.Outlet_Cost__c = 12;
        product.POS_Related_Item__c = 'test';
        product.SAP_IO_Number__c = 'test'; 
        product.Pricing_Type__c = 'By Unit';
        product.Country__c = countryId;
        product.RecordTypeId = skuRecordTypeId;
        product.POS_Item_Short_Description__c = 'test';
        product.Start_Date__c =  Date.today();
        //product.Expiry_Date__c =  Date.today();
        insert product; 
        test.stopTest();
        System.assert(product.Id != null,'Product Id should not be null');
        
        //change
        Territory__c territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Territory_Type__c = 'Service';
        territoryObj.Country__c = countryId;
        insert territoryObj;
        List<Bonus_Header__c> bonusHeaders=new List<Bonus_Header__c>();
        Bonus_Header__c bonusHeader1 = new Bonus_Header__c();
        bonusHeader1.Country__c = countryId;
        bonusHeader1.Status__c = 'Draft';
        bonusHeaders.add(bonusHeader1);
        Bonus_Header__c bonusHeader2 = new Bonus_Header__c();
        bonusHeader2.Country__c = countryId;
        bonusHeader2.Status__c = 'Draft';
        bonusHeaders.add(bonusHeader2);
        insert bonusHeaders;
        List<Bonus_Detail__c> bonusDetails=new List<Bonus_Detail__c>();
        Bonus_Detail__c bonusDetail=new Bonus_Detail__c();
        bonusDetail.Bonus_Header__c=bonusHeader1.Id;
        bonusDetail.KPI_Type__c='MPA';
        bonusDetail.Weight__c=20;
        bonusDetail.RecordTypeId=bonusdtlKPIRecordTypeId;
        bonusDetails.add(bonusDetail);
        Bonus_Detail__c bonusDetail2=new Bonus_Detail__c();
        bonusDetail2.Bonus_Header__c=bonusHeader2.Id;
        bonusDetail2.KPI_Type__c='NPD';
        bonusDetail2.Weight__c=30;
        bonusDetail2.RecordTypeId=bonusdtlKPIPrdRecordTypeId;
        bonusDetail2.Product__c=product.Id;
        bonusDetails.add(bonusDetail2);
        insert bonusDetails;
        
        List<Bonus_Assignment__c> bonusAssignments=new List<Bonus_Assignment__c>();
        Bonus_Assignment__c bonusAssignment1 = new Bonus_Assignment__c();
        bonusAssignment1.Bonus_Header__c = bonusHeader2.Id;
        bonusAssignment1.Territory__c =  territoryList[1].Id;
        bonusAssignment1.Global_Percentage__c = 60;
        bonusAssignment1.Territory_Percentage__c = 30;
        bonusAssignment1.Total__c = 90;
        bonusAssignment1.Bonus_Detail__c=bonusDetail.Id;
        bonusAssignment1.RecordTypeId=bonushdrRecordTypeId;
        bonusAssignments.add(bonusAssignment1);
        Bonus_Assignment__c bonusAssignment2 = new Bonus_Assignment__c();
        bonusAssignment2.Bonus_Header__c = bonusHeader2.Id;
        bonusAssignment2.Territory__c = territoryObj.Id;
        bonusAssignment2.Global_Percentage__c = 60;
        bonusAssignment2.Territory_Percentage__c = 30;
        bonusAssignment2.Total__c = 90;
        bonusAssignment2.Bonus_Detail__c=bonusDetail2.Id;
        bonusAssignment2.RecordTypeId=bonusdtlRecordTypeId;
        bonusAssignments.add(bonusAssignment2);
        insert bonusAssignments;
        //System.assert(bonusAssignment1.Id != null);
        
        try{
            bonusHeader1.Status__c = 'Active';
            update bonusHeader1;
            bonusAssignment1.Global_Percentage__c = 70;
            update bonusAssignment1;
            
        }catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        
    }
    
    @isTest
    public static void testHeaderCreation(){
        List<Product__c> productList = [Select Id from Product__c where Name ='Test Product'];
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        system.assert(countryList.size() > 0,'countryList should must have some value');
        Id countryId = countryList[0].Id;
        
        if(productList != null && productList.size() > 0){           
            Test.startTest();
            List<Bonus_Header__c> bonusHeaderList = createBonusHeaders(productList[0].Id, countryId);
            system.assert(bonusHeaderList.size() > 0,'bonusHeaderList should must have some value');
            Test.stopTest();
        }
    }
    
  /*  @isTest
    public static void testBonusDetailsCreation(){
        
        
        
    }*/
    
    @isTest
    public static void testBonusAssignmentsCreation(){
        
        List<Bonus_Assignment__c> bonusAssignments = new List<Bonus_Assignment__c>();
        Map<String, Bonus_Detail__c> bonusDetailKPITypeToRecMap = new Map<String, Bonus_Detail__c>();
        List<Product__c> productList = [Select Id from Product__c where Name ='Test Product'];
        //system.assert(productList.size() > 0);
        //List<Bonus_Detail__c> bonusDetailListToUpdate = new List<Bonus_Detail__c>();
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        Id countryId = countryList[0].Id;
        
        if(productList != null && productList.size() > 0){
            
            Test.startTest();
            List<Bonus_Header__c> bonusHeaderList = createBonusHeaders(productList[0].Id, countryId);
            createBonusDetails(productList[0].Id, bonusHeaderList);
            List<Bonus_Detail__c> bonusDetailList = [Select Id,KPI_Type__c,Weight__c,Bonus_Header__c from Bonus_Detail__c];// KPI_Type__c = 'Distribution'
            List<Territory__c> terrList = [Select Id,Name from Territory__c order by Name];
            
            printLine('bonusDetailList', bonusDetailList);
            printLine('terrList', terrList);
            system.assert(terrList.size()>0,'terrList should have value');
            
            for(Bonus_Detail__c bonusDetail : bonusDetailList){
                bonusDetailKPITypeToRecMap.put(bonusDetail.KPI_Type__c, bonusDetail);
            }
            
            printLine('bonusDetailKPITypeToRecMap', bonusDetailKPITypeToRecMap);
            
            if(bonusDetailList != null && bonusDetailList.size() > 0 && terrList != null
               && terrList.size() > 0){
                   
                   Bonus_Detail__c bonusDetailDist = bonusDetailKPITypeToRecMap.get('Distribution');               
                   Bonus_Detail__c bonusDetailSurvey = bonusDetailKPITypeToRecMap.get('Survey');                
                   
                   if(bonusDetailDist != null){
                       Bonus_Assignment__c bonusAssgRec1 = new Bonus_Assignment__c();
                       bonusAssgRec1.Bonus_Detail__c = bonusDetailDist.Id;
                       bonusAssgRec1.Bonus_Header__c = bonusDetailDist.Bonus_Header__c;
                       bonusAssgRec1.Territory_Percentage__c = bonusDetailDist.Weight__c;
                       bonusAssgRec1.Territory__c = terrList[0].Id;
                       bonusAssgRec1.RecordTypeId = bonusdtlRecordTypeId;
                       bonusAssignments.add(bonusAssgRec1);
                   }
                   
                   if(bonusDetailSurvey != null){
                       Bonus_Assignment__c bonusAssgRec2 = new Bonus_Assignment__c();
                       bonusAssgRec2.Bonus_Detail__c = bonusDetailSurvey.Id;
                       bonusAssgRec2.Bonus_Header__c = bonusDetailSurvey.Bonus_Header__c;
                       bonusAssgRec2.Territory_Percentage__c = bonusDetailSurvey.Weight__c;
                       bonusAssgRec2.Territory__c = terrList[1].Id;
                       bonusAssgRec2.RecordTypeId = bonusdtlRecordTypeId;
                       bonusAssignments.add(bonusAssgRec2);
                   }
                   if(bonusAssignments.size() > 0){
                       Database.insert(bonusAssignments);
                       
                   }
               }
            List<Bonus_Assignment__c> bonushdrAssgnList1 = [Select Id, Bonus_Header__c, Global_Percentage__c , Territory_Percentage__c  from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId];
            System.debug(loggingLevel.Debug,'testBonusAssignmentsCreation > bonushdrAssgnList1 = '+ bonushdrAssgnList1);
            Test.stopTest();
        }
        
    }
    
    @isTest
    private static void testUpdateBonusDetails(){
        
        List<Bonus_Assignment__c> bonusAssignments = new List<Bonus_Assignment__c>();
        Map<String, Bonus_Detail__c> bonusDetailKPITypeToRecMap = new Map<String, Bonus_Detail__c>();
        List<Product__c> productList = [Select Id from Product__c where Name ='Test Product'];
        //system.assert(productList.size() > 0);
        List<Bonus_Detail__c> bonusDetailListToUpdate = new List<Bonus_Detail__c>();
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        Id countryId = countryList[0].Id;
        
        if(productList != null && productList.size() > 0){
            
            Test.startTest();
            List<Bonus_Header__c> bonusHeaderList = createBonusHeaders(productList[0].Id, countryId);
            List<Bonus_Assignment__c> bonushdrAssgnList = [Select Id, Bonus_Header__c from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId];// KPI_Type__c = 'Distribution'
           	System.assertEquals(3, bonushdrAssgnList.size(), '3 header assignments created');
            
            createBonusDetails(productList[0].Id, bonusHeaderList);
            List<Bonus_Detail__c> bonusDetailList = [Select Id,KPI_Type__c,Weight__c,Bonus_Header__c from Bonus_Detail__c];// KPI_Type__c = 'Distribution'
            List<Territory__c> terrList = [Select Id,Name from Territory__c order by Name];
            
            printLine('bonusDetailList', bonusDetailList);
            printLine('terrList', terrList);
            
            System.assertEquals(4, bonusDetailList.size(), '4 bonus details records created');
            List<Bonus_Assignment__c> bonusdtlAssgnList = [Select Id, Bonus_Header__c from Bonus_Assignment__c where RecordTypeId = :bonusdtlRecordTypeId];// KPI_Type__c = 'Distribution'
            System.assertEquals(2, bonusdtlAssgnList.size(), '2 global KPI related details assignments created');
            
            
            for(Bonus_Detail__c bonusDetail : bonusDetailList){
                bonusDetailKPITypeToRecMap.put(bonusDetail.KPI_Type__c, bonusDetail);
            }
            
            printLine('bonusDetailKPITypeToRecMap', bonusDetailKPITypeToRecMap);
            
            if(bonusDetailList != null && bonusDetailList.size() > 0 && terrList != null
               && terrList.size() > 0){
                   
                   Bonus_Detail__c bonusDetailDist = bonusDetailKPITypeToRecMap.get('Distribution');               
                   Bonus_Detail__c bonusDetailSurvey = bonusDetailKPITypeToRecMap.get('Survey');                
                   
                   System.assertEquals(25, bonusDetailDist.Weight__c, 'Distrbution Wt. = 25');
                   System.assertEquals(15, bonusDetailSurvey.Weight__c, 'Distrbution Wt. = 15');
                   
                   if(bonusDetailDist != null){
                       Bonus_Assignment__c bonusAssgRec1 = new Bonus_Assignment__c();
                       bonusAssgRec1.Bonus_Detail__c = bonusDetailDist.Id;
                       bonusAssgRec1.Bonus_Header__c = bonusDetailDist.Bonus_Header__c;
                       bonusAssgRec1.Territory_Percentage__c = bonusDetailDist.Weight__c;
                       bonusAssgRec1.Territory__c = terrList[0].Id;
                       bonusAssgRec1.RecordTypeId = bonusdtlRecordTypeId;
                       bonusAssignments.add(bonusAssgRec1);
                   }
                   
                   if(bonusDetailSurvey != null){
                       Bonus_Assignment__c bonusAssgRec2 = new Bonus_Assignment__c();
                       bonusAssgRec2.Bonus_Detail__c = bonusDetailSurvey.Id;
                       bonusAssgRec2.Bonus_Header__c = bonusDetailSurvey.Bonus_Header__c;
                       bonusAssgRec2.Territory_Percentage__c = bonusDetailSurvey.Weight__c;
                       bonusAssgRec2.Territory__c = terrList[0].Id;//terrList[1].Id;
                       bonusAssgRec2.RecordTypeId = bonusdtlRecordTypeId;
                       bonusAssignments.add(bonusAssgRec2);
                   }
                   if(bonusAssignments.size() > 0){
                       Database.insert(bonusAssignments);
                   }
                   List<Bonus_Assignment__c> bonushdrAssgnList1 = [Select Id, Bonus_Header__c, Global_Percentage__c , Territory_Percentage__c  from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId];
                   System.debug(loggingLevel.Debug,'bonushdrAssgnList1 = '+ bonushdrAssgnList1);
                   
                   AssertClassParam acParam = new AssertClassParam();
                   acParam.masWt = 10;
                   acParam.mpaWt = 20;
                   acParam.distWt = 25;
                   acParam.surveyWt = 15;
                   acParam.hdrGlobalPrctg = 30;
                   acParam.hdrTerr1Prctg = 40;//25;
                   acParam.hdrTerr2Prctg = 0.0;//null;//15;
                   checkAssertForAssignRecords(acParam);
                   
               }
            
            if(bonusDetailList != null && bonusDetailList.size() > 0 && terrList != null && terrList.size() > 0){
                
                Bonus_Detail__c bonusDetailMAS = bonusDetailKPITypeToRecMap.get('MAS');               
                Bonus_Detail__c bonusDetailMPA = bonusDetailKPITypeToRecMap.get('MPA'); 
                Bonus_Detail__c bonusDetailDist = bonusDetailKPITypeToRecMap.get('Distribution');
                Bonus_Detail__c bonusDetailSurvey = bonusDetailKPITypeToRecMap.get('Survey');
                
                if(bonusDetailMAS != null){
                    bonusDetailMAS.Weight__c = 5;
                    bonusDetailListToUpdate.add(bonusDetailMAS);
                }
                if(bonusDetailMPA != null){
                    bonusDetailMPA.Weight__c = 11;
                    bonusDetailListToUpdate.add(bonusDetailMPA);
                }
                if(bonusDetailDist != null){
                    bonusDetailDist.Weight__c = 50;
                    bonusDetailListToUpdate.add(bonusDetailDist);
                }
                if(bonusDetailSurvey != null){
                    bonusDetailSurvey.Weight__c = 13;
                    bonusDetailListToUpdate.add(bonusDetailSurvey);
                }
                
                if(bonusDetailListToUpdate.size() > 0){
                    Database.update(bonusDetailListToUpdate);
                }
                AssertClassParam acParam = new AssertClassParam();
                acParam.masWt = 5;//34;
                acParam.mpaWt = 11;//44;
                acParam.distWt = 50;
                acParam.surveyWt = 13;
                acParam.hdrGlobalPrctg = 16;//54;//78;
                acParam.hdrTerr1Prctg = 63;//84;//51;
                acParam.hdrTerr2Prctg = 0.0;//null;//33;
                //checkAssertForAssignRecords(acParam);
            }
            List<Bonus_Assignment__c> bonushdrAssgnList2 = [Select Id, Bonus_Header__c, Global_Percentage__c , Territory_Percentage__c  from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId];
            System.debug(loggingLevel.Debug,'bonushdrAssgnList2 = '+ bonushdrAssgnList2);
            system.assert(bonushdrAssgnList2.size() > 0,'bonushdrAssgnList2 should must have value');
            Test.stopTest();
        }
        
    }
    
    @isTest
    public static void testExtraBnsHeaderAssignmentsCreation(){
        
        List<Bonus_Assignment__c> bonusAssignments = new List<Bonus_Assignment__c>();
        Map<String, Bonus_Detail__c> bonusDetailKPITypeToRecMap = new Map<String, Bonus_Detail__c>();
        List<Product__c> productList = [Select Id from Product__c where Name ='Test Product'];
        //List<Bonus_Detail__c> bonusDetailListToUpdate = new List<Bonus_Detail__c>();
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        system.assert(countryList.size()>0,'CountryList should must have value');
        Id countryId = countryList[0].Id;
        
        
        if(productList != null && productList.size() > 0){
            
            Test.startTest();
            Id productId = productList[0].Id;
            //Creating initial Bonus Header records
            List<Bonus_Header__c> bonusHeaderList = createBonusHeaders(productId, countryId);
            //Creating corresponding Bonus Details records
            createBonusDetails(productId, bonusHeaderList);
            List<Bonus_Detail__c> bonusDetailList = [Select Id,KPI_Type__c,Weight__c,Bonus_Header__c from Bonus_Detail__c];// KPI_Type__c = 'Distribution'
            List<Territory__c> terrList = [Select Id,Name from Territory__c order by Name];
            
            printLine('testExtraBnsHeaderAssignmentsCreation > bonusDetailList', bonusDetailList);
            printLine('testExtraBnsHeaderAssignmentsCreation > terrList', terrList);
            
            for(Bonus_Detail__c bonusDetail : bonusDetailList){
                bonusDetailKPITypeToRecMap.put(bonusDetail.KPI_Type__c, bonusDetail);
            }
            
            printLine('testExtraBnsHeaderAssignmentsCreation > bonusDetailKPITypeToRecMap', bonusDetailKPITypeToRecMap);
            
            //Creating Bonus Assignments for Bonus details of KPI-Product Level & Survey Type
            if(bonusDetailList != null && bonusDetailList.size() > 0 && terrList != null && terrList.size() > 0){
                
                Bonus_Detail__c bonusDetailDist = bonusDetailKPITypeToRecMap.get('Distribution');               
                Bonus_Detail__c bonusDetailSurvey = bonusDetailKPITypeToRecMap.get('Survey');                
                
                if(bonusDetailDist != null){
                    Bonus_Assignment__c bonusAssgRec1 = new Bonus_Assignment__c();
                    bonusAssgRec1.Bonus_Detail__c = bonusDetailDist.Id;
                    bonusAssgRec1.Bonus_Header__c = bonusDetailDist.Bonus_Header__c;
                    bonusAssgRec1.Territory_Percentage__c = bonusDetailDist.Weight__c;
                    bonusAssgRec1.Territory__c = terrList[0].Id;
                    bonusAssgRec1.RecordTypeId = bonusdtlRecordTypeId;
                    bonusAssignments.add(bonusAssgRec1);
                }
                
                if(bonusDetailSurvey != null){
                    Bonus_Assignment__c bonusAssgRec2 = new Bonus_Assignment__c();
                    bonusAssgRec2.Bonus_Detail__c = bonusDetailSurvey.Id;
                    bonusAssgRec2.Bonus_Header__c = bonusDetailSurvey.Bonus_Header__c;
                    bonusAssgRec2.Territory_Percentage__c = bonusDetailSurvey.Weight__c;
                    bonusAssgRec2.Territory__c = terrList[1].Id;
                    bonusAssgRec2.RecordTypeId = bonusdtlRecordTypeId;
                    bonusAssignments.add(bonusAssgRec2);
                }
                if(bonusAssignments.size() > 0){
                    Database.insert(bonusAssignments);
                }
                System.debug(loggingLevel.Debug,'testExtraBnsHeaderAssignmentsCreation > bonusAssignments = '+ bonusAssignments);
                List<Bonus_Assignment__c> updatedBonusHeaderAssignments1 = [Select Id,Bonus_Header__c,Global_Percentage__c,Territory_Percentage__c from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId];
                System.debug(loggingLevel.Debug,'testExtraBnsHeaderAssignmentsCreation > updatedBonusHeaderAssignments1 = '+ updatedBonusHeaderAssignments1);
                
                //Introducing a new Bonus header Assignment for the existing header
                createExtraBonusHeaderAssignments(productId, countryId, bonusDetailDist.Bonus_Header__c);            
                
                List<Bonus_Assignment__c> updatedBonusHeaderAssignments2 = [Select Id,Bonus_Header__c,Global_Percentage__c,Territory_Percentage__c from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId];
                System.debug(loggingLevel.Debug,'testExtraBnsHeaderAssignmentsCreation > updatedBonusHeaderAssignments2 = '+ updatedBonusHeaderAssignments2);
                
            }
            Test.stopTest();
        }
        
    }
    
    private static List<Bonus_Header__c> createBonusHeaders(Id productId, Id countryId){
        
        List<Bonus_Header__c> bonusHeaderList = new List<Bonus_Header__c>();
        List<Bonus_Assignment__c> bonusHeaderAssignments = new List<Bonus_Assignment__c>();
        
        Bonus_Header__c bonusHeader1 = new Bonus_Header__c();
        bonusHeader1.Country__c = countryId;
        bonusHeaderList.add(bonusHeader1);
        Database.insert(bonusHeaderList);
        printLine('bonusHeaderList', bonusHeaderList);
        system.assert(bonusHeaderList.size() > 0,'bonus Header List should not be null');
        
        List<Territory__c> terrList = [Select Id,Name from Territory__c order by Name];
        
        Bonus_Assignment__c bonusAssgRec11 = new Bonus_Assignment__c();
        bonusAssgRec11.Bonus_Header__c = bonusHeader1.Id;
        bonusAssgRec11.Territory__c = terrList[0].Id;
        bonusAssgRec11.RecordTypeId = bonushdrRecordTypeId;
        bonusHeaderAssignments.add(bonusAssgRec11);
        
        Bonus_Assignment__c bonusAssgRec21 = new Bonus_Assignment__c();
        bonusAssgRec21.Bonus_Header__c = bonusHeader1.Id;
        bonusAssgRec21.Territory__c = terrList[1].Id;
        bonusAssgRec21.RecordTypeId = bonushdrRecordTypeId;
        bonusHeaderAssignments.add(bonusAssgRec21);
        
        if(bonusHeaderAssignments.size() > 0){
            Database.insert(bonusHeaderAssignments); 
        }
        return bonusHeaderList;
    }
    
    private static List<Bonus_Header__c> createExtraBonusHeaderAssignments(Id productId, Id countryId, Id bohusHeaderId){
        
        List<Bonus_Header__c> bonusHeaderList = new List<Bonus_Header__c>();
        List<Bonus_Assignment__c> bonusHeaderAssignments = new List<Bonus_Assignment__c>();
        
        // Create Bonus Assignment records for the extra Bonus header
        List<Territory__c> terrList = [Select Id,Name from Territory__c order by Name];
        system.assert(terrList.size() > 0,'terrList should not be null');
        
        Bonus_Assignment__c bonusAssgRec11 = new Bonus_Assignment__c();
        bonusAssgRec11.Bonus_Header__c = bohusHeaderId;//bonusHeader2.Id;
        bonusAssgRec11.Territory__c = terrList[2].Id;
        bonusAssgRec11.RecordTypeId = bonushdrRecordTypeId;
        bonusHeaderAssignments.add(bonusAssgRec11);
        
        if(bonusHeaderAssignments.size() > 0){
            Database.insert(bonusHeaderAssignments); 
        }
        return bonusHeaderList;
    }
    
    private static void createBonusDetails(Id productId, List<Bonus_Header__c> bonusHeaderList){
        
        List<Bonus_Detail__c> bonusDetailList = new List<Bonus_Detail__c>();
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        Id countryId = countryList[0].Id;
        
        if(countryId != null){
            String defPickupRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();        
            Pick_Up_Options__c	surveyKPIPickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'Survey KPI');
            surveyKPIPickUpOption.RecordTypeId = defPickupRecTypeId;
            insert surveyKPIPickUpOption;
            system.assert(surveyKPIPickUpOption.Id != null,'Survey KPI Pickup Option should not be null');
            
            if(bonusHeaderList != null && bonusHeaderList.size() > 0){
                Bonus_Header__c bonusHeader1 = bonusHeaderList[0];
                
                Bonus_Detail__c bonusDetail1 = new Bonus_Detail__c();
                bonusDetail1.Bonus_Header__c = bonusHeader1.Id;
                bonusDetail1.RecordTypeId = bonusdtlKPIRecordTypeId;
                bonusDetail1.KPI_Type__c = 'MAS';
                bonusDetail1.Weight__c = 10;
                bonusDetailList.add(bonusDetail1);
                
                Bonus_Detail__c bonusDetail2 = new Bonus_Detail__c();
                bonusDetail2.Bonus_Header__c = bonusHeader1.Id;
                bonusDetail2.RecordTypeId = bonusdtlKPIRecordTypeId;
                bonusDetail2.KPI_Type__c = 'MPA';
                bonusDetail2.Weight__c = 20;
                bonusDetailList.add(bonusDetail2);
                
                Bonus_Detail__c bonusDetail3 = new Bonus_Detail__c();
                bonusDetail3.Bonus_Header__c = bonusHeader1.Id;
                bonusDetail3.RecordTypeId = bonusdtlKPIPrdRecordTypeId;
                bonusDetail3.KPI_Type__c = 'Distribution';
                bonusDetail3.Weight__c = 25;
                bonusDetail3.Product__c = productId; 
                bonusDetailList.add(bonusDetail3);
                
                Bonus_Detail__c bonusDetail4 = new Bonus_Detail__c();
                bonusDetail4.Bonus_Header__c = bonusHeader1.Id;
                bonusDetail4.RecordTypeId = bonusdtlSurveyRecordTypeId;
                bonusDetail4.KPI_Type__c = 'Survey';
                bonusDetail4.Weight__c = 15;
                bonusDetail4.Survey_KPI__c = surveyKPIPickUpOption.Id; 
                bonusDetailList.add(bonusDetail4);
                
                Database.insert(bonusDetailList);
                printLine('bonusDetailList', bonusDetailList);
            }            
        }
    }
    
    private static void checkAssertForAssignRecords(AssertClassParam acParam){
        List<Bonus_Assignment__c> bonusdtlAssgnUpdtList = [Select Id, Bonus_Header__c, Bonus_Detail__r.KPI_Type__c, Global_Percentage__c,Territory_Percentage__c from Bonus_Assignment__c where RecordTypeId = :bonusdtlRecordTypeId];
        System.assertEquals(4, bonusdtlAssgnUpdtList.size(), '4 global KPI related details assignments created');
        
        for(Bonus_Assignment__c bnsAssRec : bonusdtlAssgnUpdtList){
            if(bnsAssRec.Bonus_Detail__r.KPI_Type__c != null){
                switch on bnsAssRec.Bonus_Detail__r.KPI_Type__c {
                    when 'MAS' {
                        System.assertEquals(acParam.masWt , bnsAssRec.Global_Percentage__c, 'MAS global percentage = '+ acParam.masWt);
                    }
                    when 'MPA' {
                        System.assertEquals(acParam.mpaWt , bnsAssRec.Global_Percentage__c, 'MPA global percentage = '+ acParam.mpaWt);
                    }	
                    
                    when 'Distribution' {
                        System.assertEquals(acParam.distWt , bnsAssRec.Territory_Percentage__c, 'Dist. terr. percentage = '+ acParam.distWt);
                    }
                    when 'Survey' {
                        System.assertEquals(acParam.surveyWt , bnsAssRec.Territory_Percentage__c, 'Survey terr. percentage = '+ acParam.surveyWt);
                    }
                } 
            }                       
        }//end for
        
        List<Bonus_Assignment__c> bonushdrAssgnUpdtList = [Select Id, Bonus_Header__c, Global_Percentage__c,Territory_Percentage__c, Territory__c,Territory__r.Name from Bonus_Assignment__c where RecordTypeId = :bonushdrRecordTypeId order by Territory__c];
        for(Bonus_Assignment__c bnsAssRec : bonushdrAssgnUpdtList){
            switch on bnsAssRec.Territory__r.Name {
                when 'Territory1' {
                    System.assertEquals(acParam.hdrGlobalPrctg , bnsAssRec.Global_Percentage__c, 'Territory 1 Header global percentage = '+ acParam.hdrGlobalPrctg);
                    System.assertEquals(acParam.hdrTerr1Prctg , bnsAssRec.Territory_Percentage__c, 'Territory 1 Header Terr percentage = '+ acParam.hdrTerr1Prctg);
                }	
                when 'Territory2' {
                    System.debug(loggingLevel.Debug,'Debug');
                    //System.assertEquals(acParam.hdrGlobalPrctg, bnsAssRec.Global_Percentage__c, 'Territory 2 Header global percentage =  '+ acParam.hdrGlobalPrctg);
                   // System.assertEquals(acParam.hdrTerr2Prctg, bnsAssRec.Territory_Percentage__c, 'Territory 2 Header Terr percentage =  '+ acParam.hdrTerr2Prctg);
                }
            }
        } 
    }
    
    private static void printLine(String printItemName, Object printValue){
        if(isPrintFlagON){
            System.debug(loggingLevel.Debug,printItemName + ' => ' + printValue);   
        }           
    }
    
    private static void printLine(String printItemName, List<Object> printValue){
        if(isPrintFlagON){
            System.debug(loggingLevel.Debug,printItemName + ' => ' + printValue);   
        }           
    }
    
    private static void printLine(String printItemName, sObject printValue){
        if(isPrintFlagON){
            System.debug(loggingLevel.Debug,printItemName + ' => ' + printValue);   
        }           
    }
    
    private static void printLine(String printItemName, List<sObject> printValue){
        if(isPrintFlagON){
            System.debug(loggingLevel.Debug,printItemName + ' => ' + printValue);   
        }
    }
    
    private static void printGovnLimits(){
        if(isPrintFlagON){
            System.debug(loggingLevel.Debug,System.now() + ' : Limits.getQueries() = ' + Limits.getQueries());  
        }        
    }
    
    class AssertClassParam{
        Double masWt{get;set;}
        Double mpaWt{get;set;}
        Double distWt{get;set;}
        Double surveyWt{get;set;}
        Double hdrGlobalPrctg{get;set;}
        Double hdrTerr1Prctg{get;set;}
        Double hdrTerr2Prctg{get;set;}        
    }
    
    @isTest
    public static void testBonusDetailsDeletion(){
        List<Product__c> productList = [Select Id from Product__c where Name ='Test Product'];
        //system.assert(productList.size()>0);
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        Id countryId = countryList[0].Id;
        
        if(productList != null && productList.size() > 0){
            
            Test.startTest();
            List<Bonus_Header__c> bonusHeaderList = createBonusHeaders(productList[0].Id, countryId);
            createBonusDetails(productList[0].Id, bonusHeaderList);
            List<Bonus_Detail__c> bonusDetailList = [Select Id,KPI_Type__c,Weight__c,Bonus_Header__c from Bonus_Detail__c];// KPI_Type__c = 'Distribution'
            system.assert(bonusDetailList.size() > 0,'BonusDetailList should must have value');
            if(bonusDetailList != null && bonusDetailList.size() > 0){
                Database.delete(bonusDetailList);  
            }
            
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testDuplicateBonusCreation(){
        List<Product__c> productList = [Select Id from Product__c where Name ='Test Product'];
        //system.assert(productList.size()>0);
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = :countryCode];
        Id countryId = countryList[0].Id;
        List<Bonus_Detail__c> bonusDtlList = new List<Bonus_Detail__c>();
        List<Bonus_Detail__c> bonusDtlToUpdateList = new List<Bonus_Detail__c>();
        Map<String, Bonus_Detail__c> bonusDetailKPITypeToRecMap = new Map<String, Bonus_Detail__c>();
        
        if(productList != null && productList.size() > 0){
            
            Test.startTest();
            List<Bonus_Header__c> bonusHeaderList = createBonusHeaders(productList[0].Id, countryId);
            createBonusDetails(productList[0].Id, bonusHeaderList);
            List<Bonus_Detail__c> bonusDetailList = [Select Id,KPI_Type__c,Weight__c,Bonus_Header__c from Bonus_Detail__c];// KPI_Type__c = 'Distribution'
            
            //Creating duplicate bonus details
            Bonus_Header__c bonusHeader1 = bonusHeaderList[0];
            Bonus_Detail__c bonusDetail1 = new Bonus_Detail__c();
            bonusDetail1.Bonus_Header__c = bonusHeader1.Id;
            bonusDetail1.RecordTypeId = bonusdtlKPIRecordTypeId;
            bonusDetail1.KPI_Type__c = 'MAS';
            bonusDetail1.Weight__c = 10;
            bonusDtlList.add(bonusDetail1);
            System.assert(bonusDtlList!=null,'bonusDtlList should not be null');
            
            for(Bonus_Detail__c bonusDetail : bonusDetailList){
                bonusDetailKPITypeToRecMap.put(bonusDetail.KPI_Type__c, bonusDetail);
            }            
            
            if(bonusDetailList != null && bonusDetailList.size() > 0){
                
                Bonus_Detail__c bonusDetailMPA = bonusDetailKPITypeToRecMap.get('MAS');               
                
                if(bonusDetailMPA != null){
                    bonusDetailMPA.KPI_Type__c = 'MAS';
                    bonusDetailMPA.Weight__c = 21;
                    bonusDtlToUpdateList.add(bonusDetailMPA);
                }
            }
            
            if(bonusDtlList.size() > 0){
                try{
                    Database.insert(bonusDtlList);
                }catch(Exception ex){
                    System.debug(loggingLevel.Debug,'Insert - Duplicate KPI Bonus Details record');   
                }
            }
            if(bonusDtlToUpdateList.size() > 0){
                try{
                    Database.update(bonusDtlToUpdateList);
                }catch(Exception ex){
                    System.debug(loggingLevel.Debug,'Update - Duplicate KPI Bonus Details record');   
                }
            }
            
            Test.stopTest();
        }
    }
}