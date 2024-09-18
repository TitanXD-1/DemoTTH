/**
* @Name    : EDGE_KPIAchivementTriggerHelper
* @Purpose : This is to handle KPI Achivement Trigger Handler Events
* @History :                                                           

* @VERSION  AUTHOR             DATE              DETAIL
*   1.0     Manikant          29-Oct-2019        Initial Development
*   2.0		Sandip Ghosh	  10/04/2020		 [ES20-7826] SFDC_US 13- Calculation of Total Activation KPI(populateActKPITarget,populateTotalTarget)
*   2.1     Shahbaz Khan	  13/12/2020		 [ES20-8860] Exclude pickuption with AS from Target Calculation
*   2.2     Dinesh Sharma     22/01/2021         [ES20-9498] Generate Unique Key for KPI Achievement(populateKpiAchievementUniqueId)
*   2.3     Supriya Galinde   29/10/2021         [ES20-11242] Auto Populate the Country in USer KPI record type.
*   2.4     Supriya Galinde   29/10/2021         [ES20-11241] Populate Unique key in KPI Achievement object.
*   2.5     Debolina Saha     23/03/2022         [ES20-12219] Modification of target calculation_ SFDC_ Activation Specialist Enhancements
**/


public with sharing class EDGE_KPIAchivementTriggerHelper {

    //Variable to stop trigger recursion 
    public static boolean stopKPIAchvTriggerToRun = false;

    /*
     * @Method  : populateActKPITarget
     * @Purpose : Method to polate Activation KPI target
     */
    public static void populateActKPITarget(List < KPI_Achivement__c > newItems, Map < Id, sObject > oldItems, Boolean calledFromPckupTrigger) {

        Set < Id > relatedTerrIds = new Set < Id > ();
        Map < Id, Decimal > terrIdToTotalTargetMap = new Map < Id, Decimal > ();
        List < KPI_Achivement__c > totalKpiAchvRecs = new List < KPI_Achivement__c > ();
        Map < Id, KPI_Achivement__c > totalKpiAchvIdToRecordMap = new Map < Id, KPI_Achivement__c > ();
        Map < Id, KPI_Achivement__c > mapOldKPIAchvments;
        Set < String > allowedKPITypes = new Set < String > {'Activation Survey KPI','Survey','Total Activation Survey'};
        Set < Id > pickupOptionsIdSet = new Set < Id > ();
        Map < ID, Pick_Up_Options__c > pckupOptionsMap;
        
        Id activationTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); //ES20-12219
        Set <Id> territoryIdSet = new Set <Id> (); //ES20-12219 - Set for taking Territory Id
        Map <Id,Id> terrRecTypeMap = new Map <Id,Id> (); //ES20-12219 - Map of Territory RecordType With Territory Id

        if (!stopKPIAchvTriggerToRun) {
            stopKPIAchvTriggerToRun = true;
            system.debug('No of Times ');
            if (oldItems != null) {
                mapOldKPIAchvments = (Map < Id, KPI_Achivement__c > ) oldItems;
            }
            if (newItems != null) {
                for (KPI_Achivement__c newKPiAchvRec: newItems) {
                    if (newKPiAchvRec.Survey_KPI__c != null) { //enclosed in if condition for ES20-8860
                        pickupOptionsIdSet.add(newKPiAchvRec.Survey_KPI__c);
                        territoryIdSet.add(newKPiAchvRec.Territory__c);
                    }
                    if (newKPiAchvRec.Activation_Type__c != null) { //added this if condition for ES20-8860
                        pickupOptionsIdSet.add(newKPiAchvRec.Activation_Type__c);
                        territoryIdSet.add(newKPiAchvRec.Territory__c);
                    }
                }
                
                //ES20-12219 - Territory Map Created to Compare Territory RecordType
                List <Territory__c> terrList = [Select id,Name, RecordTypeId from Territory__c where Id IN: territoryIdSet];
                for (Territory__c terr: terrList) {
                    terrRecTypeMap.put(terr.id,terr.RecordTypeId);
                }
                
                if (pickupOptionsIdSet != null) { //added Applicable_Business_Role__c in below query for ES20-8860
                    pckupOptionsMap = new Map < ID, Pick_Up_Options__c > ([Select Id, Include_in_Total_Activation_Survey_KPI__c, Applicable_Business_Role__c from
                        Pick_Up_Options__c where Id in: pickupOptionsIdSet
                    ]);
                }
            }

            for (KPI_Achivement__c newKPiAchvRec: newItems) {
                if (newKPiAchvRec.Territory__c != null) {
                    Id surveyKPIId = newKPiAchvRec.Survey_KPI__c;
                    Id actKPIId = newKPiAchvRec.Activation_Type__c; //included this variable and modified below if condition for ES20-8860
                    if (terrRecTypeMap.get(newKPiAchvRec.Territory__c) != activationTerrRecordTypeId) { //ES20-12219 - Checking if the territory record type is Activation Territory                        
                    	if (((calledFromPckupTrigger && (newKPiAchvRec.KPI_Type__c == 'Survey' || newKPiAchvRec.KPI_Type__c == 'Activation Survey KPI')) ||
                                (pckupOptionsMap != null && (newKPiAchvRec.KPI_Type__c == 'Activation Survey KPI' && pckupOptionsMap.containsKey(actKPIId) && pckupOptionsMap.get(actKPIId).Applicable_Business_Role__c != 'Activation Specialist') ||
                                    (newKPiAchvRec.KPI_Type__c == 'Survey' && pckupOptionsMap.containsKey(surveyKPIId) && pckupOptionsMap.get(surveyKPIId).Include_in_Total_Activation_Survey_KPI__c && pckupOptionsMap.get(surveyKPIId).Applicable_Business_Role__c != 'Activation Specialist'))
                            ) &&
                            ((mapOldKPIAchvments != null && mapOldKPIAchvments.get(newKPiAchvRec.Id).Target_Derived__c != newKPiAchvRec.Target_Derived__c) ||
                                mapOldKPIAchvments == null)) 
                        {
                            relatedTerrIds.add(newKPiAchvRec.Territory__c);
                        }
                    } 
                    // ES20-12219 - Added Below for Activation Territory Check
                    else if((terrRecTypeMap.get(newKPiAchvRec.Territory__c) == activationTerrRecordTypeId))
                    {
                        if (((calledFromPckupTrigger && (newKPiAchvRec.KPI_Type__c == 'Survey' || newKPiAchvRec.KPI_Type__c == 'Activation Survey KPI')) ||
                                (pckupOptionsMap != null && ((newKPiAchvRec.KPI_Type__c == 'Activation Survey KPI' && pckupOptionsMap.containsKey(actKPIId) && pckupOptionsMap.get(actKPIId).Applicable_Business_Role__c != Null && pckupOptionsMap.get(actKPIId).Applicable_Business_Role__c.Equals('Activation Specialist')) ||
                                    (newKPiAchvRec.KPI_Type__c == 'Survey' && pckupOptionsMap.containsKey(surveyKPIId) && pckupOptionsMap.get(surveyKPIId).Include_in_Total_Activation_Survey_KPI__c && pckupOptionsMap.get(surveyKPIId).Applicable_Business_Role__c != Null && pckupOptionsMap.get(surveyKPIId).Applicable_Business_Role__c.Equals('Activation Specialist'))))) &&
                            ((mapOldKPIAchvments != null && mapOldKPIAchvments.get(newKPiAchvRec.Id).Target_Derived__c != newKPiAchvRec.Target_Derived__c) ||
                                mapOldKPIAchvments == null)) 
                        {
                            relatedTerrIds.add(newKPiAchvRec.Territory__c);
                        }
                    }                 
                                /*else if(newKPiAchvRec.KPI_Type__c == 'Survey'){
                            if(newKPiAchvRec.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c && mapOldKPIAchvments.get(newKPiAchvRec.Id).Target_Derived__c != newKPiAchvRec.Target_Derived__c){
                            relatedTerrIds.add(newKPiAchvRec.Territory__c);
                            }
                            }*/
                                /*else if(calledFromPckOpTrigger && newKPiAchvRec.KPI_Type__c == 'Survey'){//Called from Pickuption Trigger
                            relatedTerrIds.add(newKPiAchvRec.Territory__c);
                            }else{//Insert Scenario
                            if(newKPiAchvRec.KPI_Type__c == 'Activation Survey KPI' || (newKPiAchvRec.KPI_Type__c == 'Survey' && newKPiAchvRec.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c)){
                            relatedTerrIds.add(newKPiAchvRec.Territory__c);
                            }
          			  }*/
                }
            }
           
            
            for (KPI_Achivement__c otherKPIAchvRec: [Select Id, Territory__c, Target_Number__c, Target_Derived__c, KPI_Type__c, Survey_KPI__r.Applicable_Business_Role__c,
                    Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c, Activation_Type__r.Applicable_Business_Role__c from KPI_Achivement__c
                    where Territory__c in: relatedTerrIds and KPI_Type__c IN: allowedKPITypes]) 
            {                   
                //modified below if condition to check whether it has AS as Business Role for ES20-8660
                
                //modified below if condition to check whether the territory is AT and the Applicable Business Role is AS for ES20-12219
                if (terrRecTypeMap.get(otherKPIAchvRec.Territory__c) != activationTerrRecordTypeId && ((otherKPIAchvRec.KPI_Type__c == 'Activation Survey KPI' && otherKPIAchvRec.Activation_Type__r.Applicable_Business_Role__c != 'Activation Specialist') ||
                        otherKPIAchvRec.KPI_Type__c == 'Survey' && otherKPIAchvRec.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c && otherKPIAchvRec.Survey_KPI__r.Applicable_Business_Role__c != 'Activation Specialist')) 
                {
                	populateTotalTarget(terrIdToTotalTargetMap, otherKPIAchvRec); //otherKPIAchvRec.Territory__c
                } 
                else if (terrRecTypeMap.get(otherKPIAchvRec.Territory__c) == activationTerrRecordTypeId && ((otherKPIAchvRec.KPI_Type__c == 'Activation Survey KPI' && (otherKPIAchvRec.Activation_Type__r.Applicable_Business_Role__c != Null && otherKPIAchvRec.Activation_Type__r.Applicable_Business_Role__c == 'Activation Specialist')) ||
                        otherKPIAchvRec.KPI_Type__c == 'Survey' && otherKPIAchvRec.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c && (otherKPIAchvRec.Survey_KPI__r.Applicable_Business_Role__c != Null && otherKPIAchvRec.Survey_KPI__r.Applicable_Business_Role__c == 'Activation Specialist'))) 
                {
                    populateTotalTarget(terrIdToTotalTargetMap, otherKPIAchvRec); //otherKPIAchvRec.Territory__c
                }
                
                /*else if(otherKPIAchvRec.KPI_Type__c == 'Survey' && otherKPIAchvRec.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c){
                populateTotalTarget(terrIdToTotalTargetMap, otherKPIAchvRec.Territory__c, otherKPIAchvRec);
                }*/
                
                else if (otherKPIAchvRec.KPI_Type__c == 'Total Activation Survey') //for Total Activation Survey Type of records
                { 
                    totalKpiAchvIdToRecordMap.put(otherKPIAchvRec.Territory__c, otherKPIAchvRec);
                }
            } //end of for - otherKPIAchvRec

            System.debug('totalKpiAchvIdToRecordMap = ' + totalKpiAchvIdToRecordMap);
            System.debug('terrIdToTotalTargetMap = ' + terrIdToTotalTargetMap);

            for (Id terrId: terrIdToTotalTargetMap.keySet()) {
                if (totalKpiAchvIdToRecordMap.containsKey(terrId)) {
                    KPI_Achivement__c totalKPIAchvRec = totalKpiAchvIdToRecordMap.get(terrId);
                    if (totalKPIAchvRec != null) {
                        totalKPIAchvRec.Target_Number__c = terrIdToTotalTargetMap.get(terrId);
                        totalKpiAchvRecs.add(totalKPIAchvRec);
                    }
                }
            }

            System.debug('totalKpiAchvRecs = ' + totalKpiAchvRecs);
            if (totalKpiAchvRecs.size() > 0) {
                Database.update(totalKpiAchvRecs);
            }
        }
    }

    /* Populate Target Number on the ACtivation Survey KPI on an incremental basis */
    private static void populateTotalTarget(Map < Id, Decimal > terrIdToTotalTargetMap, KPI_Achivement__c kpiAchvRec) {

        Id terrId = kpiAchvRec.Territory__c;
        Decimal targetToAdd = kpiAchvRec.KPI_Type__c == 'Survey' ? kpiAchvRec.Target_Derived__c : kpiAchvRec.Target_Number__c;

        if (terrIdToTotalTargetMap.containsKey(terrId)) {
            Decimal tempTargetval = terrIdToTotalTargetMap.get(terrId);
            terrIdToTotalTargetMap.put(terrId, tempTargetval + EDGE_UtilityClass.checkForNull(targetToAdd));
        } else {
            terrIdToTotalTargetMap.put(terrId, EDGE_UtilityClass.checkForNull(targetToAdd));
        }
    }

    /*
     * @Method  : checkAndGenerateSharing
     * @Purpose : To create sharing record on Insert
     */
    public static void checkAndGenerateSharing(List < KPI_Achivement__c > newItems) {
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');
    }

    /*
     * @Method  : validateAndReGenerateSharing
     * @Purpose : Modify, Validate sharing record on update
     */
    public static void validateAndReGenerateSharing(List < KPI_Achivement__c > newItems, Map < Id, SObject > oldItems) {
        Map < Id, KPI_Achivement__c > mapOldItems;
        List < KPI_Achivement__c > lstNewChangeGeography = new List < KPI_Achivement__c > ();
        List < KPI_Achivement__c > lstOldChangeGeography = new List < KPI_Achivement__c > ();

        EDGE_SharingUtil.validateEditPermission(newItems);

        if (oldItems != null) {
            mapOldItems = (Map < Id, KPI_Achivement__c > ) oldItems;
        }

        for (KPI_Achivement__c objBusinessRole: newItems) {
            if (mapOldItems.containsKey(objBusinessRole.Id) && objBusinessRole.Country__c != mapOldItems.get(objBusinessRole.Id).Country__c) {
                lstNewChangeGeography.add(objBusinessRole);
                lstOldChangeGeography.add(mapOldItems.get(objBusinessRole.Id));
            }
        }

        if (lstNewChangeGeography != null && lstNewChangeGeography.size() > 0) {
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }
    }

    /*//Check for Null
public static Decimal checkForNull(Decimal val){
return val != null ? val : 0;
}*/


    /*
     * @Method  : populateKpiAchievementUniqueId
     * @Purpose : This method is used to populate Unique Id field in KPI Achievement 
     */
    public static void populateKpiAchievementUniqueId(List < SObject > newItems) {

        String ProductKPIRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product KPI').getRecordTypeId();
        String TerrHierRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory Hierarchy KPI').getRecordTypeId();
        String UserKpiRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();

        list < KPI_Achivement__c > newRecordList = (list < KPI_Achivement__c > ) newItems;
        for (KPI_Achivement__c kpi: newRecordList) {
            string unique = null;
            if (kpi.Territory__c != null || (kpi.Region__c != null && kpi.RecordTypeId == TerrHierRecordTypeId)) {

                if (kpi.KPI_Type__c == 'Volume Category Performance') {
                    unique = kpi.RecordTypeId == TerrHierRecordTypeId ? kpi.Region__c + '_' + 'Volume' : kpi.Territory__c + '_' + 'Volume';
                    if (kpi.Volume_Category__c != null) {
                        unique += '_' + kpi.Volume_Category__c;
                    }
                    kpi.Unique_Key__c = unique;
                } else if (kpi.KPI_Type__c == 'SoS') {
                    unique = kpi.RecordTypeId == TerrHierRecordTypeId ? kpi.Region__c + '_' + kpi.KPI_Type__c : kpi.Territory__c + '_' + kpi.KPI_Type__c;
                    if (kpi.Category__c != null) {
                        unique += '_' + kpi.Category__c;
                    }
                    kpi.Unique_Key__c = unique;
                } else if (kpi.KPI_Type__c == 'Survey') {
                    unique = kpi.RecordTypeId == TerrHierRecordTypeId ? kpi.Region__c + '_' + kpi.KPI_Type__c : kpi.Territory__c + '_' + kpi.KPI_Type__c;
                    if (kpi.Survey_KPI__c != null) {
                        unique += '_' + kpi.Survey_KPI__c;
                    }
                    kpi.Unique_Key__c = unique;
                } else if (kpi.KPI_Type__c == 'Activation Survey KPI') {
                    unique = kpi.RecordTypeId == TerrHierRecordTypeId ? kpi.Region__c + '_' + 'Activation' : kpi.Territory__c + '_' + 'Activation';
                    if (kpi.Activation_Type__c != null) {
                        unique += '_' + kpi.Activation_Type__c;
                    }
                    kpi.Unique_Key__c = unique;
                } else if (kpi.KPI_Type__c == 'Asset') {
                    unique = kpi.RecordTypeId == TerrHierRecordTypeId ? kpi.Region__c + '_' + kpi.KPI_Type__c : kpi.Territory__c + '_' + kpi.KPI_Type__c;
                    if (kpi.Master_Asset__c != null) {
                        unique += '_' + kpi.Master_Asset__c;
                    }
                    kpi.Unique_Key__c = unique;
                } else if ((kpi.KPI_Type__c == 'NPD' || kpi.KPI_Type__c == 'Distribution') && kpi.RecordTypeId == ProductKPIRecordTypeId) {

                    unique = kpi.Territory__c + '_' + kpi.KPI_Type__c;
                    if (kpi.Product__c != null) {
                        unique += '_' + kpi.Product__c;
                    }
                    kpi.Unique_Key__c = unique;
                } else {
                    unique = kpi.RecordTypeId == TerrHierRecordTypeId ? kpi.Region__c : kpi.Territory__c;
                    if (kpi.KPI_Type__c != null) {
                        unique += '_' + kpi.KPI_Type__c;
                    }
                    kpi.Unique_Key__c = unique;

                }
            } else if (kpi.RecordTypeId == UserKpiRecordTypeId && kpi.User__c != null) {
                unique = kpi.User__c;
                if (kpi.KPI_Type__c != null) {
                    unique += '_' + kpi.KPI_Type__c;
                }
                kpi.Unique_Key__c = unique;
            }
            //System.debug('kpi.Unique_Key__c : '+ kpi.Unique_Key__c);
        }

    }

    /** @Method  : updateKpiAchievementCountry
     * @Purpose : This method is used to populate Country field in KPI Achievement 
     *            This methods used to update User Country by created by user country (ES20-11242) 
     */
    public static void updateKpiAchievementCountry(List < SObject > newItems, Map < Id, SObject > oldItems) {
        Id geographyId;
        String userKpiRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        List < KPI_Achivement__c > newKpiAchvList = new List < KPI_Achivement__c > ();
        Map < Id, KPI_Achivement__c > oldKpiMap = (Map < Id, KPI_Achivement__c > ) oldItems;
        Map < id, KPI_Achivement__c > newKpiMap = new Map < Id, KPI_Achivement__c > ();
        Set < Id > userIdSet = new Set < Id > ();
        Map < Id, String > userToCountryMap = new Map < Id, String > ();
        Map < String, Id > geoIdMap = new Map < String, Id > ();
        for (SObject obj: newItems) {
            KPI_Achivement__c kpiAchvRec = (KPI_Achivement__c) obj;
            newKpiMap.put(kpiAchvRec.id, kpiAchvRec);
            if (kpiAchvRec.RecordTypeId == userKpiRecordTypeId && kpiAchvRec.User__c != null) {
                userIdSet.add(kpiAchvRec.User__c);
            }
            if (kpiAchvRec.RecordTypeId == userKpiRecordTypeId && (kpiAchvRec.User__c != null || (oldKpiMap != null && oldKpiMap.get(kpiAchvRec.Id).User__c != newKpiMap.get(kpiAchvRec.Id).User__c))) {
                newKpiAchvList.add(kpiAchvRec);
            }
        }

        if (userIdSet != null && userIdSet.size() > 0) {
            userToCountryMap = EDGE_DataUtility.fetchUserCountry(userIdSet);
            if (userToCountryMap != null && userToCountryMap.Size() > 0) {
                for (Geography__c geoRecord: [SELECT id, Code__c FROM Geography__c WHERE Code__c =: userToCountryMap.values()]) {
                    geoIdMap.put(geoRecord.Code__c, geoRecord.Id);
                }
            }
        }

        if (newKpiAchvList != null && newKpiAchvList.Size() > 0) {
            for (KPI_Achivement__c kpiAchv: newKpiAchvList) {
                if (oldItems == null) {

                    if (geoIdMap != null && geoIdMap.Size() > 0 && kpiAchv.User__c != null && userToCountryMap != null && userToCountryMap.containsKey(kpiAchv.User__c) && geoIdMap.ContainsKey(userToCountryMap.get(kpiAchv.User__c))) { //containsKey check is required before getting the value from a map
                        geographyId = geoIdMap.get(userToCountryMap.get(kpiAchv.User__c));
                        kpiAchv.Country__c = geographyId;
                    }
                }

                if (oldItems != null) {

                    if (oldKpiMap.Containskey(kpiAchv.Id) && kpiAchv.User__c != null && oldKpiMap.get(kpiAchv.Id).User__c != kpiAchv.User__c) {
                        if (geoIdMap != null && geoIdMap.Size() > 0 && userToCountryMap.containsKey(kpiAchv.User__c) && geoIdMap.ContainsKey(userToCountryMap.get(kpiAchv.User__c))) {
                            geographyId = geoIdMap.get(userToCountryMap.get(kpiAchv.User__c));
                            kpiAchv.Country__c = geographyId;

                        } else {
                            kpiAchv.Country__c = null;
                        }
                    } else if (kpiAchv.User__c != null && oldKpiMap.containsKey(kpiAchv.Id) && (kpiAchv.Country__c == null || oldKpiMap.get(kpiAchv.Id).Country__c != kpiAchv.Country__c)) {
                        if (geoIdMap != null && geoIdMap.Size() > 0 && kpiAchv.User__c != null && userToCountryMap.containsKey(kpiAchv.User__c) && geoIdMap.ContainsKey(userToCountryMap.get(kpiAchv.User__c))) {
                            geographyId = geoIdMap.get(userToCountryMap.get(kpiAchv.User__c));
                            kpiAchv.Country__c = geographyId;
                        }
                    } else if (oldKpiMap.Containskey(kpiAchv.Id) && kpiAchv.User__c == null && oldKpiMap.get(kpiAchv.Id).User__c != kpiAchv.User__c) {
                        kpiAchv.Country__c = null;
                    }

                }
            }
        }
    }

}