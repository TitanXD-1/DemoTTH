/**********************************************************************
Name: EDGE_SurveyQuestionGrpWrapper
=======================================================================
Purpose: 
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Sagar Barman			18/10/2019		  Intial Development
***********************************************************************/
global class EDGE_SurveyQuestionGrpWrapper implements Comparable {
    public Survey_Question__c surveyQuestion{get;set;}
    public String Id{get;set;}
    public String compareByGroup{get;set;}

        
    // Constructor
    public EDGE_SurveyQuestionGrpWrapper(Survey_Question__c sq) {
        surveyQuestion = sq;
        this.Id = sq.Id; 
    }
    
    // Compare SurveyQuestion Second Grpoups based on the Group sequence number.
    global Integer compareTo(Object compareTo) {
        // Cast argument to SurveyQuestionGrpWrapper
        EDGE_SurveyQuestionGrpWrapper compareToSQ = (EDGE_SurveyQuestionGrpWrapper)compareTo;
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        
        if (surveyQuestion.Grouping2_Sequence_Number__c > compareToSQ.surveyQuestion.Grouping2_Sequence_Number__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (surveyQuestion.Grouping2_Sequence_Number__c < compareToSQ.surveyQuestion.Grouping2_Sequence_Number__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }

        return returnValue;       
    }
}