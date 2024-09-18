/**
* @Name: EDGE_LineCleaningCycleHelper

* @History                                                            

* @Version     Developer             Date          User-Story/Purpose

*  1.1         Joshraj Sen         03/12/2021      ES20-10430(Method:calculateLineCleaningCycleEndDate,validateDuplicateStartdate,updateLineCleaningCycleHolidays)
*  1.2		   Aparajita 		   06/12/2021      ES20-10779(Method:checkAndGenerateSharing,validateAndReGenerateSharing)

*/

public with sharing class EDGE_LineCleaningCycleHelper {
    
    /**
* @description: validateDuplicateStartdate  To check if a Line Cleaning Cycle's start date or end date don't overlap with any other Line Cleaning Cycle's start date and end date
* @return: void
* @param: List<SObject>,Map<Id, SObject>,boolean,boolean
*/
    public static void validateDuplicateStartdate(List<SObject> newItems, Map<Id, SObject> oldItems, boolean isUpdate){
        List<Line_Cleaning_Cycle__c> newMap = (List<Line_Cleaning_Cycle__c>)newItems; 
        Map<Id,Line_Cleaning_Cycle__c> oldMap = (Map<id,Line_Cleaning_Cycle__c>)oldItems;
        
        List<String> LCCountryIds = new List<String>();
        
        for(Line_Cleaning_Cycle__c lineCleaningCycle: newMap){
            LCCountryIds.add(lineCleaningCycle.Country__c);
        } 
        
        // Select all applicable line cleaning cycle records for a location
        for(Line_Cleaning_Cycle__c cycleFromQuery: [Select Id,Start_Date__c,End_Date__c,Country__c,Active__c 

                                                    From Line_Cleaning_Cycle__c where Active__c = true and Country__c in :LCCountryIds ORDER BY Start_Date__c])
        {
            // For record updates, check only if start date or location has changed
            for(Line_Cleaning_Cycle__c currentLineCleaning: newMap){
                if(isUpdate){//Update scenario
                    //  Check that the Start date should be outside the Start Date and End Date Range
                    if( (currentLineCleaning.Id != cycleFromQuery.Id)  && ( (currentLineCleaning.Start_Date__c >= cycleFromQuery.Start_Date__c) && (currentLineCleaning.Start_Date__c <= cycleFromQuery.End_Date__c) 
                                                                           || ((currentLineCleaning.End_Date__c >= cycleFromQuery.Start_Date__c) && (currentLineCleaning.End_Date__c <= cycleFromQuery.End_Date__c)  ) )
                       && (currentLineCleaning.Country__c == cycleFromQuery.Country__c) ) 
                    {                   
                        currentLineCleaning.addError(System.label.EDGE_LineCleaningCycle_Already_Part_Of_Active_Cycle);
                    }
                    else if(oldMap != null && oldMap.containsKey(currentLineCleaning.Id) && currentLineCleaning.Start_Date__c != oldMap.get(currentLineCleaning.Id).Start_Date__c && currentLineCleaning.Active__c == true){
                        currentLineCleaning.Change_in_Start_Date__c = true;
                    }
                }
                else{//Insert scenario

                                                                if( ( (currentLineCleaning.Start_Date__c >= cycleFromQuery.Start_Date__c) && (currentLineCleaning.Start_Date__c <= cycleFromQuery.End_Date__c) 
                                                                     ||  ( (currentLineCleaning.End_Date__c >= cycleFromQuery.Start_Date__c) && (currentLineCleaning.End_Date__c <= cycleFromQuery.End_Date__c)  ) )
                                                                   && (currentLineCleaning.Country__c == cycleFromQuery.Country__c) ) { 
                                                                       currentLineCleaning.addError(System.label.EDGE_LineCleaningCycle_Already_Part_Of_Active_Cycle);
                                                                   }
                                                            } 
                                                        }
                                                    }         
    }
    
    /**
* @description: calculateLineCleaningCycleEndDate  To update End Date from the Duration and Holiday Lists
* @return: void
* @param: List<SObject>,Map<Id, SObject>,boolean,boolean
*/
    public static void calculateLineCleaningCycleEndDate(List<SObject> newItems, Map<Id, SObject> oldItems, boolean isUpdate, boolean isInsert){
        List<Line_Cleaning_Cycle__c> newMap = (List<Line_Cleaning_Cycle__c>)newItems; 
        Map<Id,Line_Cleaning_Cycle__c> oldMap = (Map<id,Line_Cleaning_Cycle__c>)oldItems;
        Map<Id,Integer> countryWithNoOfDays=new Map<Id,Integer>();//Storing the Country as a Key and the Line Cleaning Duration as for that country as a value
        decimal cycleDuration   = 0;
        Date lowestStartDate	= newMap[0].Start_Date__c;
        Set<String> LCCountryIds	=	new Set<String>();
        for(Line_Cleaning_Cycle__c lineCleaningCycle: newMap){
            if(lineCleaningCycle.Start_Date__c < lowestStartDate){
                lowestStartDate = lineCleaningCycle.Start_Date__c;
            }
            LCCountryIds.add(lineCleaningCycle.Country__c);
        } 
        for(Market_Setting__c marketSetting:[Select Id,Line_Cleaning_Duration__c,Geography__c From Market_Setting__c where Geography__c in :LCCountryIds]){
            countryWithNoOfDays.put(marketSetting.Geography__c, Integer.valueOf(marketSetting.Line_Cleaning_Duration__c));//Store the country as a key and the duration for each country as a value
        }
        Map<String, List<Line_Cleaning_Holiday__c>> mCountryHolidayList = new Map<String, List<Line_Cleaning_Holiday__c>>();                                                             
        for(Line_Cleaning_Holiday__c hday : [Select Id,Exclusion_Date__c,Line_Cleaning_Cycle__c,Country__c,Active__c from Line_Cleaning_Holiday__c
                                             WHERE Exclusion_Date__c >= :lowestStartDate and Active__c=true
                                             AND Country__c IN :LCCountryIds

                                             ORDER BY Country__c, Exclusion_Date__c])
        {

                                                 if(mCountryHolidayList.containsKey(hday.Country__c)){
                                                     mCountryHolidayList.get(hday.Country__c).add(hday);
                                                 } else {
                                                     mCountryHolidayList.put(hday.Country__c, new List<Line_Cleaning_Holiday__c>{hday});
                                                 }
                                             }
        
        for(Line_Cleaning_Cycle__c lineCleaningCycle : newMap){
            Date dtStartDate = lineCleaningCycle.Start_Date__c;                      
            string strCountryId      = lineCleaningCycle.Country__c;
            cycleDuration = countryWithNoOfDays.get(strCountryId);                     
            
            //  Check the cycle duration should be > ZERO
            if(Integer.valueOf(cycleDuration) > 0){
                //  Only recalculate the end date if the start date has changed in case of update of line cleaning cycle 
                if( isUpdate && (lineCleaningCycle.Start_Date__c != oldMap.get(lineCleaningCycle.Id).Start_Date__c || lineCleaningCycle.Country__c != oldMap.get(lineCleaningCycle.Id).Country__c))
                {                           
                    lineCleaningCycle.End_Date__c = calculateDueDate(dtStartDate, Integer.valueOf(cycleDuration), mCountryHolidayList.get(lineCleaningCycle.Country__c));  
                }
                else if(isInsert) {
                    lineCleaningCycle.End_Date__c = calculateDueDate(dtStartDate, Integer.valueOf(cycleDuration), mCountryHolidayList.get(lineCleaningCycle.Country__c));
                }
            }
            else
                lineCleaningCycle.addError(System.label.EDGE_Market_Duration_Null_Check);                                                            
            
        }
    }
    /**
* @description: calculateDueDate  To calculate End from the Duration and Holiday Lists
* @return: Date
* @param: Date,Integer,List<Line_Cleaning_Holiday__c>
*/
    public static Date calculateDueDate(Date dateStart, Integer intOffset, List<Line_Cleaning_Holiday__c> lHolidays){
        
        //One subtracted to account for day 1 being the start date
        intOffset--;
        
        //Initialize end date with start date and use it for calculations
        Date dateEnd = dateStart;
        
        //For all days between now and the offset
        for(Integer i=0; i < intOffset; i++ ){
            
            dateEnd = dateEnd.addDays(1);
            
            //If the calculated date is a weekend, skip it by increasing intOffset
            if(EDGE_LineCleaningCycleHelper.checkifItisWeekend(dateEnd)){
                intOffset++;
            }
            
        }
        
        if(lHolidays!=null){
            for(Line_Cleaning_Holiday__c hday :lHolidays){
                if(hday.Exclusion_Date__c >= dateStart && hday.Exclusion_Date__c <= dateEnd){
                    dateEnd = dateEnd.addDays(1);
                    //If the calculated date is a weekend, skip it by increasing intOffset
                    while(checkifItisWeekend(dateEnd)){
                        dateEnd = dateEnd.addDays(1);
                    }
                }
            }
        }
        
        //return the calculated day
        return dateEnd;
        
    }
    /**
* @description: checkifItisWeekend - To check if a Date is Weekend or not
* @return: boolean
* @param: Date
*/
    
    public static boolean checkifItisWeekend(Date currentDate){                       
        DateTime newCurrentDate = DateTime.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
        if( newCurrentDate.format('E') == 'Sat' || newCurrentDate.format('E') == 'Sun' ){
            return true;
        } else 
            return false;        
    }
    /**
* @description: checkAndGenerateSharing - To create sharing record on Insert
* @return: void
* @param: List<Line_Cleaning_Cycle__c>
*/
    public static void checkAndGenerateSharing(List<Line_Cleaning_Cycle__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /**
* @description: validateAndReGenerateSharing - Modify, Validate sharing record on update
* @return: void
* @param: List<Quality_Case_Configuration__c>, Map<Id, SObject>
*/
    public static void validateAndReGenerateSharing(List<Line_Cleaning_Cycle__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Line_Cleaning_Cycle__c> mapOldItems;
        List<Line_Cleaning_Cycle__c> lstNewChangeGeography = new List<Line_Cleaning_Cycle__c>();
        List<Line_Cleaning_Cycle__c> lstOldChangeGeography = new List<Line_Cleaning_Cycle__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Line_Cleaning_Cycle__c>)oldItems;
        }
        
        for(Line_Cleaning_Cycle__c objBusinessRole : newItems){
            if(mapOldItems.containsKey(objBusinessRole.Id) && objBusinessRole.Country__c != mapOldItems.get(objBusinessRole.Id).Country__c){
                lstNewChangeGeography.add(objBusinessRole);
                lstOldChangeGeography.add(mapOldItems.get(objBusinessRole.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    } 
    /**
* @description: updateLineCleaningCycleHolidays - Modify the Holidays with the respective Line Cleaning Cycles
* @return: void
* @param: list<Sobject> sObjectRecords, Map<Id,Sobject>oldItems
*/
    
    public static void updateLineCleaningCycleHolidays(list<Sobject> sObjectRecords, Map<Id,Sobject>oldItems)
    {
        List<Line_Cleaning_Cycle__c> cycleList = (List<Line_Cleaning_Cycle__c>)sObjectRecords;
        Map<Id,Line_Cleaning_Cycle__c> oldCycleMap = (Map<Id,Line_Cleaning_Cycle__c>) oldItems;

        Set<Id> countryIds = new Set<Id>();
        List<Line_Cleaning_Holiday__c> holidaysToUpdate=new List<Line_Cleaning_Holiday__c>();
        Map<Id,List<Line_Cleaning_Holiday__c>> holidaysForEachCountry = new Map<Id,List<Line_Cleaning_Holiday__c>>();        
        
        for(Line_Cleaning_Cycle__c cycle : cycleList){
            countryIds.add(cycle.Country__c);//Store the Country Id
        }
        
        if(countryIds !=null && countryIds.size() > 0){

            
            for(Line_Cleaning_Holiday__c hday:[Select Id,Exclusion_Date__c,Line_Cleaning_Cycle__c,Country__c,Active__c from Line_Cleaning_Holiday__c where Country__c in :countryIds and Active__c=true])
            {
                if(holidaysForEachCountry.containsKey(hday.Country__c)){
                    holidaysForEachCountry.get(hday.Country__c).add(hday);

                }else{

                    holidaysForEachCountry.put(hday.Country__c, new List<Line_Cleaning_Holiday__c>{hday});   
                }
                
            }  
            
            //Null Check For Line Cleaning Cycles and Holidays
            for(Line_Cleaning_Cycle__c cycle : cycleList)
            {

                if(oldCycleMap != null && oldCycleMap.containsKey(cycle.Id)){//Update Scenario

                    if(holidaysForEachCountry.containsKey(cycle.Country__c) && cycle.Active__c == true && cycle.End_Date__c != oldCycleMap.get(cycle.Id).End_Date__c){
                        for(Line_Cleaning_Holiday__c holiday : holidaysForEachCountry.get(cycle.Country__c))
                        {
                            if(holiday.Line_Cleaning_Cycle__c==null)
                            {
                                
                                if(holiday.Exclusion_Date__c >= cycle.Start_Date__c && holiday.Exclusion_Date__c <= cycle.End_Date__c)
                                {

                                    holiday.Line_Cleaning_Cycle__c=cycle.Id;
                                    holidaysToUpdate.add(holiday);

                                }
                                
                            }
                          
                        }
                    }
                }
                else

                {//Insert Scenario

                    if(holidaysForEachCountry.containsKey(cycle.Country__c) && cycle.Active__c == true){
                        for(Line_Cleaning_Holiday__c holiday : holidaysForEachCountry.get(cycle.Country__c))
                        {
                            if(holiday.Exclusion_Date__c >= cycle.Start_Date__c && holiday.Exclusion_Date__c <= cycle.End_Date__c)
                            {
                                holiday.Line_Cleaning_Cycle__c = cycle.Id;
                                holidaysToUpdate.add(holiday);
                                
                            }
                            
                        }
                    }
                }
                
                
            }
            if(holidaysToUpdate !=null && holidaysToUpdate.size() >0){
                Database.update(holidaysToUpdate);
            }
            
        }
        
    }
    
}