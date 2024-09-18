/**********************************************************************
* @description EDGE_FieldPermissionControllerTest
* @Purpose: This is the Test Class for EDGE_FieldPermissionController Class
* @history
                                                           
VERSION  	AUTHOR             DATE              DETAIL
1.0        Dinesh Sharma     15/03/2021       Initial Development(ES20-9141,ES20-9226)
2.0        Joshraj Sen       21/02/2022       ES20-12118
***********************************************************************/
@isTest
public class EDGE_FieldPermissionControllerTest {
    
    /**
    * @description getFieldDetailsTest
    */
    @isTest
    public static void getFieldDetailsTest(){
        
        test.startTest();
          
        //Create Org Setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null,'contId Inserted');
        
        //Create Market Setting record

        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId);

        insert newMs;
        System.assert(newMs != null,'newMs Inserted');
        
        //Create Field Permission Set record
        Field_Permission_Set__c fpsDefOutlet1 = new Field_Permission_Set__c(Market_Setting__c=newMs.Id,Type__c='Default Outlet');
        insert fpsDefOutlet1;
        
        List<Field_Permission__c> fpList=new List<Field_Permission__c>();
        //Create Field Permission record
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Field_Permission_Set__c = fpsDefOutlet1.id;
        fp.Permission__c = 'Editable & Mandatory';
        fp.Field__c = 'Phone';
        fpList.add(fp);
        
        Field_Permission__c fp2 = new Field_Permission__c();
        fp2.Related_Object__c = 'Account';
        fp2.Field_Permission_Set__c = fpsDefOutlet1.id;
        fp2.Permission__c = 'Editable & Mandatory - MDM Approval Required';
        fp2.Field__c = null;
        fp2.Parent_Field_PL__c='Global_Channel__c';
        fpList.add(fp2);
        insert fpList;
        
        EDGE_FieldPermissionController.getFieldPermissionSetRelatedRec(fpsDefOutlet1.id,'Outlet');

        EDGE_FieldPermissionController.getFieldPermissionRecords(fpsDefOutlet1.id,'Default Outlet');
        Map<String,list<String>> updatedRecord = new Map<String,list<String>>();
        
        List<String> detailRecord = new list<String>{'Editable','Account','NA'};
            
            updatedRecord.put('billingCity',detailRecord);
        
        EDGE_FieldPermissionController.insertUpdateFieldPermission(fpsDefOutlet1.id ,updatedRecord,'Default Outlet' );
       
        //Create Field Permission Set record 2
        Field_Permission_Set__c fpsDefProspect1 = new Field_Permission_Set__c(Market_Setting__c=newMs.Id,Type__c='Default Prospect');
        insert fpsDefProspect1;
        
        //Create Field Permission record 2
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Field_Permission_Set__c = fpsDefProspect1.id;
        fp1.Permission__c = 'Editable & Mandatory';
        fp1.Field__c = 'Phone';
        insert fp1;
        
        Map<String,list<String>> updatedRecord1 = new Map<String,list<String>>();
        
        List<String> detailRecord1 = new list<String>{'Editable','Account','NA'};
            
        updatedRecord1.put('billingCity',detailRecord1);

        
        EDGE_FieldPermissionController.insertUpdateFieldPermission(fpsDefProspect1.id ,updatedRecord1,'Default Prospect');
        test.stopTest();
    }
    
}