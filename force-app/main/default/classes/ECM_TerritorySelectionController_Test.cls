@isTest
public class ECM_TerritorySelectionController_Test{
    static String salesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    @isTest
    public static void outletcreation(){
        Id recordTypeIdglob = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Global').getRecordTypeId();   
        Geography__c geoGlobal =New Geography__c();
        geoGlobal.Name='Global';
        geoGlobal.Code__c='GLOB';
        geoGlobal.RecordTypeId =recordTypeIdglob;
        insert geoGlobal;
        System.assert(geoGlobal!=null ,'Global Record is Added');
        Id recordTypeIdmarket = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Market').getRecordTypeId();   
        Geography__c geoEUR =New Geography__c();
        geoEUR.Name='Europe';
        geoEUR.Parent_Geography__c=geoGlobal.Id;
        geoEUR.Code__c='EU';
        geoEUR.RecordTypeId =recordTypeIdmarket;
        insert geoEUR;
        
        Id recordTypeIdhub = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Hub').getRecordTypeId();   
        Geography__c geoEUhub =New Geography__c();
        geoEUhub.Name='EUconti';
        geoEUhub.Parent_Geography__c=geoEUR.Id;
        geoEUhub.Code__c='CE';
        geoEUhub.RecordTypeId =recordTypeIdhub;
        insert geoEUhub;
        
        Id recordTypeIdIB = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Cluster').getRecordTypeId();   
        Geography__c geoIberia =New Geography__c();
        geoIberia.Name='Europe';
        geoIberia.Parent_Geography__c=geoEUhub.Id;
        geoIberia.Code__c='IB';
        geoIberia.RecordTypeId =recordTypeIdIB;
        insert geoIberia;
        
        Id recordTypeIdSpain = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();   
        Geography__c geoSpain =New Geography__c();
        geoSpain.Name='Spain';
        geoSpain.Parent_Geography__c=geoIberia.Id;
        geoSpain.Code__c='ES';
        geoSpain.RecordTypeId =recordTypeIdSpain;
        insert geoSpain;     
        
        Id bUrectype = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();   
        Territory_Hierarchy__c terriheirarchyIB =New Territory_Hierarchy__c();
        terriheirarchyIB.Name='Iberia';
        terriheirarchyIB.Geography__c=geoSpain.Id;
        terriheirarchyIB.RecordTypeId=bUrectype;
        insert terriheirarchyIB;
        
        Id salesarearectype = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();   
        Territory_Hierarchy__c terriheirarchySA =New Territory_Hierarchy__c();
        terriheirarchySA.Name='IBSalesArea';
        terriheirarchySA.Geography__c=geoSpain.Id;
        terriheirarchySA.RecordTypeId=salesarearectype;
        terriheirarchySA.Parent_BU__c= terriheirarchyIB.Id;
        insert terriheirarchySA;
        
        Id regioinrecType = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();   
        Territory_Hierarchy__c terriheirarchyregion =New Territory_Hierarchy__c();
        terriheirarchyregion.Name='Sales region';
        terriheirarchyregion.Geography__c=geoSpain.Id;
        terriheirarchyregion.RecordTypeId=regioinrecType;
        terriheirarchyregion.Parent_BU__c= terriheirarchySA.Id;
        insert terriheirarchyregion;
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geoSpain.Id;
        testterritory.Status__c='Active';
        testterritory.Region__c= terriheirarchyregion.Id;
        testterritory.Sales_Area__c= terriheirarchySA.Id;
        testterritory.Business_Unit__c=terriheirarchyIB.Id;
        insert testterritory;
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;        
        user.email = 'test@test.com';
        user.Username ='testcm123@test.com';
        user.Alias='test';
        user.Timezonesidkey='America/Los_Angeles';
        user.LocaleSidKey='en_US';
        user.LanguageLocaleKey='en_US';
        user.EmailEncodingKey='UTF-8';
        insert user;   
        
        Territory_Member__c terrimem=New Territory_Member__c();
        terrimem.Territory__c =testterritory.Id;
        //terrimem.User__c = user.Id;
        terrimem.Type__c='Primary';
        terrimem.End_Date__c =date.today();   
        insert terrimem;
        
        Id recordTypeIdoutlet = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();   
        Account acc =New Account();
        acc.Name='Testoutlet';
        acc.Status__c='Active';
        acc.RecordTypeId= recordTypeIdoutlet;
        acc.Primary_Sales_Territory__c= testterritory.Id;        
        insert acc;
    }
    @isTest
    public static void testcontractcreation(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        insert outletAccount;
        
        ECM_TerritorySelectionController.getoutletTerritory(outletAccount.Id);       
        User usrobj=[Select Id,Name from User Limit 1];
        system.assert(usrobj.Id != null,'usrobj should not be null');
        system.runAs(usrobj){
            ECM_TerritorySelectionController.getUserTerritories();  
        }
    }
    @isTest
    public static void testcontractcreationerror(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        ECM_TerritorySelectionController.getoutletTerritory('Test');
        User usrobj=[Select Id,Name from User Limit 1];
        system.debug(LoggingLevel.Debug,'usrobj'+usrobj);
        User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
            usr.Business_Role__c = 'Sales Manager';
           
            insert usr; 
        system.runAs(usrobj){
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Region');
            terriHierRegion.Parent_BU__c = terriHierSA.Id;
            insert terriHierRegion;
            Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
            territory.Country__c = geographyId;
            territory.Sales_Area__c = terriHierSA.Id;
        	territory.Region__c = terriHierRegion.Id;
            territory.RecordTypeId = salesRecordTypeId;
            territory.Territory_Type__c = 'Sales';
            territory.Status__c = 'Active';
            insert territory;
            
            Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember.User__c = usr.Id;
            terrMember.Territory__c = territory.Id;
            terrMember.Start_Date__c = system.today().AddDays(5);
            terrMember.End_Date__c = system.today().AddDays(10);
            terrMember.Type__c = 'Secondary' ;
            insert terrMember;
            terrMember.User__c =usrobj.Id;
            update terrMember;
            system.assert(terrMember.Id != null,'territory member should not be null');
            ECM_TerritorySelectionController.getUserTerritories();
        }
    }
    
}