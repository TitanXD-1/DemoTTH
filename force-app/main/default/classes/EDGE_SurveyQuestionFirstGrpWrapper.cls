/**********************************************************************
Name: EDGE_SurveyQuestionFirstGrpWrapper
=======================================================================
Purpose: 
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Sagar Barman			21/10/2019		  Intial Development
***********************************************************************/
global class EDGE_SurveyQuestionFirstGrpWrapper implements Comparable {
    
    public String groupName {get;set;}
    public String groupSequence {get;set;}

    // Constructor
    public EDGE_SurveyQuestionFirstGrpWrapper(String groupName, String groupSequence) {
        this.groupName = groupName;
        this.groupSequence = groupSequence;
    }
    
    // Compare SurveyQuestion First Grpoups based on the Group sequence order.
    global Integer compareTo(Object compareTo) {
        // Cast argument to SurveyQuestionFirstGrpWrapper
        EDGE_SurveyQuestionFirstGrpWrapper compareToSQ = (EDGE_SurveyQuestionFirstGrpWrapper)compareTo;
    	
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        
        if (this.groupSequence > compareToSQ.groupSequence) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (this.groupSequence < compareToSQ.groupSequence) {
            // Set return value to a negative value.
            returnValue = -1;
        } 

        return returnValue;       
    }
}