/*
*	@Name: EDGE_PrimaryTerritoryOutletCalcBatchTest
*	@Req: 
*	@User Story : ES20-471
*	@History                                                            
                                                            
*	@VERSION   AUTHOR             DATE              DETAIL
*	1.0		Sagar Barman        08/04/2019      Initial Development
*	2.0		Prasanth T			02/11/2021		ES20-10838 Asset KPI Type
*	3.0		Debolina 			29/11/2021 		ES20-11036
*   4.0     Joshraj             04/01/2023      ES20-13672
*/
@isTest
public class EDGE_PrimaryTerritoryOutletCalcBatchTest {
    @isTest
    public static void testVolumeCalculation(){        
        //create Admin User
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'AU';
        insert testSysAdminUser;         
        System.assert(testSysAdminUser.id !=null,'User Inserted');        
        System.runAs(testSysAdminUser){
            //create all the necessary data
            
            createData();            
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_PrimaryTerritoryOutletCalcBatch'
                                                      AND Country_Code__c ='AU' LIMIT 1];
            
            String className = batchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));    
            
           
            
            //List <Territory__c> tc = [SELECT ID,Volume_Actual_Points__c,Volume_Target_Points__c FROM Territory__c WHERE Territory_Type__c = 'Sales'];
            
        }  
    } 
    @isTest
    public static void createData(){
        //create Admin User
        Map<Id,Territory__c> terrMap = new  Map<Id,Territory__c>();
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'AU';
        insert testSysAdminUser;
        System.assert(testSysAdminUser.id !=null,'User Inserted');
        User testSysAdminUser1 = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser1.Available_Countries__c = 'AU';
        insert testSysAdminUser1;    
        
        System.runAs(testSysAdminUser){
            
            // create Geography record  
            Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
            Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryID);
            marketSettings.Local_Segmentation_Validation__c = true;
            marketSettings.Outlet_Execution_Score__c = 'Binary';
            marketSettings.Minimum_Activation_Standards__c = 'Binary';
            marketSettings.Minimum_Product_Assortment__c = 'Binary';
            marketSettings.Share_Of_Space__c = 'Binary';
            marketSettings.Share_of_Space_facings__c = 'Facings in %';
            marketSettings.Distribution__c = 'Binary';
            marketSettings.New_Product_Distribution__c = 'Binary';
            insert marketSettings;
            
            
            //EDGE_UtilityTestClass.createOrgSettings();
            Id pickOpRecType = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
            pickupOption.RecordTypeId = pickOpRecType;
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            //Test.startTest();
            //create outlet record             
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Country__c = countryID;
            outletAccount.Volume_Category_Deluxe_Actuals__c = 100;
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outletAccount.Global_Channel__c = 'Off Trade';
            outletAccount.Global_Sub_Channel__c ='Retailer';
            outletAccount.Global_Segment__c = 'Discounter';
            outletAccount.Global_Sub_Segment__c = 'Modern Discounter';
            /*outletAccount.Outlet_Execution_Score__c = 100;
            outletAccount.Minimum_Activation_Standards__c = 100;
            outletAccount.Minimum_Product_Assortment__c = 100;
            outletAccount.New_Product_Distribution__c = 100;*/
            insert outletAccount;
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            insert terriHier;
            
            /*Territory_Hierarchy__c terriHierQuality = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Quality Territory Hierarchy');
            terriHierQuality.Parent_BU__c = terriHierSA.Id;
            insert terriHierQuality;*/
            
         
            //create quality territory
            Test.startTest();
            String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
            String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
            String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
            String terrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
            
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
            terrHirRG.Territory_Hierarchy_Type__c='Dispense Manager';
            insert terrHirRG;
            
            List<Territory__c> terrList=new List<Territory__c>();
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Country__c = countryId;
            territory.Territory_Type__c = 'Quality Dispense';
            territory.Region__c = terrHirRG.id;
            territory.Business_Unit__c=terrHirBU.id;
            territory.Sales_Area__c=terrHirSA.id;
               
            //System.debug('@@Region'+terrHirRG.id);
            territory.Pending_For_Batch__c = True;
            territory.RecordTypeId = terrRecordTypeId;
            terrList.add(territory);
            
            Territory__c territory2 = EDGE_UtilityTestClass.getTerritoryRec();
            territory2.Country__c = countryId;
            territory2.Territory_Type__c = 'Quality Service / Executive';
            territory2.Region__c = terrHirRG.id;
            territory2.Business_Unit__c=terrHirBU.id;
            territory2.Sales_Area__c=terrHirSA.id;
               
            //System.debug('@@Region'+terrHirRG.id);
            territory2.Pending_For_Batch__c = True;
            territory2.RecordTypeId = terrRecordTypeId;
            TerrList.add(territory2);
            Database.insert(terrList);
            terrMap.put(territory.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory.Id ]);
            //system.debug('terrMap++'+terrMap);
            
            
            KPIs_Target__c kpiTargetQuality = new KPIs_Target__c();
            kpiTargetQuality.Category__c = 'Beer';
            kpiTargetQuality.Segment__c = 'Discounter';
            kpiTargetQuality.Target__c = 100.00;
            kpiTargetQuality.Territory__c = territory.Id;
            insert kpiTargetQuality; 
            
            //sales territory
            Territory__c salesTerritory1 = new Territory__c();
            salesTerritory1.Territory_Type__c = 'Sales';
            salesTerritory1.Status__c = 'Active';
            salesTerritory1.Country__c = countryID;
            salesTerritory1.Region__c = terriHier.Id;
            salesTerritory1.Pending_For_Batch__c = true;
            insert salesTerritory1;
            terrMap.put(salesTerritory1.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: salesTerritory1.Id ]);
            
            KPIs_Target__c kpiTarget1 = new KPIs_Target__c();
            kpiTarget1.Category__c = 'Beer';
            kpiTarget1.Segment__c = 'Discounter';
            kpiTarget1.Target__c = 100.00;
            kpiTarget1.Territory__c = salesTerritory1.Id;
            insert kpiTarget1;       
            
            
            List<Account> qoutlets = new List<Account>();
            
            Account newqacc= EDGE_UtilityTestClass.getOutletRecord();
            newqacc.Country__c = countryID;
            newqacc.Name = 'Test Account2';
            newqacc.BillingStreet = '171 Asian Highway 45';
            newqacc.BillingCity = 'Kolkata';
            newqacc.BillingState = 'Tasmania';
            newqacc.BillingPostalCode = '56681';
            newqacc.BillingCountry = 'Australia';
            newqacc.Volume_Category_Deluxe_Actuals__c = 350;
            newqacc.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            newqacc.Global_Channel__c = 'Off Trade';
            newqacc.Global_Sub_Channel__c ='Retailer';
            newqacc.Global_Segment__c = 'Discounter';
            newqacc.Global_Sub_Segment__c = 'Modern Discounter';
            newqacc.Sos_Beer_Target__c = 100;
            newqacc.Sos_Beer_Denominator__c = 60;
            newqacc.Sos_Beer_Numerator__c = 40;
            qoutlets.add(newqacc);
            
            Account newqacc1= EDGE_UtilityTestClass.getOutletRecord();
            newqacc1.Country__c = countryID;
            newqacc1.Name = 'Test Account2';
            newqacc1.BillingStreet = '171 Asian Highway 45';
            newqacc1.BillingCity = 'Kolkata';
            newqacc1.BillingState = 'Tasmania';
            newqacc1.BillingPostalCode = '56681';
            newqacc1.BillingCountry = 'Australia';
            newqacc1.Volume_Category_Deluxe_Actuals__c = 350;
            newqacc1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            newqacc1.Global_Channel__c = 'Off Trade';
            newqacc1.Global_Sub_Channel__c ='Retailer';
            newqacc1.Global_Segment__c = 'Discounter';
            newqacc1.Global_Sub_Segment__c = 'Modern Discounter';
            newqacc1.Sos_Beer_Target__c = 100;
            newqacc1.Sos_Beer_Denominator__c = 60;
            newqacc1.Sos_Beer_Numerator__c = 40;
            qoutlets.add(newqacc1);
            
            database.insert(qoutlets);
            
            List<Outlet_Territory__c> outletTeList = new List<Outlet_Territory__c>();
            
            Outlet_Territory__c qoutletTer = EDGE_UtilityTestClass.getOutltTerritory(qoutlets[0].Id, terrList[0].Id);
            //insert qoutletTer;
            outletTeList.add(qoutletTer);
            Outlet_Territory__c soutletTer = EDGE_UtilityTestClass.getOutltTerritory(qoutlets[0].Id, salesTerritory1.Id);
            //insert soutletTer;
            outletTeList.add(soutletTer);
            Outlet_Territory__c qoutletTer1 = EDGE_UtilityTestClass.getOutltTerritory(qoutlets[1].Id, terrList[0].Id);
            //insert qoutletTer1;
            outletTeList.add(qoutletTer1);
            Outlet_Territory__c qoutletTer2 = EDGE_UtilityTestClass.getOutltTerritory(qoutlets[0].Id, terrList[1].Id);
            //insert qoutletTer2;
            outletTeList.add(qoutletTer2);
            
            Database.insert(outletTeList);
            //system.debug('newqacc++ ' + [SELECT Id, Sos_Beer_Target__c, Sos_Beer_Denominator__c, Sos_Beer_Numerator__c FROM Account WHERE Id = :newqacc.Id]);
            
            
            //create custom Territory record
            Territory__c salesTerritory = new Territory__c();
            salesTerritory.Territory_Type__c = 'Sales';
            salesTerritory.Status__c = 'Active';
            salesTerritory.Country__c = countryID;
            salesTerritory.Region__c = terriHier.Id;
            salesTerritory.Pending_For_Batch__c = true;
            insert salesTerritory;
            terrMap.put(salesTerritory.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: salesTerritory.Id ]);
            
            KPIs_Target__c kpiTarget = new KPIs_Target__c();
            kpiTarget.Category__c = 'Beer';
            kpiTarget.Segment__c = 'Discounter';
            kpiTarget.Target__c = 100.00;
            kpiTarget.Territory__c = salesTerritory.Id;
            insert kpiTarget;           
            
            List<Account> outlets = new List<Account>();
            
            Account newacc= EDGE_UtilityTestClass.getOutletRecord();
            newacc.Country__c = countryID;
            newacc.Name = 'Test Account2';
            newacc.BillingStreet = '171 Asian Highway 46';
            newacc.BillingCity = 'Kolkata';
            newacc.BillingState = 'Tasmania';
            newacc.BillingPostalCode = '56681';
            newacc.BillingCountry = 'Australia';
            newacc.Volume_Category_Deluxe_Actuals__c = 350;
            newacc.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            newacc.Global_Channel__c = 'Off Trade';
            newacc.Global_Sub_Channel__c ='Retailer';
            newacc.Global_Segment__c = 'Discounter';
            newacc.Global_Sub_Segment__c = 'Modern Discounter';
            newacc.Primary_Sales_Territory__c = salesTerritory.Id;
            newacc.Sos_Beer_Target__c = 100;
            newacc.Sos_Beer_Denominator__c = 60;
            newacc.Sos_Beer_Numerator__c = 40;
            //newacc.
            newacc.Outlet_Execution_Score__c = 100;
            newacc.Minimum_Activation_Standards__c = 100;
            newacc.Minimum_Product_Assortment__c = 100;
            newacc.New_Product_Distribution__c = 100;
            newacc.Distribution__c = 100;
            newacc.Distribution_Numerator__c = 2;
            newacc.Distribution_Denominator__c = 2;
            newacc.Activated_Outlet__c = true;
            outlets.add(newacc);
            
            Account newacc1= EDGE_UtilityTestClass.getOutletRecord();
            newacc1.Country__c = countryID;
            newacc1.Name = 'Test Account2';
            newacc1.BillingStreet = '171 Asian Highway 46';
            newacc1.BillingCity = 'Kolkata';
            newacc1.BillingState = 'Tasmania';
            newacc1.BillingPostalCode = '56681';
            newacc1.BillingCountry = 'Australia';
            newacc1.Volume_Category_Deluxe_Actuals__c = 350;
            newacc1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            newacc1.Global_Channel__c = 'Off Trade';
            newacc1.Global_Sub_Channel__c ='Retailer';
            newacc1.Global_Segment__c = 'Discounter';
            newacc1.Global_Sub_Segment__c = 'Modern Discounter';
            newacc1.Primary_Sales_Territory__c = salesTerritory.Id;
            newacc1.Sos_Beer_Target__c = 100;
            newacc1.Sos_Beer_Denominator__c = 60;
            newacc1.Sos_Beer_Numerator__c = 40;
            outlets.add(newacc1);
            
            database.insert(outlets);
            
            /*KPI_Achivement__c kpiRec = new KPI_Achivement__c();
kpiRec.KPI_Type__c = 'MAS';
kpiRec.Country__c = countryID;
kpiRec.Achievement__c = 15;
kpiRec.Total_Denominator__c = 20 ;
kpiRec.Territory__c = salesTerritory.Id;
insert kpiRec;*/
            
            //system.debug('newacc++ ' + [SELECT Id, Sos_Beer_Target__c, Sos_Beer_Denominator__c, Sos_Beer_Numerator__c FROM Account WHERE Id = :newacc.Id]);
            
            
            Test.stopTest();
            //create Sales Rep User
            User testSalesRepUser = EDGE_UtilityTestClass.runAsUser('Salesrep','Sales Representative');
            testSalesRepUser.Available_Countries__c = 'AU';
            testSalesRepUser.ManagerId  =testSysAdminUser.Id;
            insert testSalesRepUser;  
            
            Business_Role__c bRole = EDGE_UtilityTestClass.getBusinessRole();
            bRole.Country__c = countryID; 
            bRole.My_accounts_Fields_Display__c ='Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED';
            insert bRole;
            User_Business_Role__c ubRole = EDGE_UtilityTestClass.getuserBusinessRole(testSalesRepUser,bRole);
            insert ubRole;
            //create Territory Member
            Territory_Member__c tm = new Territory_Member__c();
            tm.User__c=testSalesRepUser.Id;
            tm.Territory__c=salesTerritory.Id;
            tm.Type__c = 'Primary';
            insert tm;
            
            List<Outlet_Territory__c> outletterrList = new List<Outlet_Territory__c>();
            
            //createOutletTerritory
            Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
            outletTerritory.Territory__c = salesTerritory.id;
            outletTerritory.Outlet__c = outletAccount.id;
            outletTerritory.Active__c='Active';
            
            outletterrList.add(outletTerritory);
            
            Outlet_Territory__c outletTerritory1 = new Outlet_Territory__c();
            outletTerritory1.Territory__c = salesTerritory.id;
            outletTerritory1.Outlet__c = newacc.id;
            outletTerritory1.Active__c='Active';
            outletterrList.add(outletTerritory1);
            
            insert outletterrList;
            
            // create custom Market Cycle
            Market_Cycle__c newMC = new Market_Cycle__c();
            newMC.Start_Date__c = Date.today();
            newMC.End_Date__c = newMC.Start_Date__c.addDays(14);
            newMC.Geography__c = countryID;
            insert newMC;
            
            // create custom Territory Cycle
            Territory_Cycle__c newTC= new Territory_Cycle__c();
            newTC.Market_Cycle__c = newMC.ID;
            newTC.Territory__c = salesTerritory.id;
            //newTC.Volume_Target_Value__c = 555;
            insert newTC;
            
            List<Outlet_KPI_Achievement__c> outKpiRecs = new List<Outlet_KPI_Achievement__c>();
            
            Outlet_KPI_Achievement__c outKpiRec = new Outlet_KPI_Achievement__c();
            outKpiRec.KPI_Type__c = 'SoS';
            outKpiRec.Outlet__c = newacc.Id;
            outKpiRec.Actual_Numerator__c = 15;
            outKpiRec.Total_Denominator__c = 20 ;
            outKpiRec.Target__c = 95;
            outKpiRecs.add(outKpiRec);
            
            Outlet_KPI_Achievement__c outKpiRec1 = new Outlet_KPI_Achievement__c();
            outKpiRec1.KPI_Type__c = 'SoS';
            outKpiRec1.Outlet__c = newacc1.Id;
            outKpiRec1.Actual_Numerator__c = 15;
            outKpiRec1.Total_Denominator__c = 20 ;
            outKpiRec1.Target__c = 95;
            outKpiRecs.add(outKpiRec1);
            
            Database.insert(outKpiRecs);
            System.assert(outKpiRecs !=null,'Outlet KPIs Inserted');
            
            Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
            territoryWithCycleMap.put(newTC.Id, newTC);
            EDGE_KPIAchivementOperations.calculateKPIAchivements(terrMap,territoryWithCycleMap, 'AU','Sales');
            //for EDGE_UtilityClass
            EDGE_UtilityClass.getCountryMarketSetting();
            List<Account> accountList = new List<Account>();
            accountList.add(outletAccount);
            EDGE_UtilityClass.populateGUID(accountList);       
        }   
    }
    @isTest
    public static void testAssetKpiCalculation(){        
        //create Admin User
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'GB';
        insert testSysAdminUser;         
        System.assert(testSysAdminUser.id !=null,'User Inserted');
        System.runAs(testSysAdminUser){
            //create all the necessary data
            
            createAssetKpiData();            
            //04-Jan
            /*Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_PrimaryTerritoryOutletCalcBatch'
                                                      AND Country_Code__c ='GB' LIMIT 1];*/
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_PrimaryTerritoryAssetCalcBatch'
                                                      AND Country_Code__c ='GB' LIMIT 1];
            
            String className = batchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));    
            
            //Territory__c tc = [SELECT ID,Volume_Actual_Points__c,Volume_Target_Points__c FROM Territory__c WHERE Territory_Type__c = 'Quality Service / Executive'];
            
        }  
    } 
    @isTest
    public static void createAssetKpiData(){
        //create Admin User
        Test.startTest();
       // Map<Id,Territory__c> terrMap = new  Map<Id,Territory__c>();
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'GB';
        insert testSysAdminUser;
        System.assert(testSysAdminUser.Id!=null,'User Added');
        User testSysAdminUser1 = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser1.Available_Countries__c = 'GB';
        insert testSysAdminUser1;    
        
        System.runAs(testSysAdminUser){
            
            // create Geography record  
            Id countryID = EDGE_UtilityTestClass.setupCountryGB('GB'); 
            Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryID);
            marketSettings.Local_Segmentation_Validation__c = true;
            marketSettings.Outlet_Execution_Score__c = 'Binary';
            marketSettings.Minimum_Activation_Standards__c = 'Binary';
            marketSettings.Minimum_Product_Assortment__c = 'Binary';
            marketSettings.Share_Of_Space__c = 'Binary';
            marketSettings.Share_of_Space_facings__c = 'Facings in number';
            marketSettings.Distribution__c = 'Binary';
            marketSettings.New_Product_Distribution__c = 'Binary';
            insert marketSettings;
            
            
            EDGE_UtilityTestClass.createOrgSettings();
            Id pickOpRecType = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
            pickupOption.RecordTypeId = pickOpRecType;
            pickupOption.Name = 'Gold[GB]';
            insert pickupOption;
            

            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            Id qualityTerritoryHierarchyRecType = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
            terriHier.RecordTypeId = qualityTerritoryHierarchyRecType;
            terriHier.Territory_Hierarchy_Type__c ='Regional Quality Manager (GB)';
            insert terriHier;
            Territory_Hierarchy__c terriHierSales = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHierSales.Parent_BU__c = terriHierSA.Id;
            terriHierSales.Territory_Hierarchy_Type__c ='Regional Quality Manager (GB)';
            insert terriHierSales;
            
            //create custom Territory record
            Id qualityTerritoryRecType = Schema.SObjectType.Territory__c.getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
            Territory__c qualityTerritory = new Territory__c();
            qualityTerritory.RecordTypeId = qualityTerritoryRecType;
            qualityTerritory.Territory_Type__c = 'Quality Service / Executive';
            qualityTerritory.Status__c = 'Active';
            qualityTerritory.Country__c = countryID;
            qualityTerritory.Region__c = terriHier.Id;
            qualityTerritory.Pending_For_Batch__c = true;
            insert qualityTerritory;
            
            Territory__c salesTerritory = new Territory__c();
            salesTerritory.Territory_Type__c = 'Sales';
            salesTerritory.Status__c = 'Active';
            salesTerritory.Country__c = countryID;
            salesTerritory.Region__c = terriHierSales.Id;
            salesTerritory.Pending_For_Batch__c = true;
            insert salesTerritory;
            test.stopTest();
            //create outlet record
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Country__c = countryID;
            outletAccount.Status__c ='Active';
            outletAccount.Volume_Category_Deluxe_Actuals__c = 100;
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outletAccount.Global_Channel__c = 'Off Trade';
            outletAccount.Global_Sub_Channel__c ='Retailer';
            outletAccount.Global_Segment__c = 'Discounter';
            outletAccount.Global_Sub_Segment__c = 'Modern Discounter';
            insert outletAccount;
            
            Outlet_Territory__c outletTerri = new Outlet_territory__c();
            outletTerri.Active__c='Active';
            outletTerri.Outlet__c = outletAccount.Id;
            outletTerri.Territory__c = qualityTerritory.Id;
            insert outletTerri;
            Outlet_Territory__c outletTerri1 = new Outlet_territory__c();
            outletTerri1.Active__c='Active';
            outletTerri1.Outlet__c = outletAccount.Id;
            outletTerri1.Territory__c = salesTerritory.Id;
            insert outletTerri1;
            
            Contact primcon = new Contact(FirstName='fname',
                                          LastName = 'lname',
                                          Email = 'email@gmail.com',
                                          Phone = '1234567890',Contact_Type__c='Primary',AccountID=outletAccount.Id); 
            insert primcon;
             
            Master_Asset__c masObj = new Master_Asset__c();
            masObj.Name = 'Test';
            masObj.Part_Number__c = '123CHSGT';
            masObj.GUID__c = 'TWRFSHJAKSVGG';
            masObj.Short_Description__c = 'short description';
            masObj.Country__c = countryId;
            masObj.Active__c = true;
            masObj.Priority_Assets__c = true;
            
            Insert masObj;
            Master_Asset__c masObj2 = new Master_Asset__c();
            masObj2.Name = 'Tes551';
            masObj2.Part_Number__c = '123CH2SGT';
            masObj2.GUID__c = 'TWRFSHHJAKSVGG';
            masObj2.Short_Description__c = 'sho23rt description';
            masObj2.Country__c = countryId;
            masObj2.Active__c = true;
            masObj2.Priority_Assets__c = true;
            
            Insert masObj2;
            
            Asset asst = new Asset();
            asst.Name = 'Test';
            asst.GUID__c = 'TWRFSHJAKSVGG';
            asst.Description = 'asset description';
            asst.AccountId = outletAccount.Id;
            asst.ContactId = primcon.Id;
            asst.Country__c = countryId;
            asst.Quantity = 1;
            asst.SerialNumber ='1111';   
            asst.Master_Asset__c=masObj.id;            
            insert asst;
           
        }    
    }
    @isTest
    public static void testOutletsKPIAchievementCalcBatch(){
        Test.startTest();
        createOutletsKPITestData();
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletKPIAchievementCalcBatch'
                                                  and Country_Code__c ='GB'];
        system.assert(batchSetting.Id != null,'Batch Setting Obtained');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    @isTest
    public static void createOutletsKPITestData(){
        Map<Id,Territory__c> terrMap = new  Map<Id,Territory__c>();
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        system.assert(countryId!=null,'Country Inserted');
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Outlet_Execution_Score__c = 'Binary';
        marketSettings.Minimum_Activation_Standards__c = 'Binary';
        marketSettings.Minimum_Product_Assortment__c = 'Binary';
        marketSettings.Share_Of_Space__c = 'Binary';
        marketSettings.Distribution__c = 'Binary';
        marketSettings.New_Product_Distribution__c = 'Binary';
        insert marketSettings;
        
        
        String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
        String terrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
        String terrHierRegionRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        String terrAtRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        
        Territory_Hierarchy__c terrHirBU = new Territory_Hierarchy__c();
        terrHirBU.RecordTypeId =terrHierBURecordTypeId;
        terrHirBU.Name = 'GBstralia Territory Hierarchy';
        terrHirBU.Geography__c = countryId;
        insert terrHirBU;
        
        Territory_Hierarchy__c terrHirSA = new Territory_Hierarchy__c();
        terrHirSA.RecordTypeId =terrHierSARecordTypeId;
        terrHirSA.Name = 'GBstralia Territory Hierarchy';
        terrHirSA.Geography__c = countryId;
        terrHirSA.Parent_BU__c = terrHirBU.Id;
        insert terrHirSA;
        
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'GBstralia Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG;
               
        Territory_Hierarchy__c terrHirRG2 = new Territory_Hierarchy__c();
        terrHirRG2.RecordTypeId =terrHierRegionRecordTypeId;
        terrHirRG2.Name = 'GBstralia Territory Hierarchy';
        terrHirRG2.Geography__c = countryId;
        terrHirRG2.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG2;
        
        
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.Territory_Type__c = 'Quality Service / Executive';
        territory.Region__c = terrHirRG.id;
        territory.Pending_For_Batch__c = True;
        territory.RecordTypeId = terrRecordTypeId;
        territory.Status__c = 'Active';
        insert territory;
        
        Territory__c territory2 = EDGE_UtilityTestClass.getTerritoryRec();
        territory2.Country__c = countryId;
        territory2.Territory_Type__c = 'Sales';
        territory2.Region__c = terrHirRG2.id;
        territory2.Pending_For_Batch__c = True;
        territory2.Status__c = 'Active';
        //territory2.RecordTypeId = terrRecordTypeId;
        insert territory2;
        
        Territory__c territory3 = EDGE_UtilityTestClass.getTerritoryRec();
        territory3.Country__c = countryId;
        territory3.Territory_Type__c = 'Activation Territory';
        territory3.Pending_For_Batch__c = True;
        territory3.Status__c = 'Active';
        territory3.RecordTypeId = terrAtRecordTypeId;
        insert territory3;
        
        
        terrMap.put(territory2.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory2.Id ]);
        //terrMap.put(territory2.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory2.Id ]);
        //terrMap.put(territory2.Id, territory2);
        //terrMap.put(territory.Id, territory);
        
        /*for(Territory__c terr : [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c]){
            terrMap.put(terr.Id,terr);
        }*/
                                 
        //system.debug('terrMap++'+terrMap);
        // create custom Market Cycle
        Market_Cycle__c newMC = new Market_Cycle__c();
        newMC.Start_Date__c = Date.today();
        newMC.End_Date__c = newMC.Start_Date__c.addDays(14);
        newMC.Geography__c = countryId;
        insert newMC;
        
        // create custom Territory Cycle
        Territory_Cycle__c newTC= new Territory_Cycle__c();
        newTC.Market_Cycle__c = newMC.ID;
        newTC.Territory__c = territory.id;
        insert newTC;
        
        Territory_Cycle__c newTC2= new Territory_Cycle__c();
        newTC2.Market_Cycle__c = newMC.ID;
        newTC2.Territory__c = territory2.id;
        insert newTC2;
        
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[GB]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        //outlet.Pending_For_Outlet_KPI_Achievement__c = true;
        //outlet.Primary_Sales_Territory__c = territory.id;
        outlet.Status__c = 'Active';
        insert outlet;
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name = 'Test_Outlet2';
        outlet2.AccountNumber = '90909';
        outlet2.Outlet_Email_Address__c = 'test1@test1.com';
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet2.Independent_of_Owner__c = true;
        //outlet.Pending_For_Outlet_KPI_Achievement__c = true;
        outlet2.Primary_Sales_Territory__c = territory2.id;
        outlet2.BillingStreet = '18 South Highway 45';
        outlet2.BillingCity = 'Brisbane';
        outlet2.BillingPostalCode = '5669';
        outlet2.BillingState = 'Queensland';
        outlet2.Status__c = 'Active';
        outlet2.Activation_Territory_LT__c =territory3.Id;
        insert outlet2;
        Set<Id> outletIdSet = new Set<Id>();
        outletIdSet.Add(outlet.Id);
        outletIdSet.Add(outlet2.Id);
        
        Outlet_Territory__c outletTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        outletTer.Active__c = 'Active';
        insert outletTer;
        
        Outlet_Territory__c outletTer2 = EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, territory2.Id);
        outletTer2.Active__c = 'Active';
        insert outletTer2;
        
        Outlet_Territory__c outletTer3 = EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, territory3.Id);
        outletTer3.Active__c = 'Active';
        insert outletTer3;
        
        
        List<KPIs_Target__c> lstKPITarget = new List<KPIs_Target__c>();
        KPIs_Target__c kpiTarget = new KPIs_Target__c();
        kpiTarget.Territory__c = territory.id;
        kpiTarget.Segment__c = 'Hypermarket';
        kpiTarget.Name = 'Sample';
        kpiTarget.Target__c = 89;
        kpiTarget.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget);
        
        KPIs_Target__c kpiTarget2 = new KPIs_Target__c();
        kpiTarget2.Territory__c = territory2.id;
        kpiTarget2.Segment__c = 'Hypermarket';
        kpiTarget2.Name = 'Sample';
        kpiTarget2.Target__c = 89;
        kpiTarget2.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget2);
        
        KPIs_Target__c kpiTarget1 = new KPIs_Target__c();
        kpiTarget1.Territory__c = territory.id;
        kpiTarget1.Segment__c = 'Hypermarket';
        kpiTarget1.Name = 'SampleHypermarket';
        kpiTarget1.Target__c = 85;
        kpiTarget1.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget1);
        
        KPIs_Target__c kpiTarget3 = new KPIs_Target__c();
        kpiTarget3.Territory__c = territory2.id;
        kpiTarget3.Segment__c = 'Hypermarket';
        kpiTarget3.Name = 'SampleHypermarket';
        kpiTarget3.Target__c = 85;
        kpiTarget3.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget3);
        
        insert lstKPITarget; 
        
        List<Outlet_KPI_Achievement__c> outletKPIAcivmtList = new List<Outlet_KPI_Achievement__c>();
        Outlet_KPI_Achievement__c outKPIAch = new Outlet_KPI_Achievement__c();
        outKPIAch.Target__c=91;
        outKPIAch.KPI_Type__c = 'SoS';
        outKPIAch.Category__c = 'Gin';
        outKPIAch.Outlet__c = outlet.id;
        outletKPIAcivmtList.add(outKPIAch);
        
        Outlet_KPI_Achievement__c outKPIAch4 = new Outlet_KPI_Achievement__c();
        outKPIAch4.Target__c=90;
        outKPIAch4.KPI_Type__c = 'SoS';
        outKPIAch4.Category__c = 'Gin';
        outKPIAch4.Outlet__c = outlet2.id;
		outletKPIAcivmtList.add(outKPIAch4);
        
        Outlet_KPI_Achievement__c outKPIAch1 = new Outlet_KPI_Achievement__c();
        outKPIAch1.Target__c=81;
        outKPIAch1.KPI_Type__c = 'SoS';
        outKPIAch1.Category__c = 'Liqueur';
        outKPIAch1.Outlet__c = outlet.id;
        
        Outlet_KPI_Achievement__c outKPIAch3 = new Outlet_KPI_Achievement__c();
        outKPIAch3.Target__c=80;
        outKPIAch3.KPI_Type__c = 'SoS';
        outKPIAch3.Category__c = 'Liqueur';
        outKPIAch3.Outlet__c = outlet2.id;
        
        outletKPIAcivmtList.add(outKPIAch1);
        outletKPIAcivmtList.add(outKPIAch3);
        insert outletKPIAcivmtList;
        
        KPI_Achivement__c kpiAch = new KPI_Achivement__c();
        kpiAch.KPI_Type__c = 'SoS';
        kpiAch.Category__c = 'Gin';
        kpiAch.Total_Denominator__c = 100;
        kpiAch.Actual_Numerator__c = 50;
        kpiAch.Achievement__c = 50;
        kpiAch.Territory__c = territory.Id;
        kpiAch.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch.Unique_Key__c = territory.Id+'_'+'SoS'+'_'+'Gin';
        kpiAch.Total_Outlets__c = 4;
        kpiAch.Target__c = 25;
        kpiAch.Region__c = terrHirRG.Id;
        insert kpiAch;
        
        KPI_Achivement__c kpiAch2 = new KPI_Achivement__c();
        kpiAch2.KPI_Type__c = 'SoS';
        kpiAch2.Category__c = 'Gin';
        kpiAch2.Total_Denominator__c = 100;
        kpiAch2.Actual_Numerator__c = 50;
        kpiAch2.Achievement__c = 50;
        kpiAch2.Territory__c = territory2.Id;
        kpiAch2.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch2.Unique_Key__c = territory2.Id+'_'+'SoS'+'_'+'Gin';
        kpiAch2.Total_Outlets__c = 4;
        kpiAch2.Target__c = 25;
        kpiAch.Region__c = terrHirRG2.Id;
        insert kpiAch2;
        
        
        KPI_Achivement__c kpiAch3 = new KPI_Achivement__c();
        kpiAch3.KPI_Type__c = 'Volume Category Performance';
        kpiAch3.Volume_Category__c = 'RTD';
        kpiAch3.Total_Denominator__c = 100;
        kpiAch3.Actual_Numerator__c = 50;
        kpiAch3.Achievement__c = 50;
        kpiAch3.Territory__c = territory2.Id;
        kpiAch3.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch3.Unique_Key__c = territory2.Id+'_'+'Volume'+'_'+'RTD';
        kpiAch3.Total_Outlets__c = 4;
        kpiAch3.Target__c = 25;
        kpiAch3.Region__c = terrHirRG2.Id;
        insert kpiAch3;
        System.assert(kpiAch3.Id!=null ,'KPIs Added');
        
        Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
        //territoryWithCycleMap.put(newTC.Id, newTC);
        territoryWithCycleMap.put(newTC2.Id, newTC2);
        //EDGE_KPIAchivementOperations.calculateSOSandVolumeCategoryKPIAchivements(terrMap,territoryWithCycleMap,outletKPIAcivmtList, 'GB',outletIdSet);
        //EDGE_KPIAchivementOperations.calculateAssetKPIAchivements(terrMap, null, 'GB');
        Outlet_KPI_Achievement__c outKPIAch2 = new Outlet_KPI_Achievement__c();
        outKPIAch2.Target__c=90;
        outKPIAch2.Actual_Numerator__c = 15;
        outKPIAch2.Total_Denominator__c = 20 ; 
        outKPIAch2.Achievement__c = 40;
        outKPIAch2.KPI_Type__c = 'SoS';
        outKPIAch2.Category__c = 'Liqueur';
        outKPIAch2.Outlet__c = outlet.id;
        
        Outlet_KPI_Achievement__c outKPIAch5 = new Outlet_KPI_Achievement__c();
        outKPIAch5.Target__c=90;
        outKPIAch5.Actual_Numerator__c = 15;
        outKPIAch5.Total_Denominator__c = 20 ;
        outKPIAch5.Achievement__c = 40;
        outKPIAch5.KPI_Type__c = 'SoS';
        outKPIAch5.Category__c = 'Liqueur';
        outKPIAch5.Outlet__c = outlet2.id;
        
        
        Outlet_KPI_Achievement__c outKPIAch6 = new Outlet_KPI_Achievement__c();
        outKPIAch6.Target__c=90;
        outKPIAch6.KPI_Type__c = 'Volume';
        outKPIAch6.Volume_Category__c = 'RTD';
        outKPIAch6.Achievement__c = 40;
        outKPIAch6.Actual_Numerator__c = 15;
        outKPIAch6.Total_Denominator__c = 20 ;
        outKPIAch6.Outlet__c = outlet2.id;
        
        List<Outlet_KPI_Achievement__c> outletKpiList = new List<Outlet_KPI_Achievement__c>();
        outletKpiList.add(outKPIAch2);
        outletKpiList.add(outKPIAch5);
        outletKpiList.add(outKPIAch6);
        try{
            insert outletKpiList;
        }catch(Exception e){
            System.debug(LoggingLevel.Debug,'Error '+e.getCause());
        }
        
        
    } 
}