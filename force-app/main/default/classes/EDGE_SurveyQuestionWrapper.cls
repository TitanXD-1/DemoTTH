/**********************************************************************
Name: EDGE_SurveyQuestionWrapper
=======================================================================
Purpose: 
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Sagar Barman			18/10/2019		  Intial Development
***********************************************************************/
global class EDGE_SurveyQuestionWrapper implements Comparable {
    public Survey_Question__c surveyQuestion{get;set;}
    public String Id{get;set;} 
    
    // Constructor
    public EDGE_SurveyQuestionWrapper(Survey_Question__c sq) {
        surveyQuestion = sq;
        Id = sq.Id;
    }
    
    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        EDGE_SurveyQuestionWrapper compareToSQ = (EDGE_SurveyQuestionWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (surveyQuestion.Order_Number__c > compareToSQ.surveyQuestion.Order_Number__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (surveyQuestion.Order_Number__c < compareToSQ.surveyQuestion.Order_Number__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}