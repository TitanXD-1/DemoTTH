/************************************************************************
Name: CC_BusinessDays
=========================================================================
Purpose: This class is used to calculate the number of working days
=========================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Jayashree               20-04-2021        Initial Development

*************************************************************************/


public class CC_BusinessDays
{
    public static BusinessHours defaultHours
    {
        get
        {
            if (defaultHours == null)
                defaultHours = [SELECT Id FROM BusinessHours WHERE Name = 'Customer Concerns Business Hours'];
            return defaultHours;
        }
        private set;
    }

    public static Datetime add(Datetime pointer, Integer days)
    {
        pointer = BusinessHours.nextStartDate(defaultHours.Id, pointer);
        // make sure you're starting at a Datetime within BusinessHours
        for (Integer elapsed = 0; elapsed < days; elapsed++)
        {
            pointer = pointer.addDays(1);
            if (!BusinessHours.isWithin(defaultHours.Id, pointer))
                pointer = BusinessHours.nextStartDate(defaultHours.Id, pointer);
        }
        return pointer;
    }
}