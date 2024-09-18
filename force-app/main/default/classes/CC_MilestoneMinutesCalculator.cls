/************************************************************************
Name: CC_MilestoneMinutesCalculator
=========================================================================
Purpose: This class is used to handle the minutes for milestone. 
=========================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Deepika Gulati         16-04-2021        Initial Development

*************************************************************************/
global class CC_MilestoneMinutesCalculator implements Support.MilestoneTriggerTimeCalculator {   
    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId){
        Case c = [SELECT CC_Passed_for_Investigation__c,CC_Product_Type__c, CC_Prestige_Product__c FROM Case WHERE Id=:caseId];
    BusinessHours bh = [select id from businesshours where Name='Customer Concerns Business Hours'];   
    
   //Integer daysLapsed = (c.CC_Passed_for_Investigation__c).daysBetween(Date.valueOf(system.today()));
    Integer milestoneMinutes = 1;
    Long sec = BusinessHours.diff(bh.Id, c.CC_Passed_for_Investigation__c, Date.valueOf(system.today()))/1000;
    Decimal mins = Integer.valueOf(sec/ 60);
    Integer hrs = Integer.valueOf(sec/ 3600);
    Integer daysLapsed= Integer.valueOf(hrs/24);
    System.debug ('Days Elapsed'+daysLapsed);
    
        //MilestoneType mt = [SELECT Name FROM MilestoneType WHERE Id=:milestoneTypeId];
        
        if (c.CC_Product_Type__c.equalsIgnoreCase('Prestige') && c.CC_Prestige_Product__c.equalsIgnoreCase ('Luxury'))
        {
            if(daysLapsed > 0)
            {
                if(daysLapsed <= 10)
                	milestoneMinutes = (10-daysLapsed)*60*24;
            }
            else
                milestoneMinutes = 14400;
        }
        else if (c.CC_Product_Type__c.equalsIgnoreCase('Prestige') && c.CC_Prestige_Product__c.equalsIgnoreCase ('Prestige 1')){
            if(daysLapsed > 0)
            {
                if(daysLapsed <= 10)
                	milestoneMinutes = (10-daysLapsed)*60*24;  
            }
            else
                milestoneMinutes = 14400;
        }
        else if (c.CC_Product_Type__c.equalsIgnoreCase('Prestige') && c.CC_Prestige_Product__c.equalsIgnoreCase ('Prestige 2')){
            if(daysLapsed > 0)
            {
                if(daysLapsed <= 10)
                	milestoneMinutes = (10-daysLapsed)*60*24;
            }
            else
                milestoneMinutes = 14400;
        }
        else if (c.CC_Product_Type__c.equalsIgnoreCase('Standard') ){
            if(daysLapsed > 0)
            {
                if(daysLapsed <= 10)
                	milestoneMinutes = (10-daysLapsed)*60*24;
            }
            else
            	milestoneMinutes = 14400;
        }
        System.debug('milestoneMinutes'+ milestoneMinutes);
        return milestoneMinutes;
    }
}