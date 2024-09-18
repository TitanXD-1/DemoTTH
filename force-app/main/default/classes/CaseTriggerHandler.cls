/**

*@Description: CaseTriggerHandler

*@Purpose: Trigger Handler Class for Case

*@History:

*@Version	Developer		    Date			Story/Purpose

* 1.0      Saurav Prasad      12/06/2020        Initial Development
* 2.0	   Kapil Baliyan	  05/05/2021		NCP-3064
* 3.0	   Sayan Samaddar	  25/05/2021		NCP-2825
* 4.0	   Dinesh Sharma	  20/07/2021		ES20-9229
* 5.0	   Monalisa Halder	  27/07/2021		ES20-9662
* 6.0	   Amar Deep	  	  03/08/2021		NCP-3815,NCP-3817
* 7.0	   Monalisa Halder	  17/09/2021		ES20-10567
* 8.0      Anand U            12/01/2021        ES20-11752
* 9.0      Pratik Kumar       21/12/2021        PION-1586
* 10.0      Anand U            12/01/2021        ES20-11752
* 10.0     Amar Deep          31/01/2022        NCP-6014
* 11.0	   Aparajita	      11/02/2022		ES20-11978
* 12.0		Saurav Prasad	  04/04/2023		CUS-254
* 13.0     SaiKiran           05/04/2023        CUS-255
* 13.1			Saurav Prasad		17/04/2023		CUS-265
* 13.2     Swagat Shaw          27/06/2023      CUS-404
* 13.3     Swagat Shaw        10/07/2023        CUS-405
* 13.4     Suvendu Roy        15/07/2023        CUS-439
* 13.5     Nidhi Jaiswal        25/07/2023       143374
* 13.6		Swagat Shaw			08/09/2023		 144667	
* 13.7	    Mukesh Kanth		25/04/2024		 152905	
* 13.8      Monalisa Halder     02/05/2024      366449(372793)
*/


public class CaseTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Case Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
        PNR_CaseTriggerHandler.updateEntitlementName(newItems);//Added for Pioneer
        
        //Customer Concerns
        CC_CaseTriggerHelper.initialMethod(newItems);
        
        //Added for D1 NCP-2825
        D1_CaseTriggerHelper.updateCaseSalesOrg(newItems);

        //Added for D1 NCP-3064
        D1_CaseTriggerHelper.updateCaseSubjectToStandard(newItems); 
        
        //Populated GUID Field --- ES20-10906
        EDGE_UtilityClass.populateGUID(newItems);
        

        //Populated the Quality Entitlement 
        EDGE_QualitySLAProcessHelper.updateQualityEntitlementName(newItems);
        D1_CaseTriggerHelper.updateCaseOwner(newItems);

        PNR_CaseTriggerHandler.addSoToCase(newItems, null);
        
		D1_CaseTriggerHelper.checkShiptoAccounts(newItems);//CUS-98 change
        
        //CUS-254
        D1_CaseTriggerHelper.createEntitlements(newItems);
        //CUS-265
        D1_CaseTriggerHelper.validateOnCreateAndEdit(newItems);
        //CUS-404
        D1_CaseTriggerHelper.updateCaseAgent(newItems, NULL);
        //CUS-405
        D1_CaseTriggerHelper.validationOnCase(newItems, NULL);
        D1_CaseTriggerHelper.setUpCasePriority(newItems, null);

    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
         CC_CaseTriggerHelper.readOnlyRecordType(oldItems,newItems);//PION-2574
        EDGE_QualityCaseTriggerHelper.restrictCaseStatusUpdate(newItems, oldItems);
       
        
        //Added for D1 NCP-2825
        D1_CaseTriggerHelper.updateCaseSubjectToStandard(newItems.values()); 
        D1_CaseTriggerHelper.updateCaseSalesOrg(newItems.values());
        D1_CaseTriggerHelper.updateCaseStatusToOpen(newItems.values()); //NCP-3865
        
        EDGE_QualityCaseTriggerHelper.pauseMilestone(newItems,oldItems);
        EDGE_QualityCaseTriggerHelper.populateSLAMetForCase(newItems,oldItems);

        PNR_CaseTriggerHandler.validateOwnerChange(newItems,oldItems); //Added as part of Ver 8.0

		EDGE_QualityCaseTriggerHelper.enableManualSLAExtensionFlag(newItems.values(),oldItems);
        EDGE_QualityCaseTriggerHelper.restrictCaseStatusUpdate(newItems, oldItems);
      	PNR_CaseTriggerHandler.addSoToCase(newItems.values(), oldItems);
        
		D1_CaseTriggerHelper.checkShiptoAccounts(newItems.values());//CUS-98 change
        D1_CaseTriggerHelper.validateUserOnEdit(newItems.values(), oldItems);//CUS-115 change
        D1_CaseTriggerHelper.updateClosedBy(newItems.values(), oldItems);//CUS-153 change
        
        //CUS-254
        D1_CaseTriggerHelper.createEntitlements(newItems.values());
        //CUS-265
        D1_CaseTriggerHelper.validateOnCreateAndEdit(newItems.values());
        //CUS-404
        D1_CaseTriggerHelper.updateCaseAgent((List<Case>)newItems.values(), (Map<Id,Case>)oldItems);
        //CUS-405
        D1_CaseTriggerHelper.validationOnCase((List<Case>)newItems.values(), (Map<Id,Case>)oldItems);
        D1_CaseTriggerHelper.setUpCasePriority((List<Case>)newItems.values(), (Map<Id,Case>)oldItems);
   }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        //D1_CaseTriggerHelper.sendCaseToIntouch(newItems); //NCP-3064 // commenting for 366449
        EDGE_CaseTriggerHelper.updateCaseUserCountry(newItems); //ES20-10567
        EDGE_CaseTriggerHelper.createSnowTicket(newItems, null); //ES20-9229
        EDGE_QualityCaseTriggerHelper.setDueDateOnCase(newItems,null,false);
        PNR_CaseTriggerHandler.shareCasesWithoutAccount(newItems, null, 'insert');
        PNR_CaseTriggerHandler.sendEmailToCCCTeam(newitems, null,false);//PION-2494
        D1_CaseTriggerHelper.assignDiageoOneCasesToTerritory(newItems,null,'Insert');//CUS-439
        C360_PushNotificationHelper.sendPushNotification(newItems.values());//144408
        C360_CustomerServiceNotificationHelper.autoFollowOnCaseCreation(newItems.values());//144667

    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       CC_CaseTriggerHelper.ccAfterupdatehandler(newItems,oldItems);
       EDGE_CaseTriggerHelper.insertCaseAttachment(newItems , oldItems); // ES20-9662
       D1_CaseTriggerHelper.sendNotificationToCaseCreater(newItems, oldItems); //NCP-3815,NCP-3817

        EDGE_QualityCaseTriggerHelper.setDueDateOnCase(newItems,oldItems,true);

        EDGE_CaseTriggerHelper.createSnowTicket(newItems, oldItems);//NCP-6014
		PNR_CaseTriggerHandler.shareCasesWithoutAccount(newItems, oldItems, 'update');
        PNR_CaseTriggerHandler.sendEmailToCCCTeam(newitems, oldItems,true);//PION-2492
        D1_CaseTriggerHelper.completeCaseMilestoneOnCaseStatusUpdate(newItems, oldItems);//CUS-255
        D1_CaseTriggerHelper.reOpenCaseMilestoneOnCaseStatus(newItems, oldItems);//CUS-256
        D1_CaseTriggerHelper.assignDiageoOneCasesToTerritory(newItems,oldItems,'Update');//CUS-439
        C360_CustomerServiceNotificationHelper.sendPushNotificationForStatusChange(newItems,oldItems);//144402
        
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
       
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}