/*
* @Name: EDGE_LineCleaningHolidayHelper

* @History                                                            

* @Version     Developer           Date          User-Story/Purpose

*  1.1       Supriya Galinde     03/12/2021      ES20-10437(Method:calculateDueDate,checkifItisWeekend,calculateLineCleaningEndDateFromHoliday)
*  1.2		 Aparajita 			 06/12/2021      ES20-10780(Method:checkAndGenerateSharing,validateAndReGenerateSharing)
*  1.3       Rajarshi Lahiri 	 08/02/2022      ES20-11643

**/
public class EDGE_LineCleaningHolidayHelper {
    
    public static Date calculateDueDate(Date dateStart, Integer intOffset){
        //One subtracted to account for day 1 being the start date
        //intOffset--;
        
        //Initialize end date with start date and use it for calculations
        Date dateEnd = dateStart;
        if(intOffset <0){
            intOffset = math.abs(intOffset);
            //for(Integer i = intOffset; i > 0; i--){
            for(Integer i=0; i < intOffset; i++){
                dateEnd = dateEnd.addDays(-1);
                //If the calculated date is a weekend, skip it by increasing intOffset
                if(EDGE_LineCleaningCycleHelper.checkifItisWeekend(dateEnd))
                    intOffset++;
        	}
        }
        else{
        //For all days between now and the offset
        for(Integer i=0; i < intOffset; i++ ){
            
            dateEnd = dateEnd.addDays(1);
            System.debug('dateEnd'+dateEnd);
            //If the calculated date is a weekend, skip it by increasing intOffset
            if(EDGE_LineCleaningCycleHelper.checkifItisWeekend(dateEnd))
                intOffset++;
            
        }
        }
        
        //return the calculated day
        return dateEnd;
        
    }
      
    /**
* @description: calculateLineCleaningEndDateFromHoliday - Calculate end date from Line Cleaning Holiday
* @return: void
* @param: list<Sobject> sObjectRecords
*/  
    public static void calculateLineCleaningEndDateFromHoliday(list<Sobject> sObjectRecords,boolean isDelete, boolean isUpdate, map<id,Sobject> oldItems)
    {
        List<Line_Cleaning_Holiday__c> listLineCleaningHoliday=(List<Line_Cleaning_Holiday__c>)sObjectRecords;
        Map<id,Line_Cleaning_Holiday__c> oldHolidayMap=(Map<id,Line_Cleaning_Holiday__c>)oldItems;
        Set<String> lineCleaningHolidayCountry	=	new Set<String>();
        Map<Id,Line_Cleaning_Holiday__c> MapOfHolidaywithCycle = new Map<Id,Line_Cleaning_Holiday__c>();
        Map<Id,Line_Cleaning_Cycle__c> toBeUpdateLc= new Map<Id,Line_Cleaning_Cycle__c>();
        for(Line_Cleaning_Holiday__c lineCleaningHolidayCycle: listLineCleaningHoliday){
            lineCleaningHolidayCountry.add(lineCleaningHolidayCycle.Country__c);
        }
        List<Line_Cleaning_Cycle__c> lineCleaningCycleList = [SELECT Start_Date__c, End_Date__c,Active__c	, Country__c FROM Line_Cleaning_Cycle__c 
                                            WHERE   Country__c != NULL 
                                            AND     Country__c IN :lineCleaningHolidayCountry AND Active__c = True];
        System.debug('listLineCleaningHoliday'+listLineCleaningHoliday);
        if(lineCleaningCycleList !=null && lineCleaningCycleList.size()>0){
            
            for(Line_Cleaning_Holiday__c lineCleaningHol: listLineCleaningHoliday){
                if(lineCleaningHol.Line_Cleaning_Cycle__c == null || isUpdate && lineCleaningHol.Exclusion_Date__c != oldHolidayMap.get(lineCleaningHol.id).Exclusion_Date__c || isDelete)
                {
                    for(Line_Cleaning_Cycle__c lineCleaningCycleRec:lineCleaningCycleList){
                        if(lineCleaningCycleRec.Start_Date__c <= lineCleaningHol.Exclusion_Date__c && lineCleaningCycleRec.End_Date__c >= lineCleaningHol.Exclusion_Date__c && lineCleaningCycleRec.Country__c == lineCleaningHol.Country__c && lineCleaningHol.Active__c == true){
                            //System.debug('Setting flag as true');
                            System.debug('lineCleaningHol.Exclusion_Date__c'+lineCleaningHol.Exclusion_Date__c);
                            lineCleaningCycleRec.Change_in_Holidays__c = true;
                            toBeUpdateLc.put(lineCleaningCycleRec.Id,lineCleaningCycleRec);
                            MapOfHolidaywithCycle.put(lineCleaningCycleRec.Id,lineCleaningHol);
                            if(isDelete){
                            	lineCleaningCycleRec.End_Date__c = Edge_LineCleaningHolidayHelper.calculateDueDate(lineCleaningCycleRec.End_Date__c,-1);
                            }
                            else{
                                lineCleaningCycleRec.End_Date__c = Edge_LineCleaningHolidayHelper.calculateDueDate(lineCleaningCycleRec.End_Date__c,1);
                            	lineCleaningHol.Line_Cleaning_Cycle__c = lineCleaningCycleRec.Id;
                            }
                            
                        }
                       
                    }
                }
                
            }  
            
        }
        
        if(toBeUpdateLc !=null && toBeUpdateLc.size()>0){
            Database.SaveResult[] srList = Database.update(toBeUpdateLc.values(), false);
            Integer index = 0;
            for(Id linecycleId : toBeUpdateLc.keySet()){
                Database.SaveResult sr = srList[index];
                if(sr.isSuccess()){
                    system.debug('Updated Record'+sr.id); 
                }else{
                    MapOfHolidaywithCycle.get(linecycleId).addError(System.label.Edge_Error_msg_If_cycle_end_date_overlaps_with_Active_Line_Cleaning_Cycle);
                }
                index++;
            }
        }
    }
    
    /**
* @description: checkAndGenerateSharing - To create sharing record on insert
* @return: void
* @param: List<Line_Cleaning_Holiday__c>
*/
    public static void checkAndGenerateSharing(List<Line_Cleaning_Holiday__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    
    /**
* @description: validateAndReGenerateSharing - Modify, Validate sharing record on update
* @return: void
* @param: List<Line_Cleaning_Holiday__c>, Map<Id, SObject>
*/
    public static void validateAndReGenerateSharing(List<Line_Cleaning_Holiday__c> newItems,Map<Id, SObject> oldItems){        
        Map<Id, Line_Cleaning_Holiday__c> mapOldItems;
        List<Line_Cleaning_Holiday__c> lstNewChangeGeography = new List<Line_Cleaning_Holiday__c>();
        List<Line_Cleaning_Holiday__c> lstOldChangeGeography = new List<Line_Cleaning_Holiday__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Line_Cleaning_Holiday__c>)oldItems;
        }
        
        for(Line_Cleaning_Holiday__c lcHoliday : newItems){
            if(mapOldItems.containsKey(lcHoliday.Id) && lcHoliday.Country__c != mapOldItems.get(lcHoliday.Id).Country__c){
                lstNewChangeGeography.add(lcHoliday);
                lstOldChangeGeography.add(mapOldItems.get(lcHoliday.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    } 
}