/**
* @description EDGE_FieldPermissionTriggerTest
* @history

* @VERSION  		AUTHOR             DATE              DETAIL
* @1.0        Monalisa Halder      10/08/2021       Initial Development(ES20-10866)
* @2.0        Joshraj Sen          21/02/2022       ES20-12118
* @3.0        Sakshi Shah          15/05/2024       PMD Fix
**/
@isTest
public class EDGE_FieldPermissionTriggerTest {
        
    /**
    * @description updateParentDependentFieldTest
    */
    @isTest
    public static void updateParentDependentFieldTest(){
        List<Field_Permission__c> fieldPermissionList = new List<Field_Permission__c>();
        test.startTest();
         
        //Create Org Setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null,'Country Id should not be null.');
        
        //Create Market Setting record
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null,'Market Setting should not be null.');
        
        //Create Field Permission Set record
        Field_Permission_Set__c fpsDefOutlet1 = new Field_Permission_Set__c(Market_Setting__c=newMs.Id,Type__c='Default Outlet');
        insert fpsDefOutlet1;
        
        //Create Field Permission record
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Field_Permission_Set__c = fpsDefOutlet1.id;
        fp.Permission__c = 'Editable & Mandatory';
        fp.Field__c = 'Global_Channel__c';
        fieldPermissionList.add(fp);
       
		//Create Field Permission record 2
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Field_Permission_Set__c = fpsDefOutlet1.id;
        fp1.Permission__c = 'Editable & Mandatory';
        fp1.Field__c = 'Global_Segment__c';
        fieldPermissionList.add(fp1);
        
        //Create Field Permission record 3
        Field_Permission__c fp2 = new Field_Permission__c();
        fp2.Related_Object__c = 'Account';
        fp2.Field_Permission_Set__c = fpsDefOutlet1.id;
        fp2.Permission__c = 'Editable & Mandatory';
        fp2.Field__c = 'Global_Sub_channel__c';
        fieldPermissionList.add(fp2);
        
        insert fieldPermissionList;
        
        delete fp2;
        undelete fp2;
        
        test.stopTest();
    }
    
}