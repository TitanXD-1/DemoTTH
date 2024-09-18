/**
*@Name: EDGE_FieldPermissionSetTriggerTest
*@Req: 
*@ES20-9225 

*@History                                                            
                                                           
*@	VERSION   AUTHOR            DATE              DETAIL
*@	1.0      Aparajita       01/02/2021      Initial Development

**/
@isTest
public class EDGE_FieldPermissionSetTriggerTest 
{
    @isTest 
    public static void testcheckDefaultTypeRecords() 
    {
        EDGE_UtilityTestClass.createOrgSettings();
        Id contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null,'contId Inserted');
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null,'newMs Inserted');
        
        Field_Permission_Set__c fpsDefOutlet1 = new Field_Permission_Set__c(Market_Setting__c=newMs.Id,Type__c='Default Outlet');
        insert fpsDefOutlet1;
        Field_Permission_Set__c fpsDefProspect1 = new Field_Permission_Set__c(Market_Setting__c=newMs.Id,Type__c='Default Prospect');
        insert fpsDefProspect1;
        delete fpsDefProspect1;
        undelete fpsDefProspect1; 
        
        Test.startTest();
        try{
            fpsDefProspect1.Type__c='Default Outlet'; 
            update fpsDefProspect1;
        }catch(Exception ex){
            System.Assert(ex.getMessage().contains(System.Label.EDGE_FieldPermissionSetErrorMsg),'Message should contains label value');
        }
        Test.stopTest();     
    }
}