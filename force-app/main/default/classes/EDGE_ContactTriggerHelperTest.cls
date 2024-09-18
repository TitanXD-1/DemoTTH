/**
* @Description :  EDGE_ContactTriggerHelperTest

* @Purpose: This is the test class for the  EDGE_ContactTriggerHelper class. It also covers Contact TriggerHandler class.

* @History :

* @Version   Developer      	Date             User Story	  
*   1.0   	Sandeep Sahoo     18/03/2019      Initial Development
*   2.0	  	Rajarshi Lahiri	  26/04/2022	  Removed all references to Contact_Type__c field (ES20-12548 and ES20-12393)
*/

@isTest
public class EDGE_ContactTriggerHelperTest{
    
    /**
Method  : testPrimaryContactInsert
Purpose : This is used to PrimaryContact method
*/
    @isTest
    public static void testPrimaryContactInsert(){
        EDGE_UtilityTestClass.createOrgSettings();
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        
        User admin = EDGE_UtilityTestClass.runAsUser('addmin01','System Administrator'); 
        admin.Available_Countries__c = 'GB';
        insert admin;
        
        System.runAs(admin){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            testoutlet.Country__c = geoMap.get('Country');
            testoutlet.Hub__c = geoMap.get('Hub');
            testoutlet.Region__c=geoMap.get('Region');
            testoutlet.Area__c=geoMap.get('Area');
            testoutlet.Market__c = geoMap.get('Market');
            testoutlet.Cluster__c= geoMap.get('Cluster');
            insert testoutlet;
            
            Test.startTest();
            Contact primcon=new Contact(FirstName='fname',
                                        LastName = 'lname',
                                        Email = 'email@gmail.com',
                                        Phone = '1234567890',AccountID=testoutlet.Id); 
            insert primcon;
            try{
                Contact seccon=new Contact(FirstName='fname',
                                           LastName = 'lname',
                                           Email = 'email1@gmail.com',
                                           Phone = '1234567899',AccountID=testoutlet.Id); 
                insert seccon;
            }catch(Exception ex){
                String s1 = ex.getMessage();
                s1 = s1.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ' , ': [');
                System.assertEquals(s1, Label.One_Primary_Contact,'Exception should match');
            }   
            Test.stopTest();
        }
    }
    
    /**
Method  : testPrimaryContactUpdate
Purpose : This is used to Primary Contact update method
*/
    @isTest
    public static void testPrimaryContactUpdate(){
        EDGE_UtilityTestClass.createOrgSettings();
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        
        User admin = EDGE_UtilityTestClass.runAsUser('addmin02','System Administrator'); 
        admin.Available_Countries__c = 'GB';
        insert admin;
        
        System.runAs(admin){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.Country__c = geoMap.get('Country');
            testoutlet.Hub__c = geoMap.get('Hub');
            testoutlet.Region__c=geoMap.get('Region');
            testoutlet.Area__c=geoMap.get('Area');
            testoutlet.Market__c = geoMap.get('Market');
            testoutlet.Cluster__c= geoMap.get('Cluster');
            insert testoutlet;
            Contact primcon=new Contact(FirstName='fname',
                                        LastName = 'lname',
                                        Email = 'email@gmail.com',
                                        Phone = '1234567890',AccountID=testoutlet.Id); 
            Test.startTest();
            insert primcon;
            Contact seccon;
            Contact testcon;
            try{
                seccon=new Contact(FirstName='fname',
                                   LastName = 'lname',
                                   Email = 'email1@gmail.com',
                                   Phone = '1234567899',AccountID=testoutlet.Id); 
                insert seccon;
                testcon=[Select Id from Contact where Email='email1@gmail.com'];
                //testcon.Contact_Type__c='Secondary';
                update testcon;
                delete testcon;
                undelete testcon;
            }catch(Exception ex){
                String s1 = ex.getMessage();
                s1 = s1.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ' , ': [');
                System.assertEquals(s1, Label.One_Primary_Contact,'Exception not received');
            } 
            Test.stopTest();
            //delete testcon
        }
    }
    /**
Method  : testValidatePhoneNumber
Purpose : This is used to Validate Phone Number
*/
    @isTest
    public static void testValidatePhoneNumber(){        
        
        EDGE_UtilityTestClass.createOrgSettings();
       Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        
        User admin = EDGE_UtilityTestClass.runAsUser('addmin03','System Administrator'); 
        admin.Available_Countries__c = 'GB';
        insert admin;
        
        System.runAs(admin){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.Country__c = geoMap.get('Country');
            testoutlet.Hub__c = geoMap.get('Hub');
            testoutlet.Region__c=geoMap.get('Region');
            testoutlet.Area__c=geoMap.get('Area');
            testoutlet.Market__c = geoMap.get('Market');
            testoutlet.Cluster__c= geoMap.get('Cluster');
            insert testoutlet;
            system.assert(testoutlet.Id != null,'testoutlet should not be null');
            
            Test.startTest();
            List<Contact> lstContact = new List<Contact>();
            
            Contact primCon=new Contact(FirstName='fname',
                                        LastName = 'lname',
                                        Email = 'email@gmail.com',
                                        MobilePrefix__c = '+61',
                                        Mobile__c = '512 123 123',
                                        PhonePrefix__c = '+61',
                                        Phone__c = '1 2222 3333',
                                        AccountID=testoutlet.Id); 
            lstContact.add(primCon);
            
            Contact secondCon=new Contact(FirstName='fname1',
                                          LastName = 'lname1',
                                          Email = 'email1@gmail.com',
                                          MobilePrefix__c = '+61',
                                          Mobile__c = '512 123 456',
                                          PhonePrefix__c = '+34',
                                          Phone__c = '123 456 789',
                                          AccountID=testoutlet.Id); 
            lstContact.add(secondCon);
            
            Contact thirdCon=new Contact(FirstName='fname1',
                                         LastName = 'lname1',
                                         Email = 'email1@gmail.com',
                                         MobilePrefix__c = '+61',
                                         Mobile__c = '512 123 4562',
                                         PhonePrefix__c = '+34',
                                         Phone__c = '123 456 7892',
                                         AccountID=testoutlet.Id);
            lstContact.add(thirdCon);
            Contact fourthCon=new Contact(FirstName='fname1',
                                          LastName = 'lname1',
                                          Email = 'email2@gmail.com',
                                          MobilePrefix__c = '+61',
                                          Mobile__c = '512 123 452',
                                          PhonePrefix__c = '+34',
                                          Phone__c = '123 456 7892',
                                          AccountID=testoutlet.Id);
            lstContact.add(fourthCon);
            
            Contact fifthCon=new Contact(FirstName='fname1',
                                         LastName = 'lname1',
                                         Email = 'email2@gmail.com',
                                         PhonePrefix__c = '+34',
                                         Phone__c = '123 456 784',
                                         AccountID=testoutlet.Id);
            lstContact.add(fifthCon);
            
            try{
                insert lstContact;            
            } catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());   
            }
            
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testupdateEmailPreference(){ 
        
        EDGE_UtilityTestClass.createOrgSettings();
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        
        User admin = EDGE_UtilityTestClass.runAsUser('addmin04','System Administrator'); 
        admin.Available_Countries__c = 'GB';
        insert admin;
        
        System.runAs(admin){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.Country__c = geoMap.get('Country');
            testoutlet.Hub__c = geoMap.get('Hub');
            testoutlet.Region__c=geoMap.get('Region');
            testoutlet.Area__c=geoMap.get('Area');
            testoutlet.Market__c = geoMap.get('Market');
            testoutlet.Cluster__c= geoMap.get('Cluster');
            insert testoutlet;
            system.assert(testoutlet.Id != null,'testoutlet should not be null');
            
            Test.startTest();
            List<Contact> lstContact = new List<Contact>();
            
            Contact primCon=new Contact(FirstName='fname',
                                        LastName = 'lname',
                                        Email = 'email@gmail.com',
                                        MobilePrefix__c = '+61',
                                        Mobile__c = '512 123 123',
                                        PhonePrefix__c = '+61',
                                        Phone__c = '1 2222 3333',
                                        AccountID=testoutlet.Id,MD_ContactSubscriptions__c='Email'); 
            
            lstContact.add(primCon);
            Contact secondCon=new Contact(FirstName='fname1',
                                          LastName = 'lname1',
                                          Email = 'email1@gmail.com',
                                          MobilePrefix__c = '+61',
                                          Mobile__c = '512 123 456',
                                          PhonePrefix__c = '+34',
                                          Phone__c = '123 456 789',
                                          AccountID=testoutlet.Id); 
            lstContact.add(secondCon);
            
            try{
                insert lstContact; 
                
            } catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            }
            
            Test.stopTest();
        }
    }  
}