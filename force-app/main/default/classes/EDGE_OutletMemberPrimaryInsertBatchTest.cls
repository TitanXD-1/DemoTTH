/*

* @description :  EDGE_OutletMemberPrimaryInsertBatchTest

* @purpose : This is the test class for EDGE_OutletMemberPrimaryInsertBatch

* @history :

* @Version    Developer           Date           User Story/Purpose

*  1.1      Dinesh Sharma       02/03/2021       ES20-9804
*  1.2		Aparajita/Rajarshi  11/03/2022		 ES20-12216,12231,12213
			/Subhodeep     				
*  1.3      Sakshi Shah         22/08/2024       PMD Fix
*/

@isTest
public class EDGE_OutletMemberPrimaryInsertBatchTest {
    public static boolean pendingRepInsert = true;
    public static string countryCode ='AU';
    public static List<Outlet_Member__c> om1List ;
    final static String ACTIVATIONRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); //ES20-12216,12231,12213

    
    @isTest
    public static void outletMemberInsert(){
        createData();
        List<EDGE_BatchSObjectWrapper> wrapperList = new List<EDGE_BatchSObjectWrapper>();
        EDGE_BatchSObjectWrapper wrapper = new EDGE_BatchSObjectWrapper();
        wrapper.operationType = 'Insert';
        wrapper.recordToProcess = om1List[0];
        wrapperList.add(wrapper);
        
        EDGE_BatchSObjectWrapper wrapper1 = new EDGE_BatchSObjectWrapper();
        wrapper1.operationType = 'Update';
        wrapper1.recordToProcess = om1List[1];
        
        wrapperList.add(wrapper1);
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletMemberPrimaryInsertBatch' AND Country_Code__c ='AU'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch Setting should not be null.');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceExtended job = (BatchJobManagementInterfaceExtended)t.newInstance();
        job.getBatchDetails(batchSetting,wrapperList);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
    }
    /**
 * @description create data method
 */
    public static void createData(){
       om1List = new list<Outlet_Member__c>();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        Geography__c country = [SELECT Id, Code__c FROM Geography__c WHERE ID =:countryID LIMIT 1];
        
        //insert pickup option
        Pick_Up_Options__c pickUpVisit1 = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit1.Name = 'Gold[AU]';
        insert pickUpVisit1;
        
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Country__c = country.Id;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit1.Id;
        insert outletAccount;
        
        //create Sales Representative User
        User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
        usr.Business_Role__c = 'Sales Manager';
        usr.trax_user__c=true;
        insert usr; 
        
        User asUsr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
        asUsr.Business_Role__c = 'On Trade Activation Specialist GB';
        insert asUsr; 
        
        //create Outlet Member record
        Outlet_Member__c om = new Outlet_Member__c();
        om.Outlet__c = outletAccount.id;
        om.User__c = usr.id;
        om.Outlet_Role__c = 'Primary';
        om.Pending_for_Rep_Insert_Batch__c = true;
        om1List.add(om);
        
        Outlet_Member__c actOM = new Outlet_Member__c();
        actOM.Outlet__c = outletAccount.id;
        actOM.User__c = asUsr.id;
        actOM.Outlet_Role__c = 'Activation Specialist';
        actOM.Pending_for_Rep_Insert_Batch__c = true;
        om1List.add(actOM);        
    } 
}