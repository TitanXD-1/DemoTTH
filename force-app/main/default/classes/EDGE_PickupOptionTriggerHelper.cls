/**

* @description :  EDGE_PickupOptionTriggerHelper

* @history :

* @Version   Developer     	  	Date       	User Story	 		 	Purpose
*  1.0       Preyanka Ghosh    21/05/2019   ES20-1615
*  2.0       Sandeep Sahoo     27/06/2019   ES20-2081/ES20-3111
*  3.0       Sandip Ghosh      10/04/2020   ES20-7826 				SFDC_US 13- Calculation of Total Activation KPI(reCalcKPIAchievements)
*  3.1       Shahbaz Khan      13/12/2020   ES20-8860 				Exclude pickuption with AS from Target Calculation of KPI Achievements
*  3.2		 Prasanth T		   29/07/2021	ES20-10743
*  3.3		 Anand Uppalapati  29/07/2021	ES20-10807
*  3.4		 Sayan Mullick		10/12/2021	CST-162
*  3.5		 Jayashree		   21/12/2022   CONS-261				Changes made to share the pickup options for Customer Onboarding
*/
public with sharing class EDGE_PickupOptionTriggerHelper {
    final static String RBReasonRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();     
    final static String RBReasonCategoryRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();     
    final static String QualityResolutionRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Resolution Code').getRecordTypeId();     
    final static String QualityReasonRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Reason Code').getRecordTypeId();
    //ES20-7826 : Re-calculate the target if the Include_in_Total_Activation_Survey_KPI__c field value is changed
    public static void reCalcKPIAchievements(List<Pick_Up_Options__c> newItems,Map<Id, SObject> oldItems){
        
        Map<Id, Pick_Up_Options__c> mapOldItems;
        List<Id> lstChangedPickupOptions = new List<Id>();
        List<KPI_Achivement__c> lstKPIAchvsToUpdate = new List<KPI_Achivement__c>();
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Pick_Up_Options__c>)oldItems;
        }
        
        for(Pick_Up_Options__c objPickupOption : newItems){//checked if Applicable Business role is changed
            if(mapOldItems.containsKey(objPickupOption.Id) && (objPickupOption.Include_in_Total_Activation_Survey_KPI__c != mapOldItems.get(objPickupOption.Id).Include_in_Total_Activation_Survey_KPI__c) || (objPickupOption.Applicable_Business_Role__c != mapOldItems.get(objPickupOption.Id).Applicable_Business_Role__c)){
                lstChangedPickupOptions.add(objPickupOption.Id);
            }
        }        
        if(lstChangedPickupOptions.size() > 0){//modified below query for ES20-8860
            for(KPI_Achivement__c kpiAchv : [Select Id,Territory__c,KPI_Type__c,Survey_KPI__c, Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c,Target_Derived__c,Activation_Type__c from KPI_Achivement__c where Survey_KPI__c in :lstChangedPickupOptions OR  Activation_Type__c IN :lstChangedPickupOptions]){
                lstKPIAchvsToUpdate.add(kpiAchv);  
            }
        }        
        if(lstKPIAchvsToUpdate.size() > 0){
            //Database.update(lstKPIAchvsToUpdate);
            EDGE_KPIAchivementTriggerHelper.populateActKPITarget(lstKPIAchvsToUpdate, null, true); 
        }
    }
    
    /*
* @Method  : checkAndGenerateSharingfromSalesOrg
* @Purpose : To create sharing record on Insert
*/
    public static void checkAndGenerateSharingfromSalesOrg(List<Pick_Up_Options__c> newItems){
        //CONS-261 : Changes made to share the pickup options for Customer Onboarding.
        List<Pick_Up_Options__c> pickupOptions = new List<Pick_Up_Options__c>();
        List<String> recordTypes = new List<String>();
        for(String rt : Label.CO_Pickup_Option_Record_Types.split(';')){
            recordTypes.add(rt.trim());
        }
        List<RecordType> pickupOptionRTs = [select Id,Name from RecordType where sObjectType='Pick_Up_Options__c' and Name IN :recordTypes];
        List<String> recordTypeIds = new List<String>();
        for(RecordType rt : pickupOptionRTs){
            recordTypeIds.add(rt.Id);
        }
        for(Pick_Up_Options__c pickUpOpt : newItems)
        {
            if(recordTypeIds.contains(pickUpOpt.RecordTypeId))
            {
                pickupOptions.add(pickUpOpt);
            }
        }
        if(pickupOptions != null && pickupOptions.size()>0){
            CST_SharingUtil.validateCreatePermission(pickupOptions, 'Sales_Organisation__c');
            CST_SharingUtil.generateSharingFromSalesOrg(pickupOptions, 'Sales_Organisation__c', 'Read');
            CST_SharingUtil.generateSharingFromSalesOrg(pickupOptions, 'Sales_Organisation__c', 'Edit');
        }   
    }
    
/*
* @Method  : validateAndReGenerateSharingfromSalesOrg
* @Purpose : Modify, Validate sharing record on update
*/
    public static void validateAndReGenerateSharingfromSalesOrg(List<Pick_Up_Options__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Pick_Up_Options__c> mapOldItems;
        List<Pick_Up_Options__c> lstNewChangeGeography = new List<Pick_Up_Options__c>();

        List<Pick_Up_Options__c> lstOldChangeGeography = new List<Pick_Up_Options__c>();
        //CONS-261 : Changes made to share the pickup options for Customer Onboarding.
        List<String> recordTypes = new List<String>();
        for(String rt : Label.CO_Pickup_Option_Record_Types.split(';')){
            recordTypes.add(rt.trim());
        }
        List<RecordType> pickupOptionRTs = [select Id,Name from RecordType where sObjectType='Pick_Up_Options__c' and Name IN :recordTypes];
        List<String> recordTypeIds = new List<String>();
        for(RecordType rt : pickupOptionRTs){
            recordTypeIds.add(rt.Id);
        }
        CST_SharingUtil.validateEditPermission(newItems);
        if(oldItems != null){
            mapOldItems = (Map<Id, Pick_Up_Options__c>)oldItems;
        }
        for(Pick_Up_Options__c objPickupOption : newItems){
            if( recordTypeIds.contains(objPickupOption.RecordTypeId) && mapOldItems.containsKey(objPickupOption.Id) && objPickupOption.Sales_Organisation__c != mapOldItems.get(objPickupOption.Id).Sales_Organisation__c){
                lstNewChangeGeography.add(objPickupOption);
                lstOldChangeGeography.add(mapOldItems.get(objPickupOption.Id));

            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            CST_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Sales_Organisation__c');

            CST_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Sales_Organisation__c');

            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeGeography, 'Sales_Organisation__c', 'Read');
            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeGeography, 'Sales_Organisation__c', 'Edit');
        }
    }
    
/*
* @Method  : checkAndGenerateSharing
* @Purpose : To create sharing record on Insert
*/
    public static void checkAndGenerateSharing(List<Pick_Up_Options__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Down', 'Edit');        
    }
    
/*
* @Method  : validateAndReGenerateSharing
* @Purpose : Modify, Validate sharing record on update
*/
    public static void validateAndReGenerateSharing(List<Pick_Up_Options__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Pick_Up_Options__c> mapOldItems;
        List<Pick_Up_Options__c> lstNewChangeGeography = new List<Pick_Up_Options__c>();
        List<Pick_Up_Options__c> lstOldChangeGeography = new List<Pick_Up_Options__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Pick_Up_Options__c>)oldItems;
        }
        
        for(Pick_Up_Options__c objPickupOption : newItems){
            if(mapOldItems.containsKey(objPickupOption.Id) && objPickupOption.Geography__c != mapOldItems.get(objPickupOption.Id).Geography__c){
                lstNewChangeGeography.add(objPickupOption);
                lstOldChangeGeography.add(mapOldItems.get(objPickupOption.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Down', 'Edit');
        }       
    }
    
/*
* @Method  : markforDeletion for Account,Product,OpportunityTemplate Pickup Options
* @Purpose : Find Unused Pickup Option and Mark for Deletion
*/
    public static void markforDeletion(List<Pick_Up_Options__c> newItems,Map<Id, SObject> oldItems){        
        Map<Id, Pick_Up_Options__c> mapOldItems;
        Set<Id> pickupOptionOppTemplateSet = new Set<Id>();
        Set<Id> pickupOptionProductSet = new Set<Id>();
        Set<Id> pickupOptionAccountSet = new Set<Id>();
        Set<Id> pickupOptionSurveySet = new Set<Id>(); //added by Shahbaz Khan for Survey KPI type story ES20-4592
        if(oldItems != null){
            mapOldItems = (Map<Id, Pick_Up_Options__c>)oldItems;
        }
        
        for(Pick_Up_Options__c objPickupOption : newItems){
            if(objPickupOption.Status__c != mapOldItems.get(objPickupOption.Id).Status__c && objPickupOption.Status__c =='Marked for Deletion' && objPickupOption.Type__c =='MAS'){
                pickupOptionOppTemplateSet.add(objPickupOption.Id);
            }else if(objPickupOption.Status__c != mapOldItems.get(objPickupOption.Id).Status__c && objPickupOption.Status__c =='Marked for Deletion' && objPickupOption.Type__c =='Product Type'){
                pickupOptionProductSet.add(objPickupOption.Id);
            }
            //added 1 else if condtion for ES20-4592 by Shahbaz Khan
            else if(objPickupOption.Status__c != mapOldItems.get(objPickupOption.Id).Status__c && objPickupOption.Status__c == 'Marked for Deletion' && objPickupOption.Type__c == 'Survey KPI'){
                pickupOptionSurveySet.add(objPickupOption.Id);  
            }else if(objPickupOption.Status__c != mapOldItems.get(objPickupOption.Id).Status__c && objPickupOption.Status__c =='Marked for Deletion' ){
                pickupOptionAccountSet.add(objPickupOption.Id);
            }
        }
        
        //Call markOpportunityTemplateDelete Method
        if(pickupOptionOppTemplateSet.size()>0){
            markOpportunityTemplateDelete(pickupOptionOppTemplateSet, newItems);
        }
        
        //Call markProductDelete Method
        if(pickupOptionProductSet.size()>0){
            markProductDelete(pickupOptionProductSet, newItems);
        }
        
        //Call markAccountDelete Method
        if(pickupOptionAccountSet.size()>0){
            markAccountDelete(pickupOptionAccountSet, newItems);
        }
        //call markSurveyKPIDelete method (added by Shahbaz Khan for ES20-4592)
        if(pickupOptionSurveySet.size()>0){
            markSurveyKPIDelete(pickupOptionSurveySet,newItems);
        }
    }
    
    //Check Pickup Option value exists for Active Opportunity Templates, status cannot be changed to Mark for Deletion
    public static void markOpportunityTemplateDelete(Set< Id> pickupOptionOppTemplateSet, List<Pick_Up_Options__c> newItems){
        Map<Id, Boolean> pickupOptionCheckMap = new Map<Id, Boolean>();
        for(Opportunity_Template__c oppoTemplateRec : [Select Id, Activation__c from Opportunity_Template__c where Activation__c IN: pickupOptionOppTemplateSet AND (End_Date__c >= Today OR End_Date__c = NULL)]){            
            pickupOptionCheckMap.put(oppoTemplateRec.Activation__c, True);
        }
        
        for(Pick_Up_Options__c pickUpOptionRec : newItems) {
            if(pickupOptionCheckMap.size()>0 && pickupOptionCheckMap.containsKey(pickUpOptionRec.Id)){
                pickUpOptionRec.addError(label.Status_cannot_be_changed_to_Mark_for_Deletion_for_Opportunity_Template);   
            }else{
                pickUpOptionRec.Deletion_Date__c = Date.today();
            }
        }       
    }
    
    //Check Pickup Option value exists for POS Products, status cannot be changed to Mark for Deletion
    public static void markProductDelete(Set< Id> pickupOptionProductSet, List<Pick_Up_Options__c> newItems){
        Id posRecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('POS').getRecordTypeId();
        Map<Id, Boolean> pickupOptionCheckMapforProduct = new Map<Id, Boolean>();
        for(Product__c productRec : [Select Id, Product_Type__c from Product__c where Product_Type__c IN: pickupOptionProductSet AND RecordTypeId =:posRecordTypeId]){
            pickupOptionCheckMapforProduct.put(productRec.Product_Type__c,True);
        }
        
        for(Pick_Up_Options__c pickUpOptionRec : newItems) {
            if(pickupOptionCheckMapforProduct.size()>0 && pickupOptionCheckMapforProduct.containsKey(pickUpOptionRec.Id)){
                pickUpOptionRec.addError(label.Status_cannot_be_changed_to_Mark_for_Deletion_for_Product);
            }else{
                pickUpOptionRec.Deletion_Date__c = Date.today();
            }
        }
    }
    
    //Check Pickup Option value exists for Active/Temporarily Closed Outlets, status cannot be changed to Mark for Deletion
    public static void markAccountDelete(Set<Id> pickupOptionAccountSet, List<Pick_Up_Options__c> newItems){
        Map<Id, Boolean> pickupOptionCheckMapforAccount = new Map<Id, Boolean>();
        for(Account accountRec : [Select Id, Consumer_Segmentation__c, Local_Segment1__c, Local_Segment2__c, Outlet_Visit_Prioritisation_Grade__c, 
                                  Reporting_Unit__c, Responsible_Group__c,  Store_Size__c from Account 
                                  where (Consumer_Segmentation__c IN: pickupOptionAccountSet 
                                         OR Local_Segment1__c IN: pickupOptionAccountSet 
                                         OR Local_Segment2__c IN: pickupOptionAccountSet 
                                         OR Outlet_Visit_Prioritisation_Grade__c IN: pickupOptionAccountSet 
                                         OR Reporting_Unit__c IN: pickupOptionAccountSet 
                                         OR Responsible_Group__c IN: pickupOptionAccountSet
                                         OR Store_Size__c IN: pickupOptionAccountSet )
                                  AND Status__c NOT IN ('Active','Temporarily Closed')])
        {
            pickupOptionCheckMapforAccount.put(accountRec.Consumer_Segmentation__c, True);
            pickupOptionCheckMapforAccount.put(accountRec.Local_Segment1__c, True);
            pickupOptionCheckMapforAccount.put(accountRec.Local_Segment2__c, True);
            pickupOptionCheckMapforAccount.put(accountRec.Outlet_Visit_Prioritisation_Grade__c, True);
            pickupOptionCheckMapforAccount.put(accountRec.Reporting_Unit__c, True);
            pickupOptionCheckMapforAccount.put(accountRec.Responsible_Group__c, True);
            pickupOptionCheckMapforAccount.put(accountRec.Store_Size__c, True);
        }
        
        for(Pick_Up_Options__c pickUpOptionRec : newItems) {
            if(pickupOptionCheckMapforAccount.containsKey(pickUpOptionRec.Id)){
                pickUpOptionRec.addError(label.Status_cannot_be_changed_to_Mark_for_Deletion_for_Account);
            }else{
                pickUpOptionRec.Deletion_Date__c = Date.today();
            }
        }
    }
    //method added by Shahbaz Khan for ES20-4592 to implement markSurveyKPIDelete method
    public static void markSurveyKPIDelete(Set<Id> pickupOptionSurveySet,List<Pick_Up_Options__c> newItems){
        
        Map<Id,Boolean> pickupOptMapforSurvey = new Map<Id,Boolean>();
        for(Bonus_Detail__c objBonusDetail : [SELECT Id,Survey_KPI__c from Bonus_Detail__c where Survey_KPI__c IN: pickupOptionSurveySet]){
            pickupOptMapforSurvey.put(objBonusDetail.Survey_KPI__c,True);
        }
        
        for(Pick_Up_Options__c objPickupOpt : newItems){
            if(pickupOptMapforSurvey.containsKey(objPickupOpt.Id) && pickupOptMapforSurvey.get(objPickupOpt.Id)){
                objPickupOpt.addError(Label.EDGE_Status_cannot_be_changed_to_Maked_For_Deletion);
            }
            else{
                objPickupOpt.Deletion_Date__c = System.today();
            }
        }
    }
/*
   ES20-10743 && ES20-10807
* @Method: insertNameField
* @Created this method to update the Name API from pick up option Object according to the recordtypes.
*/
    public static void insertNameField(List<sObject> newItems){
        List<Pick_Up_Options__c> pickupOptions = (List<Pick_Up_Options__c>)newItems;
        Set<Id> pickupOptionsIdSet = new Set<Id>();
        Set<Id> geoSet = new Set<Id>();
        Set<Id> reasonCategorySet = new Set<Id>();
        Map<Id,String> geoCodeMap = new Map<Id,String>();
        Map<Id,String> reasonCategoryNameMap = new Map<Id,String>();
        Id geographyEU;
        if(pickupOptions != null && pickupOptions.Size()>0){
            for (Pick_Up_Options__c pickupOptnId :pickupOptions ){
                pickupOptionsIdSet.add(pickupOptnId.Id);
                if(pickupOptnId.Geography__c != null ) {
                geoSet.add(pickupOptnId.Geography__c);
                }
                if(pickupOptnId.Reason_Category__c != null){
                reasonCategorySet.add(pickupOptnId.Reason_Category__c);
                }
            }
        }
        if(geoSet != null){            
            for (Geography__c geoId: [SELECT ID , Code__c FROM Geography__c WHERE Id IN :geoSet OR Code__c ='EU']){
                geoCodeMap.put(geoId.Id,geoId.Code__c);
                if(geoId.Code__c=='EU'){
                    geographyEU = geoId.Id;         
                }
            }
        }
        if(reasonCategorySet != null && reasonCategorySet.Size()>0){
            for(Pick_Up_Options__c rCid : [SELECT ID , Reason_Category_Name__c FROM Pick_Up_Options__c WHERE Id IN :reasonCategorySet]){
                reasonCategoryNameMap.put(rCid.id,rCid.Reason_Category_Name__c);
            }
        }
        if(pickupOptions != null && pickupOptions.Size()>0 && geoCodeMap!=null && geoCodeMap.Size()>0){
            for(Pick_Up_Options__c pckRec : pickupOptions){
                if(pckRec.RecordTypeId == RBReasonCategoryRecordTypeId && pckRec.Reason_Category_Name__c != null && geographyEU !=null){
                    //RB Reason Category is specific to EU Market as of ES20-10743
                    pckRec.Geography__c = geographyEU;
                    pckRec.Name = pckRec.Reason_Category_Name__c + '['+geoCodeMap.get(geographyEU)+']';
                }
                else if(pckRec.RecordTypeId == RBReasonRecordTypeId && pckRec.Reason_Code_Name__c != null ){
                    String geoCodeString = geoCodeMap.get(pckRec.Geography__c);
                    if(geoCodeString != null){
                        String reasonCategoryName = reasonCategoryNameMap.get(pckRec.Reason_Category__c);
                        if(reasonCategoryName==null){
                            reasonCategoryName = '';
                        }
                        pckRec.Name = reasonCategoryName + pckRec.Reason_Code_Name__c   + '[' + geoCodeString + ']';
                    }
                }      
                else if(pckRec.RecordTypeId == QualityResolutionRecordTypeId && pckRec.Resolution_Code_Name__c != null ){
                    String geoCodeString = geoCodeMap.get(pckRec.Geography__c);
                    pckRec.Name = pckRec.Resolution_Code_Name__c   +'['+geoCodeString+']';
                }                
                else if(pckRec.RecordTypeId == QualityReasonRecordTypeId && pckRec.Reason_Code_Name__c != null){
                    String geoCodeString = geoCodeMap.get(pckRec.Geography__c);
                    pckRec.Name = pckRec.Reason_Code_Name__c   +'['+geoCodeString+']';
                }   
            }
        }
    }
    
    public static void updateNameField(List<Pick_Up_Options__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Pick_Up_Options__c> mapOldItems = new Map<Id, Pick_Up_Options__c>();
        List<Pick_Up_Options__c> pickupOptions = (List<Pick_Up_Options__c>)newItems;
        Set<Id> pickupOptionsIdSet = new Set<Id>();
        Set<Id> geoSet = new Set<Id>();
        Set<Id> reasonCategorySet = new Set<Id>();
        Map<Id,String> geoCodeMap = new Map<Id,String>();
        Map<Id,String> reasonCategoryNameMap = new Map<Id,String>();
        Id geographyEU;
        Map<Id,Id> oldIdRectypeMap = new Map<Id,Id>();
        if(oldItems != null){
            mapOldItems = (Map<Id, Pick_Up_Options__c>)oldItems;
        }
        if(pickupOptions != null && pickupOptions.Size()>0){
            for (Pick_Up_Options__c pickupOptnId :pickupOptions ){
                pickupOptionsIdSet.add(pickupOptnId.Id);
                if(pickupOptnId.Geography__c != null){
                    geoSet.add(pickupOptnId.Geography__c);
                }
                if(pickupOptnId.Reason_Category__c != null){
                reasonCategorySet.add(pickupOptnId.Reason_Category__c);
                }
            }
        }
        
        if(geoSet != null && geoSet.Size()>0){            
            for (Geography__c geoId: [SELECT ID , Code__c FROM Geography__c WHERE Id IN :geoSet OR Code__c ='EU']){
                geoCodeMap.put(geoId.Id,geoId.Code__c);
                if(geoId.Code__c=='EU'){
                    geographyEU = geoId.Id;         
                }
            }
        }
        if(reasonCategorySet != null && reasonCategorySet.Size()>0){
            for(Pick_Up_Options__c rCid : [SELECT ID , Reason_Category_Name__c FROM Pick_Up_Options__c WHERE Id IN :reasonCategorySet]){
                reasonCategoryNameMap.put(rCid.id,rCid.Reason_Category_Name__c);
            }
        }
        if(mapOldItems != null && mapOldItems.Size()>0){
            for(Pick_Up_Options__c rCid : [SELECT ID , RecordTypeID FROM Pick_Up_Options__c WHERE Id IN :mapOldItems.keySet()]){
                oldIdRectypeMap.put(rCid.id,rCid.RecordTypeID);
            }
        }
        if(pickupOptions != null && pickupOptions.size()>0 && geoCodeMap!=null && geoCodeMap.Size()>0){
            for(Pick_Up_Options__c pckRec : pickupOptions){
                if(mapOldItems.containskey(pckRec.Id)){            
                    if(oldIdRectypeMap.get(pckRec.Id)== RBReasonCategoryRecordTypeId
                       &&  pckRec.RecordTypeId == RBReasonCategoryRecordTypeId 
                       && (pckRec.Geography__c != mapOldItems.get(pckRec.Id).Geography__c
                           || pckRec.Reason_Category_Name__c != mapOldItems.get(pckRec.Id).Reason_Category_Name__c
                           ||pckRec.Name != mapOldItems.get(pckRec.Id).Name )              
                       && geographyEU !=null){
                           pckRec.Id = mapOldItems.get(pckRec.Id).Id;
                           pckRec.Geography__c = geographyEU;
                           if (pckRec.Reason_Category_Name__c == null){
                               pckRec.Reason_Category_Name__c ='';
                       }
                           pckRec.Name = pckRec.Reason_Category_Name__c + '['+geoCodeMap.get(geographyEU)+']';
                       }
                    else if(oldIdRectypeMap.get(pckRec.Id)== RBReasonRecordTypeId
                            && pckRec.RecordTypeId == RBReasonRecordTypeId
                            && (pckRec.Reason_Code_Name__c != mapOldItems.get(pckRec.Id).Reason_Code_Name__c
                                || pckRec.Geography__c != mapOldItems.get(pckRec.Id).Geography__c
                                || pckRec.Reason_Category__c != mapOldItems.get(pckRec.Id).Reason_Category__c
                                ||pckRec.Name != mapOldItems.get(pckRec.Id).Name)
                           ){
                               pckRec.Id = mapOldItems.get(pckRec.Id).Id;
                               String geoCodeString = geoCodeMap.get(pckRec.Geography__c);
                               if(geoCodeString != null){
                                   String reasonCategoryName = reasonCategoryNameMap.get(pckRec.Reason_Category__c);
                                   if(reasonCategoryName==null){
                                       reasonCategoryName = '';
                                   }
                                        if( pckRec.Reason_Code_Name__c == null){
                                            pckRec.Reason_Code_Name__c='';
                                       }
                                   pckRec.Name = reasonCategoryName + pckRec.Reason_Code_Name__c   + '[' + geoCodeString + ']';
                                   }     
                           }
                    else if(oldIdRectypeMap.get(pckRec.Id)== QualityResolutionRecordTypeId
                            && pckRec.RecordTypeId == QualityResolutionRecordTypeId
                            && (pckRec.Resolution_Code_Name__c != mapOldItems.get(pckRec.Id).Resolution_Code_Name__c
                                || pckRec.Geography__c != mapOldItems.get(pckRec.Id).Geography__c
                                ||pckRec.Name != mapOldItems.get(pckRec.Id).Name)
                           ){
                               pckRec.Id = mapOldItems.get(pckRec.Id).Id;
                               String geoCodeString = geoCodeMap.get(pckRec.Geography__c);
                               if(pckRec.Resolution_Code_Name__c==null){
                                   pckRec.Resolution_Code_Name__c='';
                               }
                               pckRec.Name = pckRec.Resolution_Code_Name__c   +'['+geoCodeString+']';
                           }                
                    else if(oldIdRectypeMap.get(pckRec.Id)== QualityReasonRecordTypeId
                            && pckRec.RecordTypeId == QualityReasonRecordTypeId
                            && (pckRec.Reason_Code_Name__c != mapOldItems.get(pckRec.Id).Reason_Code_Name__c
                                || pckRec.Geography__c != mapOldItems.get(pckRec.Id).Geography__c
                                ||pckRec.Name != mapOldItems.get(pckRec.Id).Name)
                           ){
                               pckRec.Id = mapOldItems.get(pckRec.Id).Id;
                               String geoCodeString = geoCodeMap.get(pckRec.Geography__c);
                               if(pckRec.Reason_Code_Name__c==null){
                                   pckRec.Reason_Code_Name__c='';
                               }
                               pckRec.Name = pckRec.Reason_Code_Name__c   +'['+geoCodeString+']';
                           }
                }
            }
        }
    }
            
}