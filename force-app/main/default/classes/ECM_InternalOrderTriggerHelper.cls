/**********************************************************************
Name: ECM_InternalOrderTriggerHelper
=======================================================================
Purpose: Internal Order Trigger Helper Class.
=======================================================================
History                                                            
-------                                                            
VERSION    	AUTHOR                   DATE              DETAIL
1.0		                                             Initial Developmemt
1.1        	Sayan Mullick	   		01.07.2021 		 Added record type check in functions updateIOFasicalYear and
													 updateIOFasicalYearOnBefore for ECM.(ECM-4534)
1.2			Sayan Mullick			20.12.2021		 Internal Order Sharing by Sales organisation(CST-497)
***********************************************************************/
public class ECM_InternalOrderTriggerHelper {
    public static Id recordTypeId= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CM Internal Order').getRecordTypeId();
    public static Id recordTypeIdCST= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CST Internal Order').getRecordTypeId();
 
    /*******************************************************************
    Method  : updateIOFasicalYear
    Purpose : check if Start date and End date is not null and record type
			  equals 'CM Internal Order' then call function fiscalYearCalculate()
    ********************************************************************/
     public static void updateIOFasicalYear(List < ECM_Internal_Order__c  > newItems) {        
        if (newItems != null) {
            for (ECM_Internal_Order__c newIORec: newItems) {
                if (newIORec.ECM_End_Date__c != null && newIORec.ECM_Start_Date__c!=Null && newIORec.RecordTypeId.equals(recordTypeId)) { //(ECM-4534)
                   fiscalYearCalculate(newIORec);
                }
            }
        }
    }
  
    /*******************************************************************
    Method  : updateIOFasicalYearOnBefore
    Purpose : check for old and new values in Start date and End date and record type
			  equals 'CM Internal Order' then call function fiscalYearCalculate() on before update.
    ********************************************************************/
    public static void updateIOFasicalYearOnBefore(List < ECM_Internal_Order__c  > newItems, Map < Id, sObject > oldItems) {
        try{            
            Map < Id, ECM_Internal_Order__c > mapOldItems = new Map < Id, ECM_Internal_Order__c > ();
        if (oldItems != null) {
            mapOldItems = (Map < Id, ECM_Internal_Order__c > ) oldItems;
        }
        if (newItems != null) {
            for (ECM_Internal_Order__c newIORec: newItems) {
                
                   if( (mapOldItems.get(newIORec.Id).ECM_Start_Date__c!=newIORec.ECM_Start_Date__c || mapOldItems.get(newIORec.Id).ECM_End_Date__c!=newIORec.ECM_End_Date__c) && newIORec.RecordTypeId.equals(recordTypeId))//(ECM-4534)
                    {
                        fiscalYearCalculate(newIORec);
                    }
                
            }
        }
        }catch(Exception ex){
            System.debug('Exception Caught in updateIOFasicalYearOnBefore method of ECM_InternalOrderTriggerHelper at Line: '+ex.getLineNumber()+' Error: '+ex.getMessage());
        }
		
    }
    
	 /*
    Name: Fiscal Yeal Calculator
    Developer: Anivesh
    Description: Method to calculate Fiscal Year in Internal order.
    */ 
    public static void fiscalYearCalculate(ECM_Internal_Order__c  newPaySum){        
        try{
            if(newPaySum.ECM_Start_Date__c!=null && newPaySum.ECM_End_Date__c!=null){    
                Date startDate = newPaySum.ECM_Start_Date__c;
                Date endDate = newPaySum.ECM_End_Date__c;
                Integer startDateMonth = startDate.month();
                Integer endDateMonth = endDate.month();
                Integer startDateYear = startDate.year();
                Integer endDateYear = endDate.year();
                String fiscalYear = '';
                for(integer i=startDateYear; i<= endDateYear; i++){
                    integer dateYear = i;
                    if(i==startDateYear){
                        if(startDateMonth<7){
                            fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        }
                    }
                    if(i==endDateYear){
                        if(startDateYear == endDateYear){
                            if(startDateMonth<7 && endDateMonth >= 7){
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth >= 7){
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                        else if(startDateYear+1 == endDateYear){
                            if(startDateMonth < 7 && endDateMonth < 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth < 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth < 7 && endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                        else{
                            if(endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            else{
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                    }
                    if(i != startDateYear && i != endDateYear){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                
                newPaySum.ECM_Fiscal_Year__c = fiscalYear.removeEndIgnoreCase('/');
            }
        }catch(Exception e){
            System.debug('Exception Caught in fiscalYearCalculate method of ECM_InternalOrderTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<ECM_Internal_Order__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'ECM_Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<ECM_Internal_Order__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Internal_Order__c > mapOldItems;
        List<ECM_Internal_Order__c> lstNewChangeGeography = new List<ECM_Internal_Order__c>();
        List<ECM_Internal_Order__c> lstOldChangeGeography = new List<ECM_Internal_Order__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Internal_Order__c>)oldItems;
        }
        
        for(ECM_Internal_Order__c  objInternalOrderOption : newItems){
            if(mapOldItems.containsKey(objInternalOrderOption.Id) && objInternalOrderOption.ECM_Geography__c != mapOldItems.get(objInternalOrderOption.Id).ECM_Geography__c){
                lstNewChangeGeography.add(objInternalOrderOption);
                lstOldChangeGeography.add(mapOldItems.get(objInternalOrderOption.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'ECM_Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'ECM_Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'ECM_Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'ECM_Geography__c', 'Down', 'Edit');
        }       
    }
    /*
	* @description : checkAndGenerateSharingfromSalesOrg
	* @return : void
	* @param : List<Approver_Matrix__c>
	*/
    public static void checkAndGenerateSharingfromSalesOrg(List<ECM_Internal_Order__c> newItems){
        List<ECM_Internal_Order__c> lstNewChangeSalesOrg = new List<ECM_Internal_Order__c>();
        for(ECM_Internal_Order__c  objInternalOrderOption : newItems){
            if(objInternalOrderOption.RecordTypeId.equals(recordTypeIdCST))
                lstNewChangeSalesOrg.add(objInternalOrderOption);
        }
    	if(lstNewChangeSalesOrg != null && lstNewChangeSalesOrg.size()>0){
        	CST_SharingUtil.validateCreatePermission(lstNewChangeSalesOrg, 'Sales_Organisation__c');
        	CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'Sales_Organisation__c', 'Read');
        	CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'Sales_Organisation__c', 'Edit');
        }
    }
    
    /*
	* @description : validateAndReGenerateSharingfromSalesOrg
	* @return : void
	* @param : List<Approver_Matrix__c>,Map<Id, SObject>
	*/
    public static void validateAndReGenerateSharingfromSalesOrg(List<ECM_Internal_Order__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Internal_Order__c > mapOldItems;
        List<ECM_Internal_Order__c> lstNewChangeSalesOrg = new List<ECM_Internal_Order__c>();
        List<ECM_Internal_Order__c> lstOldChangeSalesOrg = new List<ECM_Internal_Order__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Internal_Order__c>)oldItems;
        }
        
        for(ECM_Internal_Order__c  objInternalOrderOption : newItems){
            if(mapOldItems.containsKey(objInternalOrderOption.Id) && objInternalOrderOption.Sales_Organisation__c != mapOldItems.get(objInternalOrderOption.Id).Sales_Organisation__c && objInternalOrderOption.RecordTypeId.equals(recordTypeIdCST)){
                lstNewChangeSalesOrg.add(objInternalOrderOption);
                lstOldChangeSalesOrg.add(mapOldItems.get(objInternalOrderOption.Id));
            }
        }
        
        if(lstNewChangeSalesOrg != null && lstNewChangeSalesOrg.size()>0){
            CST_SharingUtil.validateCreatePermission(lstNewChangeSalesOrg, 'Sales_Organisation__c');
            CST_SharingUtil.updateSharingRecords(lstNewChangeSalesOrg, lstOldChangeSalesOrg, 'Sales_Organisation__c');
            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'Sales_Organisation__c', 'Read');
            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'Sales_Organisation__c', 'Edit');
        }       
    }
}