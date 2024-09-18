/*
* Name: WrapperStartDateEndDatePair
* Purpose: This is a wrapper class for storing storing start date and end date in PS
* History

VERSION    	AUTHOR                	DATE              	DETAIL
1.0			Mayukh			      31/05/2023		
*/

public class WrapperStartDateEndDatePair{
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public WrapperStartDateEndDatePair(Date startPeriod,Date endPeriod){
        this.startDate = startPeriod;
        this.endDate = endPeriod;
    }
}