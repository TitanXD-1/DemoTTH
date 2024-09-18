/**
@description EDGE_FieldChangeRequestTriggerHelperTest
@history                                                                                                                       
VERSION     AUTHOR           		DATE            DETAIL
1.0         Dipanjan Das     	21/02/2019      Test Class for EDGE_AccountTriggerHelper
1.1         Saurav Paul     	16/04/2019      Test Class for CheckMandatoryFields
2.0         Monalisa Halder     25/02/2022        ES20-11303
3.0         Sakshi Shah         15/05/2024      PMD Fix
*/
@isTest
public class EDGE_FieldChangeRequestTriggerHelperTest{
    final static String OUTLET_RECORD_TYPE_ID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  

    
    @isTest
    public static void testAccountCreateFieldChangeRequest(){
        
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null,'Sales Manager Id should not be null.');
        
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null,'Sales Representative Id should not be null.');
        
        System.runAs(salesManager){ 
            Id contId = EDGE_UtilityTestClass.setupCountry('AU');
            EDGE_UtilityTestClass.createOrgSettings();
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption; 
            
            Test.startTest();                       
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();  
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;    
            outlet.Minimum_Activation_Standards__c = 90.00;
            outlet.Minimum_Product_Assortment__c = 40.00;
            insert outlet;
            
            Field_Change_Request__c fcrOutlet = new Field_Change_Request__c();
            fcrOutlet.Status__c ='MDM Approved';
            fcrOutlet.Approver__c = salesManager.Id;
            fcrOutlet.Field_Name__c = 'Status__c';
            fcrOutlet.Field_Type__c ='Picklist';
            fcrOutlet.Geography__c =contId;
            fcrOutlet.MDM_Approval_required__c = True;
            fcrOutlet.New_Value__c ='Closed';
            fcrOutlet.Old_Value__c ='Active';
            fcrOutlet.Sales_manager_approval_required__c =False;
            fcrOutlet.Object_Type__c ='Account';
            fcrOutlet.Outlet__c = outlet.Id;
            insert fcrOutlet;
            system.assert(fcrOutlet.Id != null,'Field Change Request Id should not be null.');
            
            Test.stopTest();
        }
        System.runAs(salesManager){
            Group grp = new Group(Name='AUT_MDM', type='Queue');
            insert grp;
            QueueSObject que = new QueueSObject(QueueID = grp.id, SobjectType = 'Geography__c');
            insert que; 
            
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = salesRep.Id;
            grpMem1.GroupId = grp.Id;
            insert grpMem1;            
        }
        
    }
    
    @isTest
    public static void testCreateLicense(){
        
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        insert salesManager;
        
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        
        System.runAs(salesManager){
            Id contId = EDGE_UtilityTestClass.setupCountry('AUT');
            EDGE_UtilityTestClass.createOrgSettings();
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert outlet; 
            
            system.assert(outlet.id != null,'Outlet Id should not be null.');
            
            License__c newLicense = new License__c(Outlet_Id__c=outlet.Id,License_Number__c='123456789',License_Type__c='Wine');
            insert newLicense;
            
            Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId,License_Number__c='Editable & Mandatory - Manager Approval Required');
            insert newMs;
            
            License__c chkLicense = [Select ID, License_Number__c from License__c where ID=: newLicense.Id];
            chkLicense.License_Number__c='007';
            update chkLicense;
            system.assert(chkLicense.Id != null,'License Id should not be null.');
            
            Field_Change_Request__c fcrOutlet = new Field_Change_Request__c();
            fcrOutlet.Status__c ='MDM Approved';
            fcrOutlet.Approver__c = salesManager.Id;
            fcrOutlet.Field_Name__c = 'License_Number__c';
            fcrOutlet.Field_Type__c ='Text';
            fcrOutlet.Geography__c =contId;
            fcrOutlet.MDM_Approval_required__c = True;
            fcrOutlet.New_Value__c ='007';
            fcrOutlet.Old_Value__c ='100';
            fcrOutlet.Sales_manager_approval_required__c =False;
            fcrOutlet.Object_Type__c ='License__c';
            fcrOutlet.License__c = chkLicense.Id;
            insert fcrOutlet;
            system.assert(fcrOutlet.id != null,'Field Request Change Id should not be null.');
            //update the License
            fcrOutlet.Status__c = 'Approved';
            update fcrOutlet;
        }
        System.runAs(salesManager){
            Group g1 = new Group(Name='AUT_MDM', type='Queue');
            insert g1;
            QueueSObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Geography__c');
            insert q1;
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = salesRep.Id;
            grpMem1.GroupId = g1.Id;
            insert grpMem1;            
        }
    }
        @isTest
    public static void testDeleteUndeleteFCR(){
        
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        insert salesManager;
        
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        
        System.runAs(salesManager){
            Id contId = EDGE_UtilityTestClass.setupCountry('AUT');
            EDGE_UtilityTestClass.createOrgSettings();
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert outlet; 
            
            system.assert(outlet.id != null,'Outlet Id should not be null.');
            
            License__c newLicense = new License__c(Outlet_Id__c=outlet.Id,License_Number__c='123456789',License_Type__c='Wine');
            insert newLicense;
            
            Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId,License_Number__c='Editable & Mandatory - Manager Approval Required');
            insert newMs;
            
            License__c chkLicense = [Select ID, License_Number__c from License__c where ID=: newLicense.Id];
            chkLicense.License_Number__c='007';
            update chkLicense;
            system.assert(chkLicense.Id != null,'License Id should not be null.');
            
            Field_Change_Request__c fcrOutlet = new Field_Change_Request__c();
            fcrOutlet.Status__c ='MDM Approved';
            fcrOutlet.Approver__c = salesManager.Id;
            fcrOutlet.Field_Name__c = 'License_Number__c';
            fcrOutlet.Field_Type__c ='Text';
            fcrOutlet.Geography__c =contId;
            fcrOutlet.MDM_Approval_required__c = True;
            fcrOutlet.New_Value__c ='007';
            fcrOutlet.Old_Value__c ='100';
            fcrOutlet.Sales_manager_approval_required__c =False;
            fcrOutlet.Object_Type__c ='License__c';
            fcrOutlet.License__c = chkLicense.Id;
            insert fcrOutlet;
            system.assert(fcrOutlet.id != null,'Field Change Request Id should not be null.');
            //update the License
            fcrOutlet.Status__c = 'Approved';
            update fcrOutlet;
            
            delete fcrOutlet;
            undelete fcrOutlet;
        }
       
    }

        /*******************************************************************
    Method  : approveFieldUpdateRequests
    Purpose : 
    ********************************************************************/
    @isTest
    public static void approveFieldUpdateRequestsTest(){
        
        Id contId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        insert salesManager;
        
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        insert pickupOption; 
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId,License_Number__c='Editable & Mandatory - Manager Approval Required');
        newMs.Centrally_Managed__c = 'Editable - Manager Approval Required';
        insert newMs;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();  
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;    
        outlet.Minimum_Activation_Standards__c = 90.00;
        outlet.Minimum_Product_Assortment__c = 40.00;
        outlet.Centrally_Managed__c = true;
        outlet.Centrally_Managed_Note__c = 'this is first note';
        insert outlet;
        
        Account distriAcc = EDGE_UtilityTestClass.getDistriAccRec();
        insert distriAcc;
        
        Supplier_Outlet__c suppOutlet = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distriAcc.Id);
        suppOutlet.isPrimary__c = true;
        insert suppOutlet;
        
        Field_Change_Request__c fcrOutlet1 = new Field_Change_Request__c();
        //fcrOutlet1.Status__c ='New';
        fcrOutlet1.Field_Name__c = 'Status__c';
        fcrOutlet1.Field_Type__c ='Picklist';
        fcrOutlet1.Object_Type__c = 'Account';
        fcrOutlet1.Approval_Header__c = true;
        fcrOutlet1.Geography__c =contId;
        fcrOutlet1.MDM_Approval_required__c = True;
        fcrOutlet1.New_Value__c ='Closed';
        fcrOutlet1.Old_Value__c ='Active';
        fcrOutlet1.Sales_manager_approval_required__c =False;
        fcrOutlet1.Object_Type__c ='Account';
        fcrOutlet1.Outlet__c = outlet.Id; 
        Test.startTest();
        insert fcrOutlet1;        
        
        fcrOutlet1.Status__c = 'Approved';       
        update fcrOutlet1;
        
        Field_Change_Request__c fcrSupplierOutlet = new Field_Change_Request__c();
        fcrSupplierOutlet.Status__c = 'MDM Approved';
        fcrSupplierOutlet.Field_Name__c = 'isPrimary__c';
        fcrSupplierOutlet.Field_Type__c ='Boolean';
        fcrSupplierOutlet.Geography__c =contId;
        fcrSupplierOutlet.MDM_Approval_required__c = True;
        fcrSupplierOutlet.New_Value__c ='false';
        fcrSupplierOutlet.Old_Value__c ='true';
        fcrSupplierOutlet.Sales_manager_approval_required__c =false;
        fcrSupplierOutlet.Object_Type__c ='Supplier_Outlet__c';
        fcrSupplierOutlet.Supplier_Outlet__c = suppOutlet.Id;
        insert fcrSupplierOutlet;
        
        fcrSupplierOutlet.Status__c = 'Approved';
        update fcrSupplierOutlet;
        system.assert(fcrSupplierOutlet.Id != null,'Field Change Request Id should not be null.');
        Test.stopTest();
        
    }
    
    @isTest
    public static void createFieldChangeRequestLookupTest(){
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        adminUser1.ManagerId = adminUser.Id;
        insert adminUser1; 
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
       
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        insert marketsetting;
        System.assert(marketsetting.Id!=null,'Market Setting Id should not be null.');
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        List <Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        pickUpOptionList.add(pickupOption);
        String localSeg1pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c locaLSeg1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg1.Name = 'LocalSegA[AU]';
        locaLSeg1.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg1.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg1);
        
        Pick_Up_Options__c locaLSeg2 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg2.Name = 'LocalSegAB[AU]';
        locaLSeg2.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg2.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg2);
        insert pickUpOptionList;
        
        Test.startTest();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Local_Segment1__c  = locaLSeg1.Id;
        insert outlet;
        
        System.runAs(adminUser1){
            Group grp = new Group(Name='AU_MDM', type='Queue');
            insert grp;
            QueueSObject que = new QueueSObject(QueueID = grp.id, SobjectType = 'Field_Change_Request__c');
            insert que;
            QueueSObject que1 = new QueueSObject(QueueID = grp.id, SobjectType = 'Geography__c');
            insert que1;    
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = adminUser.Id;
            grpMem1.GroupId = grp.Id;
            insert grpMem1;     
            
            Field_Change_Request__c fcrSupplierOutlet = new Field_Change_Request__c();
            fcrSupplierOutlet.Field_Name__c = 'Local_Segment1__c';
            fcrSupplierOutlet.Field_Type__c ='REFERENCE';
            fcrSupplierOutlet.Geography__c =countryId;
            fcrSupplierOutlet.MDM_Approval_required__c = False;
            fcrSupplierOutlet.Changed_By__c = adminUser1.Id;
            fcrSupplierOutlet.New_Value__c = locaLSeg2.Id;
            fcrSupplierOutlet.Old_Value__c = locaLSeg1.Id;
            //fcrSupplierOutlet.Sales_manager_approval_required__c = True;
            fcrSupplierOutlet.Object_Type__c ='Account';
            fcrSupplierOutlet.Lookup_Object_Type__c ='Pick_Up_Options__c';
            insert fcrSupplierOutlet;
        }
        Test.stopTest();
     } 
    
    @isTest
    public static void createFieldChangeRequestParentTest(){
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        adminUser1.ManagerId = adminUser.Id;
        insert adminUser1; 
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        List <Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        //insert pickupOption;
        pickUpOptionList.add(pickupOption);
        String localSeg1pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c locaLSeg1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg1.Name = 'LocalSegA[AU]';
        locaLSeg1.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg1.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg1);
        
        Pick_Up_Options__c locaLSeg2 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg2.Name = 'LocalSegAB[AU]';
        locaLSeg2.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg2.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg2);
        insert pickUpOptionList;
        
        Test.startTest();
        
        System.runAs(adminUser1){
            Group grp = new Group(Name='AU_MDM', type='Queue');
            insert grp;
            QueueSObject que = new QueueSObject(QueueID = grp.id, SobjectType = 'Field_Change_Request__c');
            insert que;
            QueueSObject que1 = new QueueSObject(QueueID = grp.id, SobjectType = 'Geography__c');
            insert que1;    
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = adminUser.Id;
            grpMem1.GroupId = grp.Id;
            insert grpMem1;  
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.Local_Segment1__c  = locaLSeg1.Id;
            insert outlet; 
            
            List<Field_Change_Request__c> fcrList = new List<Field_Change_Request__c>();
            Field_Change_Request__c fcrGlobalChannel = new Field_Change_Request__c();
            fcrGlobalChannel.Field_Name__c = 'Global_Channel__c';
            fcrGlobalChannel.Field_Type__c ='Picklist';
            fcrGlobalChannel.Geography__c =countryId;
            fcrGlobalChannel.MDM_Approval_required__c = False;
            fcrGlobalChannel.New_Value__c = 'On Trade';
            fcrGlobalChannel.Old_Value__c = 'Off Trade';
            //fcrGlobalChannel.Sales_manager_approval_required__c =false;
            fcrGlobalChannel.Object_Type__c ='Account';
            fcrGlobalChannel.Approval_Description__c = 'Global_Channel__c:Old Value = Off Trade New Value = On Trade , Global_Segment__c:Old Value = Hypermarket New Value = Event , Global_Sub_Segment__c:Old Value = Modern Hypermarket New Value = Modern Event , Global_Sub_Channel__c:Old Value = Retailer New Value = On Trade , Local_Segment1__c:Old Value = locaLSeg1.Id New Value = locaLSeg2.Id , Local_Segment2__c:Old Value = null New Value = null';
            //fcrList.add(fcrSupplierOutlet);
            insert fcrGlobalChannel;
            
            Field_Change_Request__c fcr1 = new Field_Change_Request__c();
            fcr1.Field_Name__c = 'Global_Sub_Channel__c';
            fcr1.Field_Type__c ='Picklist';
            fcr1.Geography__c =countryId;
            fcr1.MDM_Approval_required__c = False;
            fcr1.New_Value__c = 'On Trade';
            fcr1.Old_Value__c = 'Retailer';
            fcr1.Sales_manager_approval_required__c =false;
            fcr1.Object_Type__c ='Account';
            fcr1.Parent_Approval__c = fcrGlobalChannel.Id;
            fcrList.add(fcr1);
            
            Field_Change_Request__c fcr2 = new Field_Change_Request__c();
            fcr2.Field_Name__c = 'Global_Segment__c';
            fcr2.Field_Type__c ='Picklist';
            fcr2.Geography__c =countryId;
            fcr2.MDM_Approval_required__c = False;
            fcr2.New_Value__c = 'Event';
            fcr2.Old_Value__c = 'Hypermarket';
            fcr2.Sales_manager_approval_required__c =false;
            fcr2.Object_Type__c ='Account';
            fcr2.Parent_Approval__c = fcrGlobalChannel.Id;
            fcrList.add(fcr2);
            
            Field_Change_Request__c fcr3 = new Field_Change_Request__c();
            fcr3.Field_Name__c = 'Global_Sub_Segment__c';
            fcr3.Field_Type__c ='Picklist';
            fcr3.Geography__c =countryId;
            fcr3.MDM_Approval_required__c = False;
            fcr3.New_Value__c = 'Modern Event';
            fcr3.Old_Value__c = 'Modern Hypermarket';
            fcr3.Sales_manager_approval_required__c =false;
            fcr3.Object_Type__c ='Account';
            fcr3.Parent_Approval__c = fcrGlobalChannel.Id;
            fcrList.add(fcr3);
            
            Field_Change_Request__c fcr4 = new Field_Change_Request__c();
            fcr4.Field_Name__c = 'Local_Segment1__c';
            fcr4.Field_Type__c ='REFERENCE';
            fcr4.Geography__c =countryId;
            fcr4.MDM_Approval_required__c = False;
            fcr4.New_Value__c = locaLSeg2.Id;
            fcr4.Old_Value__c = locaLSeg1.Id;
            fcr4.Sales_manager_approval_required__c =false;
            fcr4.Object_Type__c ='Account';
            fcr4.Lookup_Object_Type__c ='Pick_Up_Options__c';
            fcr4.Parent_Approval__c = fcrGlobalChannel.Id;
            fcrList.add(fcr4);
            insert fcrList;
            
            Test.stopTest();
        } 
    } 
   
}